import os
import google.generativeai as genai

# Your Gemini API key (set as environment variable for security)
API_KEY = "AIzaSyAyqdWhRu-hqRrY27X_Ck4E1O8ghfUAUzk"

# Configure the genai library with your API key
genai.configure(api_key=API_KEY)

# Read input data from file
with open("output.txt", "r", encoding="utf-8") as f:
    file_data = f.read()

# Your custom prompt string
prompt = "Here's the output from NMAP and GoBuster scans, can you summerize and list vulnerable subdirectories, Just give the list thats it and new subdirectory in new line."

# Combine file content and prompt
final_input = file_data + "\n" + prompt

# Initialize the Gemini model
# For chat-based interactions, you might want to use a model like 'gemini-pro'
# 'gemini-1.5-flash' is also a valid model name for the Gemini API
model = genai.GenerativeModel('gemini-1.5-flash')

# Send to Gemini API
# For a single-turn text prompt, use generate_content
response = model.generate_content(final_input)

# Extract response text
result_text = response.text # For direct text responses

# Save response to file
with open("result.txt", "w", encoding="utf-8") as f:
    f.write(result_text)

print("✅ Response saved to result.txt")
