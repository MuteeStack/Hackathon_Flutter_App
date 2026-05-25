"""
Pydantic models for request/response validation across the API and agents.
"""
from pydantic import BaseModel, Field
from typing import Optional, List
from enum import Enum
from datetime import datetime


# --- Enums ---

class ServiceType(str, Enum):
    AC_TECHNICIAN = "ac_technician"
    PLUMBER = "plumber"
    ELECTRICIAN = "electrician"
    TUTOR = "tutor"
    BEAUTICIAN = "beautician"
    CARPENTER = "carpenter"
    PAINTER = "painter"
    HOME_CLEANER = "home_cleaner"
    MECHANIC = "mechanic"
    OTHER = "other"


class BookingStatus(str, Enum):
    PENDING = "pending"
    CONFIRMED = "confirmed"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class Language(str, Enum):
    ENGLISH = "english"
    URDU = "urdu"
    ROMAN_URDU = "roman_urdu"


# --- Intent Models ---

class ParsedIntent(BaseModel):
    """Result of the Intent Agent parsing user input."""
    service_type: str = Field(..., description="Type of service requested")
    location: str = Field(..., description="Area or sector requested")
    city: str = Field(default="Islamabad", description="City name")
    time_preference: str = Field(default="as soon as possible", description="When the user needs the service")
    urgency: str = Field(default="normal", description="low, normal, or urgent")
    language_detected: str = Field(default="english", description="Language of original input")
    original_input: str = Field(default="", description="Original user message")


# --- Provider Models ---

class ProviderLocation(BaseModel):
    area: str
    city: str
    lat: float
    lng: float


class ProviderAvailability(BaseModel):
    monday: List[str] = Field(default_factory=list)
    tuesday: List[str] = Field(default_factory=list)
    wednesday: List[str] = Field(default_factory=list)
    thursday: List[str] = Field(default_factory=list)
    friday: List[str] = Field(default_factory=list)
    saturday: List[str] = Field(default_factory=list)
    sunday: List[str] = Field(default_factory=list)


class Provider(BaseModel):
    id: str
    name: str
    name_urdu: str = ""
    service_type: str
    service_categories: List[str] = []
    location: ProviderLocation
    rating: float = 0.0
    total_reviews: int = 0
    availability: ProviderAvailability = ProviderAvailability()
    price_range: str = ""
    phone: str = ""
    verified: bool = False
    experience_years: int = 0
    languages: List[str] = []


class RankedProvider(BaseModel):
    """Provider with ranking metadata from the Matching Agent."""
    provider: Provider
    rank: int
    distance_km: float = 0.0
    match_score: float = 0.0
    reasoning: str = ""
    available_slots: List[str] = []


# --- Booking Models ---

class Booking(BaseModel):
    booking_id: str = ""
    user_id: str = ""
    provider: Provider
    service_type: str
    location: str
    scheduled_time: str
    status: BookingStatus = BookingStatus.PENDING
    confirmation_message: str = ""
    created_at: str = Field(default_factory=lambda: datetime.now().isoformat())
    reminder_scheduled: bool = False
    reminder_time: str = ""


class BookingReceipt(BaseModel):
    booking_id: str
    provider_name: str
    service_type: str
    location: str
    scheduled_time: str
    status: str
    confirmation_message: str
    reminder_time: str = ""


# --- API Request/Response Models ---

class ServiceRequest(BaseModel):
    """User's incoming service request from the Flutter app."""
    user_id: str = Field(default="user_001", description="User identifier")
    message: str = Field(..., description="Natural language service request")
    lat: Optional[float] = Field(default=None, description="User's latitude")
    lng: Optional[float] = Field(default=None, description="User's longitude")


class AgentStep(BaseModel):
    """A single step in the agent's reasoning trace."""
    step_number: int
    agent_name: str
    action: str
    input_summary: str
    output_summary: str
    reasoning: str = ""
    timestamp: str = Field(default_factory=lambda: datetime.now().isoformat())


class ServiceResponse(BaseModel):
    """Full response sent back to the Flutter app."""
    request_id: str
    parsed_intent: ParsedIntent
    recommended_providers: List[RankedProvider] = []
    booking: Optional[BookingReceipt] = None
    followup: dict = {}
    agent_trace: List[AgentStep] = []
    total_processing_time: float = 0.0
