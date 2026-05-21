# 🤖 AI Service Orchestrator for Informal Economy

An **Agentic AI System** that automates the end-to-end lifecycle of informal economy service requests — from user intent to booking and follow-up.

## 📐 Architecture

```
Flutter App → FastAPI Backend → Google ADK Orchestrator → 5 AI Agents → Gemini + Maps + Firebase
```

### Agent Pipeline
1. **Intent Understanding Agent** — Parses Urdu/Roman Urdu/English using Gemini
2. **Provider Discovery Agent** — Searches mock DB + Google Maps Places API
3. **Matching & Ranking Agent** — Gemini-powered intelligent ranking with reasoning
4. **Booking Agent** — Simulates booking, generates confirmation receipts
5. **Follow-Up Agent** — Schedules reminders and status updates

## 🛠 Tech Stack

| Component | Technology |
|-----------|-----------|
| Mobile App | Flutter (Dart) |
| Backend | Python FastAPI |
| Agent Framework | Google ADK (`google-adk`) |
| LLM | Google Gemini 2.0 Flash |
| Maps | Google Maps / Places API |
| Database | In-memory (Firebase-ready) |

## 🚀 Setup

### Backend
```bash
cd backend
python -m venv .venv
.venv\Scripts\activate  # Windows
pip install -r requirements.txt
```

Add your API keys to `backend/.env`:
```
GEMINI_API_KEY=your_key_here
GOOGLE_MAPS_API_KEY=your_key_here
```

Run the server:
```bash
cd backend
python main.py
```

### Flutter App
```bash
cd ai_app
flutter pub get
flutter run
```

> **Note:** Update `baseUrl` in `lib/constants.dart` to match your backend IP.

## 📱 Screens

- **Chat Screen** — WhatsApp-style natural language input
- **Results Screen** — Ranked providers with AI reasoning
- **Trace Screen** — Full agent reasoning pipeline (for judges)
- **History Screen** — Past bookings and status tracking

## 🔧 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/service-request` | Main service request |
| GET | `/api/bookings/{user_id}` | User's bookings |
| GET | `/api/booking/{booking_id}` | Booking detail |
| POST | `/api/booking/{booking_id}/cancel` | Cancel booking |
| GET | `/api/trace/{request_id}` | Agent trace logs |

## 🧠 Gemini API Modules & Purpose

To automate the informal economy service sector, we use the **Gemini 2.0 Flash API** across three core intelligent modules. Instead of relying on hardcoded logic, Gemini acts as the brain of the orchestrator:

1. **Natural Language Intent Module (`tools/intent_tools.py`)**
   - **Purpose**: Users in Pakistan speak a mix of English, Urdu, and Roman Urdu. Gemini parses this unstructured input and extracts strict JSON metadata (Service Type, Location, City, Time Preference, Urgency).
   - **Why Gemini?**: Traditional NLP fails with Roman Urdu ("Mujhe AC theek karwana hai"). Gemini flawlessly translates and maps this to structured data our database can query.

2. **Intelligent Ranking Module (`agents/orchestrator.py`)**
   - **Purpose**: Once providers are found, Gemini acts as a "Matching Expert". It is fed the user's urgency and a list of providers (with their distances, ratings, and experience).
   - **Why Gemini?**: It doesn't just sort by distance; it reasons like a human. If the user marks it "urgent", Gemini prioritizes proximity and verified status over a slightly cheaper price, generating a `match_score` out of 100 and a 1-sentence reasoning for the user to read.

3. **Contextual Follow-up Module (`agents/orchestrator.py`)**
   - **Purpose**: Generates personalized advice once a booking is made.
   - **Why Gemini?**: If a user books a plumber, Gemini tells them "Please ensure the main water valve is accessible." If they book a beautician, it advises them on setup. This creates a deeply personalized user experience.

## ⚠️ Assumptions & Limitations

- Mock provider dataset (20 providers across Islamabad)
- In-memory booking store (resets on server restart)
- Google Maps API optional (falls back to mock data)
- Simulated notifications (no actual SMS/push)

## 👥 Team

Built for Google Hackathon — Challenge 2: AI Service Orchestrator for Informal Economy
