import os
import requests
import google.generativeai as genai

# Configure Gemini
# Get your key from: https://aistudio.google.com/app/apikey
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
GITHUB_TOKEN = os.getenv("GITHUB_TOKEN")
REPO_NAME = os.getenv("GITHUB_REPOSITORY")  # e.g., "username/repo"
PR_NUMBER = os.getenv("PR_NUMBER")

if not GEMINI_API_KEY:
    raise ValueError("GEMINI_API_KEY is missing")

genai.configure(api_key=GEMINI_API_KEY)

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

def get_model():
    """Tries to find a working model and prints available ones for debugging."""
    print("Listing available models...")
    available_models = []
    try:
        for m in genai.list_models():
            if 'generateContent' in m.supported_generation_methods:
                available_models.append(m.name)
                print(f" - {m.name}")
    except Exception as e:
        print(f"Warning: Could not list models: {e}")

    # Priority list of models to try
    # gemini-1.5-flash is standard, but sometimes requires -latest or -001
    candidates = [
        "gemini-2.5-flash",
        "gemini-2.5-flash-latest",
        "gemini-1.5-flash",
        "gemini-pro"
    ]

    for candidate in candidates:
        try:
            print(f"Attempting to use model: {candidate}")
            model = genai.GenerativeModel(candidate)
            # Test the model with a tiny prompt to ensure it works (avoids 404 later)
            model.generate_content("test")
            print(f"Success! Using {candidate}")
            return model
        except Exception as e:
            print(f"Failed to initialize {candidate}: {e}")

    raise RuntimeError("No working Gemini models found. Check the logs for the list of available models.")

def review_code():
    try:
        model = get_model()
    except Exception as e:
        print(f"Error selecting model: {e}")
        return

    print(f"Fetching diff for PR #{PR_NUMBER} in {REPO_NAME}...")
    diff_text = get_pr_diff()

    # Guard clause for empty or too large diffs
    if not diff_text:
        print("No changes found in diff.")
        return

    if len(diff_text) > 100000:
        diff_text = diff_text[:100000] + "\n...(truncated due to size limit)"

    print("Sending diff to Gemini for review...")

    prompt = f"""
    Act as a Senior Software Engineer. Review the following code changes (git diff) for a Pull Request.

    Focus on:
    1. Potential bugs or logic errors.
    2. Security vulnerabilities.
    3. Code readability and style improvements.

    Format your response in Markdown. Be concise and constructive.

    Diff:
    {diff_text}
    """

    try:
        response = model.generate_content(prompt)
        review_text = response.text
    except Exception as e:
        print(f"Error generating review: {e}")
        return

    print("Posting review to GitHub...")
    post_comment(f"## 🤖 Gemini AI Code Review\n\n{review_text}")
    print("Done!")

if __name__ == "__main__":
    review_code()