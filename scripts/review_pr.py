import os
import requests
import google.generativeai as genai
import sys
import re
import fnmatch

# Configure Gemini
# Get your key from: https://aistudio.google.com/app/apikey
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
REPO_NAME = os.getenv("GITHUB_REPOSITORY")  # e.g., "username/repo"
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
    - Check for unremoved listeners (ValueNotifier, ChangeNotifier, Streams)
    - Verify dispose() methods clean up controllers, listeners, and subscriptions
    - Look for potential memory leaks
    - Ensure async callbacks do not update state after dispose (mounted checks)

2. **Null Safety & Error Handling**
    - Verify null-aware operators (?., ??) are used correctly
    - Verify there is no usage of force unwrapping (!) or as it is called in dart the bang
      operator
    - Check for proper null checks before accessing nullable properties
    - Ensure async operations have try-catch blocks with appropriate error handling
    - Validate BuildContext usage doesn't cross async gaps

3. **Performance Optimization**
    - Use `const` constructors where possible to reduce rebuilds
    - Check for unnecessary widget rebuilds (use const, keys, or memoization)
    - Verify hooks and child widgets are used instead of builders
    - Look for expensive operations in build() methods
    - Ensure proper use of RepaintBoundary for complex widgets
    - Make sure there are no hooks inside conditions or loops
    - Avoid large widget trees in single build methods
    - Prefer stateless and hook widgets instead of stateful widgets
    - Provide suggestions for separating pure business logic from UI code especially from inside
      the hooks

4. **Code Style & Best Practices**
    - Follow Dart naming: lowerCamelCase for variables/methods, UpperCamelCase for classes
    - Avoid magic numbers—use named constants
    - Prefer named parameters for functions with multiple arguments
    - Use widget subclasses instead of methods that return widgets
    - Use `.s` extension for responsive sizing (e.g., `16.0.s` not `16.0`)
    - Use `ScreenSideOffset.defaultSmallMargin` or `.small` for margins
    - Don't use verbs (`getSomethingProvider`), use data names
    - Use SeparatedColumn/SeparatedRow for lists with separators between items

5. **Testing & Maintainability**
    - Identify integration test scenarios for critical flows
    - Check for testability: avoid static dependencies, use dependency injection

6. **Common Flutter Pitfalls**
    - Keys are used correctly in ListView/GridView
    - Infinite loops in widget rebuilds are avoided
    - MediaQuery/Theme are not accessed unnecessarily
    - GlobalKey usage is justified and not overused

7. **Security & Privacy**
    - Ensure no secrets (private keys, passkeys, JWTs, seeds) are logged
    - Do not store secrets in SharedPreferences; use secure storage
"""

GENERAL_INSTRUCTIONS = """
### 🛡️ General Code Quality (Apply to all files)
1. Add meaningful comments for complex logic.
2. Ensure no secrets or environment values are hardcoded.
3. Verify proper use of linters (flutter analyze).
4. Maintain architectural consistency (e.g., separation of concerns).
5. Verify that there is no code duplication and the code follows the DRY principle.
6. Verify that magic numbers are not used and are replaced with named constants where appropriate.
7. Verify that existing design patterns, if any, are used correctly and consistently.
8. Identify areas where poorly structured or tightly coupled code could be refactored using an appropriate design pattern, without overengineering.
9. Check that responsibilities are clearly separated and that classes or functions have a single, well-defined purpose.
10. Check for overly complex logic and verify that it can be simplified without changing behavior.
11. Verify that comments are present only where the intent or logic is not obvious from the code.
12. Assess overall readability and maintainability of the code.
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