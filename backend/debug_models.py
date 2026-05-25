import os
from google import genai
from dotenv import load_dotenv

load_dotenv()
api_key = os.getenv("GEMINI_API_KEY")

print(f"Checking API Key: {api_key[:10] if api_key else 'NOT SET'}...")

try:
    client = genai.Client(api_key=api_key)
    print("\n--- Available Models ---")
    # In the new SDK, models are listed differently or we can just try to see names
    for model in client.models.list():
        print(f"- {model.name}")
    print("\n------------------------")
except Exception as e:
    print(f"\n❌ Error listing models: {str(e)}")
