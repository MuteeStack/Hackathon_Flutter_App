"""
FastAPI Server — Main entry point for the AI Service Orchestrator.
Exposes REST API endpoints that the Flutter app communicates with.
"""
import sys
import os

# Add backend directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import time
import asyncio

from config import APP_NAME, APP_VERSION
from models.schemas import ServiceRequest
from agents.orchestrator import process_service_request, execute_booking
from tools.booking_tools import get_booking, get_user_bookings, update_booking_status, cancel_booking

# --- App Setup ---
app = FastAPI(
    title=APP_NAME,
    version=APP_VERSION,
    description="Agentic AI system for informal economy service orchestration"
)

# CORS — allow Flutter app to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# --- Health Check ---
@app.get("/")
async def root():
    return {
        "app": APP_NAME,
        "version": APP_VERSION,
        "status": "running",
        "endpoints": {
            "service_request": "POST /api/service-request",
            "bookings": "GET /api/bookings/{user_id}",
            "booking_detail": "GET /api/booking/{booking_id}",
            "cancel_booking": "POST /api/booking/{booking_id}/cancel",
            "trace": "GET /api/trace/{request_id}",
        }
    }


# --- Store for request traces ---
_trace_store = {}


# --- Main Service Request Endpoint ---
@app.post("/api/service-request")
async def handle_service_request(request: ServiceRequest):
    """
    Main endpoint — receives natural language service request,
    runs it through the full agent pipeline, and returns results.
    """
    try:
        start_time = time.time()
        
        result = await process_service_request(
            user_id=request.user_id,
            message=request.message,
            user_lat=request.lat,
            user_lng=request.lng
        )
        
        # Store trace for later retrieval
        request_id = result.get("request_id", "")
        _trace_store[request_id] = result.get("agent_trace", {})
        
        return result
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error processing request: {str(e)}")


class BookingRequest(BaseModel):
    user_id: str
    provider: dict
    intent: dict

@app.post("/api/book")
async def book_provider(request: BookingRequest):
    """
    Endpoint for user-initiated booking after provider selection.
    Triggers the Booking Agent and Follow-Up Agent.
    """
    try:
        result = await asyncio.to_thread(
            execute_booking,
            user_id=request.user_id,
            provider=request.provider,
            intent=request.intent
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error creating booking: {str(e)}")

# --- Booking Endpoints ---
@app.get("/api/bookings/{user_id}")
async def get_bookings(user_id: str):
    """Get all bookings for a user."""
    bookings = get_user_bookings(user_id)
    return {"user_id": user_id, "bookings": bookings, "count": len(bookings)}


@app.get("/api/booking/{booking_id}")
async def get_booking_detail(booking_id: str):
    """Get details of a specific booking."""
    booking = get_booking(booking_id)
    if not booking:
        raise HTTPException(status_code=404, detail=f"Booking {booking_id} not found")
    return booking


@app.post("/api/booking/{booking_id}/cancel")
async def cancel_booking_endpoint(booking_id: str):
    """Cancel a booking."""
    result = cancel_booking(booking_id)
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result


class StatusUpdateRequest(BaseModel):
    status: str

@app.post("/api/booking/{booking_id}/status")
async def update_status(booking_id: str, request: StatusUpdateRequest):
    """Update booking status."""
    result = update_booking_status(booking_id, request.status)
    if "error" in result:
        raise HTTPException(status_code=404, detail=result["error"])
    return result


# --- Trace Endpoint ---
@app.get("/api/trace/{request_id}")
async def get_trace(request_id: str):
    """Get agent reasoning trace for a specific request."""
    trace = _trace_store.get(request_id)
    if not trace:
        raise HTTPException(status_code=404, detail=f"Trace for {request_id} not found")
    return trace


# --- WebSocket for Real-time Updates ---
class ConnectionManager:
    def __init__(self):
        self.active_connections: dict = {}
    
    async def connect(self, websocket: WebSocket, user_id: str):
        await websocket.accept()
        self.active_connections[user_id] = websocket
    
    def disconnect(self, user_id: str):
        self.active_connections.pop(user_id, None)
    
    async def send_update(self, user_id: str, message: dict):
        ws = self.active_connections.get(user_id)
        if ws:
            await ws.send_json(message)


manager = ConnectionManager()


@app.websocket("/ws/updates/{user_id}")
async def websocket_endpoint(websocket: WebSocket, user_id: str):
    """WebSocket endpoint for real-time booking updates."""
    await manager.connect(websocket, user_id)
    try:
        while True:
            data = await websocket.receive_text()
            # Echo back for now — can be used for real-time status polling
            await websocket.send_json({"type": "ack", "message": "received"})
    except WebSocketDisconnect:
        manager.disconnect(user_id)


# --- Run ---
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
