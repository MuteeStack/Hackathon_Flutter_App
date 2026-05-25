# Deploying this backend to Railway (no Docker)

This folder contains a FastAPI app that can be deployed on Railway without a Dockerfile.

Prerequisites:
- Push this repository to GitHub.
- Create a Railway account (https://railway.app) and connect your GitHub account.

Quick steps (Railway web UI):
1. In Railway, create a new project and choose "Deploy from GitHub".
2. Select this repository and the `backend/` folder as the service root.
3. Set the build command (optional): `pip install -r requirements.txt`.
4. Set the start command (or use `Procfile`): `uvicorn main:app --host 0.0.0.0 --port $PORT`.
5. Add environment variables under the Project Settings (e.g., secrets, API keys).
6. Deploy and copy the public URL Railway provides — use this URL in your Flutter app.

Railway CLI quick deploy (alternative):
```bash
# install CLI
npm i -g @railway/cli

# from backend/
cd backend
railway init        # follow prompts to link or create a project
railway up          # deploys the current folder
```

Notes:
- The `Procfile` is already present and used by Railway to start the web process.
- Ensure CORS is allowed (the app already allows all origins).
- For persistent storage or databases, add Railway plugins and set the connection URL as an env var.
