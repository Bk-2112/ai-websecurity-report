import os
import google.generativeai as genai

# Your Gemini API key (set as environment variable for security)
# Make sure to set this environment variable: export GEMINI_API_KEY='YOUR_API_KEY_HERE'
API_KEY = "YOUR_GEMINI_API_KEY_HERE"

if not API_KEY:
    print("Error: GEMINI_API_KEY environment variable not set.")
    print("Please set it using: export GEMINI_API_KEY='YOUR_API_KEY_HERE'")
    exit()

# Configure the genai library with your API key
genai.configure(api_key=API_KEY)

# Read input data from file
try:
    with open("result.txt", "r", encoding="utf-8") as f:
        file_data = f.read()
except FileNotFoundError:
    print("Error: 'results.txt' not found. Please ensure the file exists.")
    exit()

# Your custom prompt string
prompt = "Here's a scan data from various tools, make me a detailed summary on this, Summarize this scan data and provide a clear vulnerability report."

# Combine file content and prompt
final_input = file_data + "\n" + prompt

# Initialize the Gemini model
# Using 'gemini-1.5-flash' as specified, it's good for summarization.
model = genai.GenerativeModel('gemini-1.5-flash')

# Send to Gemini API
try:
    response = model.generate_content(final_input)
    result_text = response.text # For direct text responses
except Exception as e:
    print(f"Error calling Gemini API: {e}")
    # You might want to print more details about the response if it's an API error
    # print(response.prompt_feedback)
    # print(response.candidates)
    exit()


# Save response to file
with open("summary.txt", "w", encoding="utf-8") as f:
    f.write(result_text)

print("✅ Response saved to summary.txt")

os.system("cat result.txt")
