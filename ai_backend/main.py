from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client, Client
import os
from dotenv import load_dotenv
from typing import Optional
import datetime
import re
from transformers import pipeline

# Load environment variables
load_dotenv()

app = FastAPI(title="SOS AI Backend", version="2.0.0")

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
    print("WARNING: Missing Supabase credentials in .env. Database operations will fail.")
    supabase = None
else:
    supabase: Client = create_client(supabase_url, supabase_key)

# 2. Initialize NLP Model (Zero-Shot Classification)
print("Loading AI Model...")
try:
    classifier = pipeline("zero-shot-classification", model="typeform/distilbert-base-uncased-mnli")
    print("AI Model Loaded Successfully!")
except Exception as e:
    classifier = None
    print(f"Warning: Failed to load transformer. Falling back to keyword matching. Error: {e}")

# 3. Initialize language detection and translation
try:
    from langdetect import detect as detect_language_raw
    print("Language detection loaded.")
except ImportError:
    detect_language_raw = None
    print("Warning: langdetect not installed. pip install langdetect")

try:
    from deep_translator import GoogleTranslator
    print("Translation engine loaded.")
except ImportError:
    GoogleTranslator = None
    print("Warning: deep-translator not installed. pip install deep-translator")

# 4. Initialize speech-to-text
try:
    import speech_recognition as sr
    recognizer = sr.Recognizer()
    print("Speech recognition loaded.")
except ImportError:
    recognizer = None
    print("Warning: SpeechRecognition not installed. pip install SpeechRecognition")

# Target classification labels for severity
ZERO_SHOT_LABELS = [
    "violence attack kidnapped weapon bleeding fire bomb shooting stabbing",
    "accident injury robbery crash medical emergency fracture",
    "feeling unsafe lost help assistance noise suspicious"
]

# Language code mapping for Indian languages
LANGUAGE_MAP = {
    'en': 'English', 'hi': 'Hindi', 'ta': 'Tamil',
    'te': 'Telugu', 'kn': 'Kannada', 'ml': 'Malayalam',
    'mr': 'Marathi', 'bn': 'Bengali', 'gu': 'Gujarati',
}

# Emergency type to agency routing
AGENCY_ROUTING = {
    'fire': 'fire_dept',
    'accident': 'ambulance',
    'medical': 'ambulance',
    'robbery': 'police',
    'following': 'police',
    'unsafe': 'police',
    'general': 'police',
}


class SOSRequest(BaseModel):
    message: str
    latitude: float
    longitude: float
    timestamp: Optional[str] = None
    emergency_type: Optional[str] = "general"
    user_name: Optional[str] = ""
    user_phone: Optional[str] = ""
    emergency_contact_name: Optional[str] = ""
    emergency_contact_phone: Optional[str] = ""
    blood_group: Optional[str] = ""
    medical_conditions: Optional[str] = ""


def normalize_text(text: str) -> str:
    """Clean and normalize input text."""
    text = text.strip()
    text = re.sub(r'\s+', ' ', text)
    return text


def detect_language(text: str) -> str:
    """Detect the language of the input text."""
    if not detect_language_raw:
        return "en"
    try:
        lang = detect_language_raw(text)
        return lang if lang in LANGUAGE_MAP else "en"
    except Exception:
        return "en"


def translate_to_english(text: str, source_lang: str) -> str:
    """Translate text to English if not already English."""
    if source_lang == "en" or not GoogleTranslator:
        return text
    try:
        translated = GoogleTranslator(source=source_lang, target='en').translate(text)
        return translated or text
    except Exception:
        return text


def get_ai_severity(message: str) -> tuple:
    """
    NLP pipeline: returns (severity_label, confidence_score)
    """
    message_lower = message.lower()

    # NLP Pipeline Path (Transformer Model)
    if classifier:
        result = classifier(message_lower, ZERO_SHOT_LABELS)
        top_label = result['labels'][0]
        top_score = result['scores'][0]

        if top_label == ZERO_SHOT_LABELS[0]:
            return ("HIGH", round(top_score, 3))
        elif top_label == ZERO_SHOT_LABELS[1]:
            return ("MEDIUM", round(top_score, 3))
        else:
            return ("LOW", round(top_score, 3))

    # Fallback: keyword matching heuristic
    high_keywords = ['violence', 'attack', 'kidnap', 'gun', 'kill', 'murder',
                     'fire', 'danger', 'weapon', 'stab', 'shoot', 'bomb',
                     'bleeding', 'threat', 'hostage', 'rape', 'assault']
    medium_keywords = ['accident', 'injury', 'crash', 'medical', 'hurt',
                       'robbery', 'theft', 'fracture', 'unconscious', 'ambulance']

    if any(word in message_lower for word in high_keywords):
        return ("HIGH", 0.85)
    elif any(word in message_lower for word in medium_keywords):
        return ("MEDIUM", 0.7)
    else:
        return ("LOW", 0.5)


def determine_agency(emergency_type: str, severity: str) -> str:
    """Route alert to appropriate agency based on type."""
    if emergency_type in AGENCY_ROUTING:
        return AGENCY_ROUTING[emergency_type]
    if severity == "HIGH":
        return "police"
    return "police"


