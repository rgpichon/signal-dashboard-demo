#!/bin/bash
echo "Starting SIGNAL..."
# Start API in background
PYTHONPATH=. uvicorn signals.api.server:app --port 8000 &
API_PID=$!
echo "API running (PID $API_PID)"
# Start dashboard server
echo "Dashboard at http://localhost:3000"
python signals/dashboard/serve.py
