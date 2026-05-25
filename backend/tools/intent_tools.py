"""
Intent Tools — Intelligent intent parser for natural language service requests.
Uses Google Gemini AI as primary NLU engine for understanding Urdu, Roman Urdu,
and English input. Falls back to keyword matching if Gemini is unavailable.
"""
import re
import json
from google import genai
from config import GEMINI_API_KEY, GEMINI_MODEL


# ============================================================
# KEYWORD DICTIONARIES
# Maps keywords (in English, Roman Urdu, and Urdu) → canonical values
# ============================================================

SERVICE_KEYWORDS = {
    "ac_technician": [
        # English
        "ac", "air conditioner", "air conditioning", "ac repair", "ac service",
        "ac technician", "hvac", "cooling",
        # Roman Urdu
        "ac theek", "ac thek", "ac wala", "ac ki repair", "ac karvana",
        "ac karwana", "ac fix", "ac band", "ac nahi chal raha",
        # Urdu
        "ائیر کنڈیشنر", "اے سی",
    ],
    "plumber": [
        # English
        "plumber", "plumbing", "pipe", "pipeline", "water leak", "tap",
        "drain", "bathroom", "toilet", "washroom",
        # Roman Urdu
        "nalkay", "nalka", "pani", "pani ka masla", "pipe leak",
        "gutter", "nali", "flush", "bathroom ka kaam",
        # Urdu
        "پلمبر", "نلکا", "پانی",
    ],
    "electrician": [
        # English
        "electrician", "electric", "electrical", "wiring", "wire",
        "switch", "socket", "fuse", "power", "light", "fan",
        # Roman Urdu
        "bijli", "bijli wala", "bijli ka kaam", "wiring ka masla",
        "switch kharab", "fan kharab", "light nahi aa rahi",
        # Urdu
        "بجلی", "الیکٹریشن",
    ],
    "tutor": [
        # English
        "tutor", "tuition", "teacher", "teaching", "coaching",
        "academy", "class", "homework", "study",
        # Roman Urdu
        "padhai", "parhana", "parhao", "teacher chahiye", "tuition wala",
        "padha do", "bachon ko parhana",
        # Urdu
        "ٹیوٹر", "ٹیوشن", "استاد", "پڑھائی",
    ],
    "beautician": [
        # English
        "beautician", "beauty", "parlour", "parlor", "salon",
        "makeup", "make up", "facial", "hair", "mehndi", "henna",
        "bridal", "threading", "waxing", "manicure", "pedicure",
        # Roman Urdu
        "makeup wali", "parlour wali", "beauty parlour", "dulhan",
        "mehndi wali", "facial karwana",
        # Urdu
        "بیوٹیشن", "پارلر", "میک اپ",
    ],
    "carpenter": [
        # English
        "carpenter", "carpentry", "wood", "furniture", "cabinet",
        "door", "shelf", "table", "chair", "wardrobe", "cupboard",
        # Roman Urdu
        "mistri", "lakri", "lakri ka kaam", "furniture banwana",
        "darwaza", "almari", "furniture repair",
        # Urdu
        "بڑھئی", "مستری", "فرنیچر", "لکڑی",
    ],
    "painter": [
        # English
        "painter", "painting", "paint", "wall paint", "house paint",
        "whitewash", "color", "colour",
        # Roman Urdu
        "rang", "rangai", "rang karwana", "paint karwana", "deewar",
        "ghar ka paint", "whitewash karwana",
        # Urdu
        "پینٹر", "رنگ", "رنگائی",
    ],
    "home_cleaner": [
        # English
        "cleaner", "cleaning", "home cleaning", "house cleaning",
        "maid", "deep clean", "sweep", "mop", "dust",
        # Roman Urdu
        "safai", "safai wala", "safai wali", "ghar ki safai",
        "saaf karwana", "jharu", "pocha",
        # Urdu
        "صفائی", "صاف",
    ],
    "mechanic": [
        # English
        "mechanic", "car repair", "car service", "auto repair",
        "bike repair", "motorcycle", "engine", "oil change", "tyre", "tire",
        # Roman Urdu
        "gaari", "gari", "car ka masla", "gaari theek",
        "bike theek", "mechanic wala", "gaari ki repair",
        # Urdu
        "مکینک", "گاڑی", "کار",
    ],
}

