"""
Quick test script for the custom intent parser.
Tests English, Roman Urdu, and Urdu inputs.
"""
import sys
import os
import io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from tools.intent_tools import parse_intent
import json


test_cases = [
    # Roman Urdu
    "Mujhe kal subah G-13 mein AC technician chahiye",
    "Mujhe urgent plumber chahiye F-8 Islamabad main",
    "Bijli wala chahiye abhi E-11 mein jaldi",
    "Bachon ko parhana hai I-10 mein kal sham",
    "Safai karwani hai ghar ki aaj subah DHA Phase 2",
    
    # English
    "I need a plumber in G-9 tomorrow morning",
    "Looking for an electrician in F-6, it's urgent",
    "Need a painter for my house in Bahria Town Phase 7",
    "Car mechanic near I-8 right now",
    
    # Urdu (Unicode)
    "مجھے ابھی پلمبر چاہیے G-13 میں",
    "بجلی والا چاہیے فوری",
    
    # Edge cases
    "AC theek karwana hai fori taur pe",       # No location
    "hello",                                    # Meaningless input
    "mujhe koi kaam karwana hai G-13 mein",    # Vague service
]

print("=" * 80)
print("CUSTOM INTENT PARSER — TEST RESULTS")
print("=" * 80)

for i, msg in enumerate(test_cases, 1):
    result = parse_intent(msg)
    print(f"\n--- Test {i} ---")
    print(f"  Input:    \"{msg}\"")
    print(f"  Service:  {result['service_type']}")
    print(f"  Location: {result['location']}")
    print(f"  City:     {result['city']}")
    print(f"  Time:     {result['time_preference']}")
    print(f"  Urgency:  {result['urgency']}")
    print(f"  Language: {result['language_detected']}")

print("\n" + "=" * 80)
print("ALL TESTS COMPLETE")
print("=" * 80)