@app.get("/")
def health_check():
    return {"status": "ok", "message": "SOS AI Engine v2.0 Running",
            "features": ["nlp_classification", "multi_language", "voice_to_text", "agency_routing"]}


@app.post("/sos")
async def process_sos_alert(request: SOSRequest):
    try:
        # 1. Normalize text
        raw_message = normalize_text(request.message)

        # 2. Detect language
        detected_lang = detect_language(raw_message)

        # 3. Translate to English if needed
        english_message = translate_to_english(raw_message, detected_lang)

        # 4. Run NLP severity classification on English text
        computed_severity, severity_score = get_ai_severity(english_message)

        # 5. Determine agency routing
        emergency_type = request.emergency_type or "general"
        agency = determine_agency(emergency_type, computed_severity)

        # 6. Prepare database payload - let database generate timestamp for accuracy
        # Don't trust client timestamp - use server time
        created_at = datetime.datetime.now(datetime.timezone.utc).isoformat()

        incident_data = {
            "message": english_message,
            "original_message": raw_message,
            "translated_message": english_message if detected_lang != "en" else "",
            "detected_language": detected_lang,
            "lat": request.latitude,
            "lng": request.longitude,
            "severity": computed_severity,
            "severity_score": severity_score,
            "emergency_type": emergency_type,
            "agency": agency,
            "status": "active",
            "created_at": created_at,
            "user_name": request.user_name or "",
            "user_phone": request.user_phone or "",
            "emergency_contact_name": request.emergency_contact_name or "",
            "emergency_contact_phone": request.emergency_contact_phone or "",
            "blood_group": request.blood_group or "",
            "medical_conditions": request.medical_conditions or "",
        }

        # 7. Store in Supabase
        stored_data = incident_data
        if supabase:
            response = supabase.table("incidents").insert(incident_data).execute()
            stored_data = response.data[0] if response.data else incident_data

        return {
            "success": True,
            "ai_severity": computed_severity,
            "severity_score": severity_score,
            "detected_language": detected_lang,
            "translated_message": english_message,
            "agency": agency,
            "stored_incident": stored_data
        }

    except Exception as e:
        print(f"Error in SOS pipeline: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/voice-to-text")
async def voice_to_text(audio: UploadFile = File(...)):
    """Convert uploaded audio to text using speech recognition."""
    if not recognizer:
        raise HTTPException(status_code=503, detail="Speech recognition not available")

    try:
        import tempfile, os as _os
        suffix = ".wav"
        if audio.filename and audio.filename.endswith(".m4a"):
            suffix = ".m4a"

        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            content = await audio.read()
            tmp.write(content)
            tmp_path = tmp.name

        with sr.AudioFile(tmp_path) as source:
            audio_data = recognizer.record(source)
            text = recognizer.recognize_google(audio_data)

        _os.unlink(tmp_path)

        detected_lang = detect_language(text) if detect_language_raw else "en"
        english_text = translate_to_english(text, detected_lang)

        return {
            "success": True,
            "transcript": text,
            "english_transcript": english_text,
            "detected_language": detected_lang
        }

    except Exception as e:
        print(f"Voice-to-text error: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Speech recognition failed: {str(e)}")


@app.post("/upload-media")
async def upload_media(
    file: UploadFile = File(...),
    incident_id: str = Form(None),
    media_type: str = Form("audio"),
):
    """Upload audio/video media to Supabase storage and optionally link to incident."""
    if not supabase:
        raise HTTPException(status_code=503, detail="Supabase not configured")

    try:
        content = await file.read()
        ext = file.filename.split(".")[-1] if file.filename else "bin"
        path = f"{media_type}/{datetime.datetime.now().strftime('%Y%m%d_%H%M%S')}_{incident_id or 'unknown'}.{ext}"

        supabase.storage.from_("sos-media").upload(path, content,
            file_options={"content-type": file.content_type or "application/octet-stream"})

        public_url = supabase.storage.from_("sos-media").get_public_url(path)

        # Update incident with media URL if incident_id provided
        if incident_id:
            col = "audio_url" if media_type == "audio" else "video_url"
            supabase.table("incidents").update({col: public_url}).eq("id", incident_id).execute()

        return {"success": True, "url": public_url, "media_type": media_type}

    except Exception as e:
        print(f"Media upload error: {str(e)}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/risk-zones")
async def get_risk_zones():
    """Get risk zone data for heatmap visualization."""
    if not supabase:
        return {"zones": []}

    try:
        response = supabase.table("incidents").select("lat, lng, severity").execute()
        incidents = response.data or []

        # Aggregate into grid cells (~111m precision at 3 decimal places)
        zones = {}
        for inc in incidents:
            key = (round(inc['lat'], 3), round(inc['lng'], 3))
            if key not in zones:
                zones[key] = {"lat": key[0], "lng": key[1], "count": 0, "high": 0}
            zones[key]["count"] += 1
            if inc.get("severity") == "HIGH":
                zones[key]["high"] += 1

        # Only return zones with 2+ incidents
        risk_zones = [z for z in zones.values() if z["count"] >= 2]
        return {"zones": risk_zones}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