URGENCY_KEYWORDS = {
    "urgent": [
        # English
        "urgent", "emergency", "asap", "immediately", "right now", "hurry",
        "quick", "fast", "rush",
        # Roman Urdu
        "fori", "jaldi", "abhi", "abhi ke abhi", "jaldi se",
        "bahut jaldi", "turant", "foran",
        # Urdu
        "فوری", "جلدی", "ابھی", "فوراً",
    ],
    "low": [
        # English
        "no rush", "whenever", "no hurry", "take your time", "anytime",
        "free time", "low priority",
        # Roman Urdu
        "koi jaldi nahi", "jab bhi ho", "araam se", "free time mein",
        # Urdu
        "آرام سے",
    ],
}

TIME_KEYWORDS = {
    # ---- Day keywords ----
    "today": ["today", "aaj", "آج"],
    "tomorrow": ["tomorrow", "kal", "کل"],
    # ---- Time-of-day keywords ----
    "morning": ["morning", "subah", "subha", "صبح"],
    "afternoon": ["afternoon", "dopahar", "dopehar", "دوپہر"],
    "evening": ["evening", "sham", "shaam", "شام"],
    "night": ["night", "raat", "رات"],
    # ---- Immediate ----
    "now": ["now", "right now", "abhi", "ابھی"],
}

CITY_KEYWORDS = {
    "Islamabad": ["islamabad", "isb", "اسلام آباد"],
    "Rawalpindi": ["rawalpindi", "pindi", "راولپنڈی", "پنڈی"],
    "Lahore": ["lahore", "lhr", "لاہور"],
    "Karachi": ["karachi", "khi", "کراچی"],
    "Peshawar": ["peshawar", "پشاور"],
    "Faisalabad": ["faisalabad", "fsd", "فیصل آباد"],
}

