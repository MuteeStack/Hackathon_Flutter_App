"""
Configuration module — loads API keys and settings from .env
"""
import os
from dotenv import load_dotenv

load_dotenv()

# --- API Keys ---
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY", "")
GOOGLE_MAPS_API_KEY = os.getenv("GOOGLE_MAPS_API_KEY", "")
FIREBASE_CREDENTIALS_PATH = os.getenv("FIREBASE_CREDENTIALS_PATH", "./firebase-service-account.json")

# --- Gemini Model ---
GEMINI_MODEL = "gemini-2.0-flash"

# --- App Settings ---
APP_NAME = "AI Service Orchestrator"
APP_VERSION = "1.0.0"
DEFAULT_CITY = "Islamabad"
DEFAULT_COUNTRY = "Pakistan"
MAX_PROVIDER_RESULTS = 5
