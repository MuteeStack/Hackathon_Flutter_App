"""
Booking Tools — Simulates the booking lifecycle.
Writes bookings to Firebase Firestore or a local JSON fallback store.
"""
import uuid
import os
import json
from datetime import datetime
from typing import Optional

# Local JSON database fallback path
LOCAL_DB_PATH = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "data", "bookings.json")

def _load_local_bookings() -> dict:
    if os.path.exists(LOCAL_DB_PATH):
        try:
            with open(LOCAL_DB_PATH, "r", encoding="utf-8") as f:
                return json.load(f)
        except Exception:
            return {}
    return {}

def _save_local_bookings(bookings: dict):
    os.makedirs(os.path.dirname(LOCAL_DB_PATH), exist_ok=True)
    try:
        with open(LOCAL_DB_PATH, "w", encoding="utf-8") as f:
            json.dump(bookings, f, indent=2, ensure_ascii=False)
    except Exception as e:
        print(f"Failed to save local bookings: {e}")

# Initialize Firestore
_db = None
try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    
    try:
        app = firebase_admin.get_app()
        _db = firestore.client()
        print("Firebase Admin already initialized. Using existing Firestore client.")
    except ValueError:
        cred_json = os.getenv("FIREBASE_CREDENTIALS_JSON")
        cred_path = os.getenv("FIREBASE_CREDENTIALS_PATH", "./firebase-service-account.json")
        
        if cred_json:
            import json
            cert_dict = json.loads(cred_json)
            cred = credentials.Certificate(cert_dict)
            firebase_admin.initialize_app(cred)
            _db = firestore.client()
            print("Firebase Admin initialized from JSON string. Firestore client ready.")
        elif os.path.exists(cred_path):
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
            _db = firestore.client()
            print("Firebase Admin initialized with credentials file. Firestore client ready.")
        else:
            firebase_admin.initialize_app(options={'projectId': 'ai-informal-economy'})
            _db = firestore.client()
            print("Firebase Admin initialized with project ID. Firestore client ready.")
except Exception as e:
    print(f"Firestore not available (using local JSON store fallback): {e}")


def create_booking(
    user_id: str,
    provider_id: str,
    provider_name: str,
    service_type: str,
    location: str,
    scheduled_time: str,
    provider_phone: str = ""
) -> dict:
    """
    Create a new booking and write to Firebase Firestore or local JSON database.
    """
    booking_id = f"BK-{uuid.uuid4().hex[:8].upper()}"
    
    booking = {
        "booking_id": booking_id,
        "user_id": user_id,
        "provider_id": provider_id,
        "provider_name": provider_name,
        "service_type": service_type,
        "location": location,
        "scheduled_time": scheduled_time,
        "status": "confirmed",
        "provider_phone": provider_phone,
        "confirmation_message": (
            f"✅ Booking Confirmed!\n"
            f"📋 Booking ID: {booking_id}\n"
            f"🔧 Service: {service_type.replace('_', ' ').title()}\n"
            f"👨‍🔧 Provider: {provider_name}\n"
            f"📍 Location: {location}\n"
            f"🕐 Time: {scheduled_time}\n"
            f"📞 Provider Contact: {provider_phone}\n\n"
            f"Your provider has been notified and will arrive at the scheduled time."
        ),
        "created_at": datetime.now().isoformat(),
        "updated_at": datetime.now().isoformat()
    }
    
    # Save to Firestore if available
    if _db:
        try:
            _db.collection("bookings").document(booking_id).set(booking)
            print(f"Saved booking {booking_id} to Firestore.")
            return booking
        except Exception as e:
            print(f"Firestore save failed: {e}. Falling back to local store.")
            
    # Fallback to local store
    local_bookings = _load_local_bookings()
    local_bookings[booking_id] = booking
    _save_local_bookings(local_bookings)
    return booking


def get_booking(booking_id: str) -> Optional[dict]:
    """Get a booking by its ID."""
    if _db:
        try:
            doc = _db.collection("bookings").document(booking_id).get()
            if doc.exists:
                return doc.to_dict()
            return None
        except Exception as e:
            print(f"Firestore get_booking failed: {e}. Falling back to local store.")
            
    local_bookings = _load_local_bookings()
    return local_bookings.get(booking_id)


def get_user_bookings(user_id: str) -> list:
    """Get all bookings for a user."""
    if _db:
        try:
            docs = _db.collection("bookings").where("user_id", "==", user_id).stream()
            bookings = [doc.to_dict() for doc in docs]
            # Sort newest first
            bookings.sort(key=lambda x: x.get("created_at", ""), reverse=True)
            return bookings
        except Exception as e:
            print(f"Firestore get_user_bookings failed: {e}. Falling back to local store.")
            
    local_bookings = _load_local_bookings()
    bookings = [b for b in local_bookings.values() if b.get("user_id") == user_id]
    bookings.sort(key=lambda x: x.get("created_at", ""), reverse=True)
    return bookings


def update_booking_status(booking_id: str, new_status: str) -> dict:
    """Update the status of a booking."""
    updated_at = datetime.now().isoformat()
    if _db:
        try:
            doc_ref = _db.collection("bookings").document(booking_id)
            doc = doc_ref.get()
            if doc.exists:
                doc_ref.update({
                    "status": new_status,
                    "updated_at": updated_at
                })
                return doc_ref.get().to_dict()
        except Exception as e:
            print(f"Firestore update_booking_status failed: {e}. Falling back to local store.")
            
    local_bookings = _load_local_bookings()
    if booking_id in local_bookings:
        local_bookings[booking_id]["status"] = new_status
        local_bookings[booking_id]["updated_at"] = updated_at
        _save_local_bookings(local_bookings)
        return local_bookings[booking_id]
    return {"error": f"Booking {booking_id} not found"}


def cancel_booking(booking_id: str) -> dict:
    """Cancel a booking."""
    return update_booking_status(booking_id, "cancelled")
