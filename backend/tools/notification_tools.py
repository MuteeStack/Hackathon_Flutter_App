"""
Notification Tools — Simulates follow-up actions like reminders and status updates.
"""
from datetime import datetime, timedelta
from dateutil import parser as dateparser

# In-memory reminders store
_reminders_store = {}


def schedule_reminder(
    booking_id: str,
    user_id: str,
    provider_name: str,
    service_type: str,
    scheduled_time: str,
    location: str,
    remind_before_minutes: int = 60
) -> dict:
    """
    Schedule a reminder for an upcoming booking.
    
    Args:
        booking_id: The booking to remind about
        user_id: User to remind
        provider_name: Name of the service provider
        service_type: Type of service
        scheduled_time: When the service is scheduled
        location: Service location
        remind_before_minutes: Minutes before appointment to remind (default: 60)
    
    Returns:
        Reminder details
    """
    try:
        # Try to parse the scheduled time
        sched_dt = dateparser.parse(scheduled_time)
        if sched_dt:
            reminder_time = sched_dt - timedelta(minutes=remind_before_minutes)
        else:
            reminder_time = datetime.now() + timedelta(hours=1)
    except Exception:
        reminder_time = datetime.now() + timedelta(hours=1)
    
    reminder = {
        "reminder_id": f"REM-{booking_id}",
        "booking_id": booking_id,
        "user_id": user_id,
        "reminder_time": reminder_time.isoformat(),
        "message": (
            f"⏰ Reminder: Your {service_type.replace('_', ' ').title()} appointment is in "
            f"{remind_before_minutes} minutes!\n"
            f"👨‍🔧 Provider: {provider_name}\n"
            f"📍 Location: {location}\n"
            f"🕐 Scheduled: {scheduled_time}"
        ),
        "status": "scheduled",
        "created_at": datetime.now().isoformat()
    }
    
    _reminders_store[reminder["reminder_id"]] = reminder
    return reminder


def send_status_update(
    booking_id: str,
    status: str,
    message: str = ""
) -> dict:
    """
    Simulate sending a status update notification.
    
    Args:
        booking_id: The booking ID
        status: Current status
        message: Optional custom message
    
    Returns:
        Status update notification details
    """
    status_messages = {
        "confirmed": "✅ Your booking has been confirmed! The provider will arrive at the scheduled time.",
        "in_progress": "🔧 Your service provider is on the way!",
        "completed": "🎉 Service completed! Thank you for using our platform. Please rate your experience.",
        "cancelled": "❌ Your booking has been cancelled. We hope to serve you again."
    }
    
    notification = {
        "booking_id": booking_id,
        "status": status,
        "notification_message": message or status_messages.get(status, f"Status updated to: {status}"),
        "sent_at": datetime.now().isoformat()
    }
    
    return notification


def check_booking_status(booking_id: str) -> dict:
    """
    Check the current status of a booking and any pending reminders.
    
    Args:
        booking_id: The booking ID to check
    
    Returns:
        Status summary including reminders
    """
    reminder_id = f"REM-{booking_id}"
    reminder = _reminders_store.get(reminder_id)
    
    return {
        "booking_id": booking_id,
        "has_reminder": reminder is not None,
        "reminder_details": reminder,
        "checked_at": datetime.now().isoformat()
    }


def simulate_completion_flow(booking_id: str, provider_name: str) -> dict:
    """
    Simulate the complete follow-up flow after service completion.
    
    Args:
        booking_id: The booking that was completed
        provider_name: Name of the provider
    
    Returns:
        Completion summary with all follow-up actions
    """
    return {
        "booking_id": booking_id,
        "completion_actions": [
            {
                "action": "status_update",
                "detail": "Booking marked as completed",
                "timestamp": datetime.now().isoformat()
            },
            {
                "action": "rating_request",
                "detail": f"Rating request sent for {provider_name}",
                "timestamp": (datetime.now() + timedelta(minutes=30)).isoformat()
            },
            {
                "action": "feedback_survey",
                "detail": "Service quality survey scheduled",
                "timestamp": (datetime.now() + timedelta(hours=2)).isoformat()
            }
        ]
    }