# Regex for Islamabad sector patterns like G-13, F-8, I-10/4, E-11, H-9, DHA Phase 2, etc.
LOCATION_PATTERN = re.compile(
    r'\b([A-Za-z][-\s]?\d{1,2}(?:/\d{1,2})?)\b'  # G-13, F-8, I-10/4, E 11
    r'|'
    r'\b(DHA\s*(?:Phase\s*)?\d{1,2})\b'            # DHA Phase 2
    r'|'
    r'\b(Bahria\s*(?:Town)?\s*(?:Phase\s*)?\d{0,2})\b',  # Bahria Town Phase 7
    re.IGNORECASE
)


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def _detect_language(text: str) -> str:
    """Detect whether the input is English, Urdu (Unicode), or Roman Urdu."""
    # Check for Urdu Unicode characters (Arabic script range)
    urdu_chars = len(re.findall(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]', text))

    if urdu_chars > len(text) * 0.3:
        return "urdu"

    # Check for Roman Urdu indicators (common Roman Urdu words)
    roman_urdu_markers = [
        "mujhe", "chahiye", "chahie", "karwana", "karvana", "wala", "wali",
        "hai", "hain", "ka", "ki", "ke", "mein", "ko", "se", "kal", "aaj",
        "abhi", "jaldi", "theek", "thek", "kaam", "karo", "karna", "karao",
        "ho", "nahi", "bahut", "yahan", "wahan", "kahan", "kya",
    ]
    text_lower = text.lower()
    roman_urdu_hits = sum(1 for word in roman_urdu_markers if word in text_lower)

    if roman_urdu_hits >= 2:
        return "roman_urdu"

    return "english"


def _detect_service_type(text: str) -> str:
    """Match the user's text against service keyword dictionaries."""
    text_lower = text.lower()

    best_match = "other"
    best_score = 0

    for service_type, keywords in SERVICE_KEYWORDS.items():
        score = 0
        for keyword in keywords:
            if keyword.lower() in text_lower:
                # Longer keyword matches are worth more (more specific)
                score += len(keyword)
        if score > best_score:
            best_score = score
            best_match = service_type

    return best_match


def _detect_location(text: str) -> str:
    """Extract Islamabad sector/area from text using regex."""
    match = LOCATION_PATTERN.search(text)
    if match:
        # Return the first matched group that is not None
        location = next((g for g in match.groups() if g is not None), None)
        if location:
            # Normalize: "G 13" → "G-13", "g-13" → "G-13"
            normalized = re.sub(r'([A-Za-z])\s+(\d)', r'\1-\2', location.strip())
            return normalized.upper()
    return "unknown"


def _detect_city(text: str) -> str:
    """Detect city from text. Defaults to Islamabad."""
    text_lower = text.lower()
    for city, keywords in CITY_KEYWORDS.items():
        for keyword in keywords:
            if keyword in text_lower:
                return city
    return "Islamabad"


def _detect_time_preference(text: str) -> str:
    """Build a time preference string from detected keywords."""
    text_lower = text.lower()

    day_part = ""
    time_part = ""

    # Check for day
    for label, keywords in [("today", TIME_KEYWORDS["today"]),
                            ("tomorrow", TIME_KEYWORDS["tomorrow"])]:
        for kw in keywords:
            if kw in text_lower:
                day_part = label
                break
        if day_part:
            break

    # Check for time of day
    for label, keywords in [("morning", TIME_KEYWORDS["morning"]),
                            ("afternoon", TIME_KEYWORDS["afternoon"]),
                            ("evening", TIME_KEYWORDS["evening"]),
                            ("night", TIME_KEYWORDS["night"])]:
        for kw in keywords:
            if kw in text_lower:
                time_part = label
                break
        if time_part:
            break

    # Check for "now" / "abhi"
    for kw in TIME_KEYWORDS["now"]:
        if kw in text_lower:
            return "right now"

    if day_part and time_part:
        return f"{day_part} {time_part}"
    elif day_part:
        return day_part
    elif time_part:
        return time_part
    else:
        return "as soon as possible"


def _detect_urgency(text: str) -> str:
    """Detect urgency from keywords. Also escalates if 'now' is detected."""
    text_lower = text.lower()

    for kw in URGENCY_KEYWORDS["urgent"]:
        if kw in text_lower:
            return "urgent"

    for kw in URGENCY_KEYWORDS["low"]:
        if kw in text_lower:
            return "low"

    # If time preference is "right now", treat as urgent
    for kw in TIME_KEYWORDS["now"]:
        if kw in text_lower:
            return "urgent"

    return "normal"


# ============================================================
# MAIN PUBLIC FUNCTION (same signature as the old Gemini version)
# ============================================================

def _parse_intent_with_gemini(user_message: str) -> dict:
    """Use Gemini to extract intent from natural language."""
    if not GEMINI_API_KEY:
        raise ValueError("GEMINI_API_KEY is not configured")
        
    client = genai.Client(api_key=GEMINI_API_KEY)
    
    prompt = f"""You are an intent parsing engine for a service booking app in Pakistan.
The user speaks English, Urdu, or Roman Urdu.
Extract the following information from the user's message:
1. service_type: Pick from [ac_technician, plumber, electrician, tutor, beautician, carpenter, painter, home_cleaner, mechanic, other]
2. location: Sector or area name (e.g., "G-13", "F-8", "DHA Phase 2"). Default to "unknown".
3. city: Default to "Islamabad".
4. time_preference: When they want it (e.g., "tomorrow morning", "today evening", "as soon as possible", "right now").
5. urgency: "low", "normal", or "urgent".
6. language_detected: "english", "urdu", or "roman_urdu".

Return ONLY a valid JSON object. No markdown formatting.

User message: "{user_message}"
"""

    try:
        response = client.models.generate_content(model=GEMINI_MODEL, contents=prompt)
        response_text = response.text.strip()
        
        # Clean up if the model wrapped it in markdown code blocks
        if response_text.startswith("```"):
            response_text = response_text.split("\n", 1)[1]
            response_text = response_text.rsplit("```", 1)[0]
            
        data = json.loads(response_text.strip())
        data["original_input"] = user_message
        return data
    except Exception as e:
        print(f"Gemini intent parsing failed: {e}")
        raise

def parse_intent(user_message: str) -> dict:
    """
    Parse a user's natural language service request to extract structured intent.
    Tries Gemini AI first. If API key is missing or call fails, falls back to
    offline keyword matching.

    Args:
        user_message: The raw text from the user
                      (e.g., "Mujhe kal subah G-13 mein AC technician chahiye")

    Returns:
        A dictionary with: service_type, location, city, time_preference,
                           urgency, language_detected, original_input
    """
    # 1. Try Gemini AI
    try:
        return _parse_intent_with_gemini(user_message)
    except Exception:
        # 2. Fallback to keyword matching
        print("Falling back to keyword-based intent parsing...")
        return {
            "service_type": _detect_service_type(user_message),
            "location": _detect_location(user_message),
            "city": _detect_city(user_message),
            "time_preference": _detect_time_preference(user_message),
            "urgency": _detect_urgency(user_message),
            "language_detected": _detect_language(user_message),
            "original_input": user_message,
        }
