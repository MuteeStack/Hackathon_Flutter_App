"""
Simple test for the end-to-end orchestrator pipeline.
"""
import sys
import os
import io
import asyncio

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from agents.orchestrator import process_service_request

async def test():
    print("Testing end-to-end request...")
    result = await process_service_request(
        user_id="user_123",
        message="Mujhe kal subah G-13 mein AC technician chahiye",
        user_lat=33.6295,
        user_lng=72.9856
    )
    print("Result keys:", list(result.keys()))
    if result.get("booking"):
        print("\n--- BOOKING CONFIRMED ---")
        print("Booking ID:", result["booking"]["booking_id"])
        print("Provider:", result["booking"]["provider_name"])
        print("Time:", result["booking"]["scheduled_time"])
        print("Status:", result["booking"]["status"])
        print("Confirmation Message:", result["booking"]["confirmation_message"])
    else:
        print("\n❌ No booking was created.")

    print("\n--- AGENT TRACE ---")
    for step in result["agent_trace"]["steps"]:
        print(f"\nStep {step['step_number']}: {step['agent_name']}")
        print(f"  Action: {step['action']}")
        print(f"  Input: {step['input_summary']}")
        print(f"  Output: {step['output_summary']}")
        print(f"  Reasoning: {step['reasoning']}")

if __name__ == "__main__":
    asyncio.run(test())
