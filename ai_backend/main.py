from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client, Client
import os
from dotenv import load_dotenv
from typing import Optional
import datetime
from transformers import pipeline

# Load environment variables
load_dotenv()

app = FastAPI(title="SOS AI Backend", version="1.0.0")

# Enable CORS for frontend flexibility
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# 1. Initialize Supabase
supabase_url = os.environ.get("SUPABASE_URL")
supabase_key = os.environ.get("SUPABASE_SERVICE_ROLE_KEY")

if not supabase_url or not supabase_key:
    # Ensure it doesn't crash immediately but warns the developer
    print("WARNING: Missing Supabase credentials in .env. Database operations will fail.")
    supabase = None
else:
    supabase: Client = create_client(supabase_url, supabase_key)

# 2. Initialize NLP Model (Using Zero-Shot Classification for flexible SOS analysis)
# Using a fast but effective sequence classification pipeline for the hackathon
print("Loading AI Model... (This may take a moment to download the transformer elements)")
try:
    classifier = pipeline("zero-shot-classification", model="typeform/distilbert-base-uncased-mnli")
    print("AI Model Loaded Successfully!")
except Exception as e:
    classifier = None
    print(f"Warning: Failed to load transformers pipeline. Falling back to simple keyword matching heuristic. Error: {e}")

# Target classification labels
ZERO_SHOT_LABELS = [
    "violence attack kidnapped",
    "accident injury medical emergency",
    "help general assistance"
]


class SOSRequest(BaseModel):
    message: str
    latitude: float
    longitude: float
    timestamp: Optional[str] = None


def get_ai_severity(message: str) -> str:
    """
    NLP Logic for identifying Severity
    """
    message_lower = message.lower()
    
    # NLP Pipeline Path (Transformer Model)
    if classifier:
        result = classifier(message_lower, ZERO_SHOT_LABELS)
        top_label = result['labels'][0]
        
        # Based on Example Logic from prompt:
        # violence, attack, kidnapped -> HIGH
        # accident, injury -> MEDIUM
        # help, assistance -> LOW
        if top_label == "violence attack kidnapped":
            return "HIGH"
        elif top_label == "accident injury medical emergency":
            return "MEDIUM"
        else:
            return "LOW"
            
    # Fallback Path (Heuristic Pattern Matching if the transformer hangs or memory limits hit)
    if any(word in message_lower for word in ['violence', 'attack', 'kidnap', 'gun', 'kill', 'murder', 'fire', 'danger']):
        return "HIGH"
    elif any(word in message_lower for word in ['accident', 'injury', 'crash', 'bleeding', 'medical', 'hurt']):
        return "MEDIUM"
    else:
        return "LOW"


@app.get("/")
def health_check():
    return {"status": "ok", "message": "SOS AI Engine Running"}


@app.post("/sos")
async def process_sos_alert(request: SOSRequest):
    try:
        # 1/2 Receive SOS Alert & Run AI classification
        computed_severity = get_ai_severity(request.message)
        
        # Determine strict timestamp format
        created_at = request.timestamp if request.timestamp else datetime.datetime.now(datetime.timezone.utc).isoformat()
        
        # Prepare database payload matching the schema
        incident_data = {
            "message": request.message,
            "lat": request.latitude,
            "lng": request.longitude,
            "severity": computed_severity,
            "status": "active",
            "created_at": created_at
        }
        
        # 3. Store alert in Postgres (Supabase)
        if supabase:
            response = supabase.table("incidents").insert(incident_data).execute()
            stored_data = response.data[0] if response.data else incident_data
        else:
            # Bypass mode if .env is missing but AI test is running
            stored_data = incident_data
            print(f"Bypassed Supabase insert. Data: {stored_data}")
        
        # 4. Return Severity Result & confirmation
        return {
            "success": True, 
            "ai_severity": computed_severity, 
            "stored_incident": stored_data
        }
        
    except Exception as e:
        print(f"Error handling SOS AI pipeline: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
