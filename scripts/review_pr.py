import os
import requests
import google.generativeai as genai
import sys
import re
import fnmatch

# --- CONFIGURATION ---
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
REPO_NAME = os.getenv("GITHUB_REPOSITORY")
PR_NUMBER = os.getenv("PR_NUMBER")

# Files to completely ignore (won't be sent to Gemini)
IGNORE_PATTERNS = [
    "**/*.g.dart",
    "**/*.r.g.dart",
    "**/*.freezed.dart",
    "**/*.mocks.dart",
    "**/*.md",
    "**/*.yaml",
    "**/package-lock.json",
    "**/yarn.lock",
    "**/Podfile.lock"
]

# Custom Instructions
FLUTTER_INSTRUCTIONS = """
### 📱 Flutter & Mobile Analysis (Apply to .dart, .kt, .swift files)
You are an expert mobile developer (Flutter, Android, iOS).

1. **Memory & Resource Management**
    - Check for unremoved listeners (ValueNotifier, ChangeNotifier, Streams).
    - Verify dispose() methods clean up controllers and subscriptions.
    - Look for potential memory leaks.

2. **Null Safety & Error Handling**
    - Verify null-aware operators (?., ??) are used correctly.
    - ⛔️ STRICTLY FORBID usage of force unwrapping (!) (the bang operator).
    - Check for proper null checks before accessing nullable properties.
    - Ensure async operations have try-catch blocks.
    - Validate BuildContext usage doesn't cross async gaps (use `mounted` check).

3. **Performance Optimization**
    - Use `const` constructors wherever possible.
    - Check for unnecessary widget rebuilds.
    - Avoid large widget trees in single build methods; suggest extracting widgets.
    - Prefer stateless/hook widgets over stateful widgets where appropriate.
    - Ensure no hooks are used inside conditions or loops.

4. **Code Style & Best Practices**
    - Follow Dart naming: lowerCamelCase for members, UpperCamelCase for classes.
    - Avoid magic numbers—use named constants.
    - Use widget subclasses instead of helper methods returning widgets.

5. **Common Flutter Pitfalls**
    - Verify keys are used correctly in Lists.
    - Check for infinite loops in widget rebuilds.
    - Ensure GlobalKey usage is justified.
"""

GENERAL_INSTRUCTIONS = """
### 🛡️ General Code Quality (Apply to all files)
1. **Comments:** Add meaningful comments for complex logic (why, not just what).
2. **Security:** Ensure no secrets, tokens, or environment values are hardcoded.
3. **Architecture:** Maintain separation of concerns (Business Logic vs UI).
4. **Testing:** Identify missing integration test scenarios for critical flows.
"""

# --- SETUP ---
if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY is missing")

if not PR_NUMBER:
    print("Error: PR_NUMBER environment variable is missing.")
    print("If running manually, please provide the Pull Request number in the workflow input.")
    sys.exit(1)

genai.configure(api_key=GEMINI_API_KEY)
model = genai.GenerativeModel("gemini-2.5-flash")

def get_pr_diff():
    """Fetches the diff of the Pull Request from GitHub."""
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3.diff"
    }
    url = f"https://api.github.com/repos/{REPO_NAME}/pulls/{PR_NUMBER}"

    response = requests.get(url, headers=headers)
    response.raise_for_status()
    return response.text

def filter_diff(diff_text):
    """Parses the diff and removes files matching IGNORE_PATTERNS."""

    # Split diff into files using the git diff header
    # Regex looks for: diff --git a/path b/path
    file_chunks = re.split(r'(?=diff --git )', diff_text)

    filtered_chunks = []

    for chunk in file_chunks:
        if not chunk.strip():
            continue

        # Extract filename from the chunk line: "diff --git a/lib/main.dart b/lib/main.dart"
        match = re.search(r'diff --git a/(.*?) b/', chunk)
        if match:
            filename = match.group(1)

            # Check if file should be ignored
            should_ignore = any(fnmatch.fnmatch(filename, pattern) for pattern in IGNORE_PATTERNS)

            if should_ignore:
                print(f"Skipping ignored file: {filename}")
                continue

            filtered_chunks.append(chunk)

    return "".join(filtered_chunks)

def post_comment(comment):
    """Posts the Gemini review as a comment on the Pull Request."""
    headers = {
        "Authorization": f"token {GITHUB_TOKEN}",
        "Accept": "application/vnd.github.v3+json"
    }
    url = f"https://api.github.com/repos/{REPO_NAME}/issues/{PR_NUMBER}/comments"

    payload = {"body": comment}
    response = requests.post(url, json=payload, headers=headers)
    response.raise_for_status()

def review_code():
    print(f"Fetching diff for PR #{PR_NUMBER} in {REPO_NAME}...")
    raw_diff = get_pr_diff()

    if not raw_diff:
        print("No changes found in diff.")
        return

    print("Filtering diff...")
    clean_diff = filter_diff(raw_diff)

    if not clean_diff.strip():
        print("No relevant changes found after filtering (only ignored files changed).")
        return

    # Truncate if still too huge (2.5 Flash has a large context, but let's be safe)
    if len(clean_diff) > 200000:
        clean_diff = clean_diff[:200000] + "\n...(truncated due to size limit)"

    print("Sending diff to Gemini 2.5 Flash for review...")

    prompt = f"""
    Act as a Senior Software Engineer. Review the following code changes (git diff) for a Pull Request.

    {FLUTTER_INSTRUCTIONS}

    {GENERAL_INSTRUCTIONS}

    **Instructions for Output:**
    - Format your response in Markdown.
    - Be concise and constructive.
    - Group issues by file if possible.
    - If a file looks good, you don't need to mention it.

    **Diff to Review:**
    {clean_diff}
    """

    try:
        response = model.generate_content(prompt)
        review_text = response.text
    except Exception as e:
        print(f"Error generating review: {e}")
        return

    print("Posting review to GitHub...")
    post_comment(f"## 🤖 Gemini Flutter & Code Review\n\n{review_text}")
    print("Done!")

if __name__ == "__main__":
    review_code()