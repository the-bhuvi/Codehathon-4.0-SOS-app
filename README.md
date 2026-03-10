# 🚨 SafeAlert - AI-Powered SOS Emergency Response System

<p align="center">
  <img src="public/sos.png" alt="SafeAlert Logo" width="120"/>
</p>

<p align="center">
  <strong>An intelligent emergency response platform with real-time alerts, AI-powered severity classification, and multi-language support.</strong>
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#mobile-app">Mobile App</a> •
  <a href="#web-dashboard">Web Dashboard</a> •
  <a href="#api">API</a>
</p>

---

## 🌟 Features

### 📱 Mobile App (Flutter)
- **One-Touch SOS** - Single button emergency alert with location
- **Shake Detection** - Shake phone to trigger panic alert (works in background)
- **Auto Video Recording** - Front camera records 10 seconds automatically on shake
- **Voice Recording** - Record voice messages for emergency context
- **Multi-Language Support** - Supports English, Hindi, Tamil, Telugu, and more Indian languages
- **Offline Queue** - Alerts are queued when offline and sent when connectivity returns
- **Auto SMS** - Sends emergency SMS to contacts automatically
- **Emergency Contacts** - Store and manage multiple emergency contacts
- **User Profile** - Store medical info, blood group, emergency contact details
- **Real-time Map** - View your location on interactive map

### 🖥️ Web Dashboard (React + Vite)
- **Real-time Incident Map** - Live map with all emergency incidents
- **Heat Map Visualization** - Risk zone identification based on incident density
- **Incident Management** - View, filter, and resolve incidents
- **Live Updates** - Real-time updates via Supabase subscriptions
- **Dark/Light Theme** - Toggle between themes

### 🤖 AI Backend (FastAPI + Python)
- **NLP Severity Classification** - Zero-shot classification using DistilBERT
- **Multi-Language Processing** - Auto-detect and translate 9+ Indian languages
- **Voice-to-Text** - Convert audio recordings to text
- **Agency Routing** - Auto-route alerts to Police, Ambulance, or Fire Department
- **Risk Zone Analysis** - Aggregate incidents into risk zones

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        SafeAlert System                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐       │
│  │  Flutter App │    │ React Web    │    │  External    │       │
│  │  (Android)   │    │  Dashboard   │    │  IoT/APIs    │       │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘       │
│         │                   │                   │                │
│         └───────────────────┼───────────────────┘                │
│                             │                                    │
│                             ▼                                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              AI Backend (FastAPI + Python)                │   │
│  │  • NLP Severity Classification (DistilBERT)               │   │
│  │  • Multi-language Translation                             │   │
│  │  • Voice-to-Text Processing                               │   │
│  │  • Agency Routing Logic                                   │   │
│  └──────────────────────────┬───────────────────────────────┘   │
│                             │                                    │
│                             ▼                                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                    Supabase                               │   │
│  │  • PostgreSQL Database (incidents, profiles)              │   │
│  │  • Real-time Subscriptions                                │   │
│  │  • Storage (audio, video, photos)                         │   │
│  │  • Row Level Security                                     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites
- **Node.js** 18+ (for web dashboard and backend server)
- **Python** 3.9+ (for AI backend)
- **Flutter** 3.24+ (for mobile app)
- **Android Studio** with Android SDK 34+ (for mobile builds)
- **Supabase** account (free tier works)

### 1️⃣ Clone Repository
```bash
git clone https://github.com/yourusername/Codehathon-4.0-SOS-app.git
cd Codehathon-4.0-SOS-app
```

### 2️⃣ Setup Supabase Database

1. Create a new project at [supabase.com](https://supabase.com)
2. Go to **SQL Editor** and run the contents of `supabase_setup.sql`
3. Enable **Realtime** for the `incidents` table:
   - Go to Database → Replication → Toggle `incidents` ON
4. Copy your project URL and keys from **Settings → API**

### 3️⃣ Configure Environment Variables

**Web Dashboard** (`.env` in root):
```env
VITE_SUPABASE_URL=https://your-project-ref.supabase.co
VITE_SUPABASE_ANON_KEY=your_supabase_anon_key
```

**AI Backend** (`ai_backend/.env`):
```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

**Node.js Server** (`server/.env`):
```env
SUPABASE_URL=https://your-project-ref.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
PORT=5000
```

---

## 📱 Mobile App

### Setup
```bash
cd safe_alert
flutter pub get
```

### Configure Supabase
Edit `lib/main.dart` and update the Supabase credentials:
```dart
const supabaseUrl = 'https://your-project-ref.supabase.co';
const supabaseAnonKey = 'your_supabase_anon_key';
```

### Build APK
```bash
# Debug build
flutter build apk --debug

# Release build
flutter build apk --release
```

APK will be at: `build/app/outputs/flutter-apk/app-debug.apk`

### Install on Device
```bash
# Via ADB
adb install build/app/outputs/flutter-apk/app-debug.apk

# Or run directly
flutter run
```

### App Features

| Feature | Description |
|---------|-------------|
| **SOS Button** | Large red button on home screen - press to send emergency alert |
| **Shake Detection** | Enable in Settings → Shake to trigger panic alert even from background |
| **Voice Recording** | Hold to record voice message, released to attach to alert |
| **Emergency Types** | Select: General, Fire, Accident, Medical, Following Me, Robbery |
| **Emergency Contacts** | Add multiple contacts in Settings |
| **Auto SMS** | Enable to send SMS to all contacts on SOS |
| **Profile** | Set your name, phone, blood group, medical conditions |

### Permissions Required
- **Location** - For GPS coordinates in alerts
- **Camera** - For automatic video recording on shake
- **Microphone** - For voice recording
- **SMS** - For sending emergency SMS
- **Notifications** - For background service notification

---

## 🖥️ Web Dashboard

### Setup & Run
```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

Open [http://localhost:5173](http://localhost:5173)

### Build for Production
```bash
npm run build
npm run preview
```

### Dashboard Features

| Component | Description |
|-----------|-------------|
| **Map View** | Interactive Leaflet map showing all incidents |
| **Heat Map** | Risk zone visualization based on incident clustering |
| **Incident List** | Sortable, filterable list of all emergencies |
| **Real-time Updates** | Live subscription to new incidents via Supabase |
| **Status Management** | Mark incidents as resolved |
| **Severity Filters** | Filter by HIGH, MEDIUM, LOW severity |

---

## 🤖 AI Backend

### Setup
```bash
cd ai_backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # Linux/Mac
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt
```

### Run Server
```bash
# Development
python main.py

# Production
uvicorn main:app --host 0.0.0.0 --port 8000
```

API available at [http://localhost:8000](http://localhost:8000)

### API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Health check |
| `/sos` | POST | Process SOS alert with AI classification |
| `/voice-to-text` | POST | Convert audio to text |
| `/upload-media` | POST | Upload audio/video to storage |
| `/risk-zones` | GET | Get aggregated risk zone data |

### SOS Request Example
```bash
curl -X POST http://localhost:8000/sos \
  -H "Content-Type: application/json" \
  -d '{
    "message": "Help! There is a fire in my building",
    "latitude": 12.9716,
    "longitude": 77.5946,
    "emergency_type": "fire",
    "user_name": "John Doe",
    "user_phone": "+91-9876543210"
  }'
```

### AI Features

**Severity Classification:**
- Uses `typeform/distilbert-base-uncased-mnli` for zero-shot classification
- Categories: HIGH (violence, fire, weapons), MEDIUM (accidents, injuries), LOW (general help)

**Language Support:**
- Auto-detects: English, Hindi, Tamil, Telugu, Kannada, Malayalam, Marathi, Bengali, Gujarati
- Translates to English for NLP processing

**Agency Routing:**
| Emergency Type | Routed To |
|---------------|-----------|
| Fire | Fire Department |
| Accident, Medical | Ambulance |
| Robbery, Following, Unsafe | Police |

---

## 🗄️ Database Schema

### incidents
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| lat | DOUBLE | Latitude |
| lng | DOUBLE | Longitude |
| severity | VARCHAR | HIGH, MEDIUM, LOW |
| severity_score | DOUBLE | AI confidence score |
| message | TEXT | Alert message (English) |
| original_message | TEXT | Original message |
| detected_language | VARCHAR | Language code |
| emergency_type | VARCHAR | Type of emergency |
| agency | VARCHAR | Routed agency |
| audio_url | TEXT | Voice recording URL |
| video_url | TEXT | Video/photo URL |
| user_name | TEXT | User's name |
| user_phone | TEXT | User's phone |
| emergency_contact_name | TEXT | Emergency contact name |
| emergency_contact_phone | TEXT | Emergency contact phone |
| blood_group | VARCHAR | User's blood group |
| medical_conditions | TEXT | Medical conditions |
| status | VARCHAR | active, resolved |
| created_at | TIMESTAMP | Creation time |

### user_profiles
| Column | Type | Description |
|--------|------|-------------|
| id | UUID | Primary key |
| device_id | TEXT | Unique device identifier |
| full_name | TEXT | User's full name |
| phone | TEXT | Phone number |
| emergency_contact_name | TEXT | Contact name |
| emergency_contact_phone | TEXT | Contact phone |
| blood_group | VARCHAR | Blood group |
| medical_conditions | TEXT | Medical info |

---

## 📁 Project Structure

```
Codehathon-4.0-SOS-app/
├── 📁 safe_alert/              # Flutter Mobile App
│   ├── lib/
│   │   ├── main.dart           # App entry point
│   │   ├── models/             # Data models
│   │   ├── providers/          # Riverpod state management
│   │   ├── screens/            # UI screens
│   │   ├── services/           # API, location, storage services
│   │   ├── theme/              # App theming
│   │   └── widgets/            # Reusable widgets
│   ├── android/                # Android native code
│   └── pubspec.yaml            # Flutter dependencies
│
├── 📁 src/                     # React Web Dashboard
│   ├── components/
│   │   ├── Dashboard.jsx       # Main dashboard
│   │   ├── Map.jsx             # Leaflet map component
│   │   ├── IncidentList.jsx    # Incident list
│   │   └── RightPanel.jsx      # Details panel
│   ├── lib/
│   │   └── supabase.js         # Supabase client
│   └── App.jsx                 # Main app component
│
├── 📁 ai_backend/              # Python AI Backend
│   ├── main.py                 # FastAPI server
│   ├── requirements.txt        # Python dependencies
│   └── .env.example            # Environment template
│
├── 📁 server/                  # Node.js Backend (optional)
│   ├── index.js                # Express server
│   └── package.json            # Node dependencies
│
├── 📁 migrations/              # Database migrations
├── supabase_setup.sql          # Database setup script
├── package.json                # Web app dependencies
├── vite.config.js              # Vite configuration
└── README.md                   # This file
```

---

## 🔧 Configuration

### Flutter App Build Settings

| Setting | File | Value |
|---------|------|-------|
| Min SDK | `android/app/build.gradle.kts` | 21 |
| Target SDK | `android/app/build.gradle.kts` | 34 |
| Compile SDK | `android/app/build.gradle.kts` | 36 |
| Gradle | `android/gradle/wrapper/gradle-wrapper.properties` | 8.7 |
| AGP | `android/settings.gradle.kts` | 8.6.0 |
| Kotlin | `android/settings.gradle.kts` | 2.1.0 |

---

## 🛡️ Security Considerations

- **Never commit `.env` files** - Contains sensitive API keys
- **Use Service Role Key only in backends** - Never expose in client apps
- **RLS Policies** - Supabase has Row Level Security enabled
- **HTTPS** - Always use HTTPS in production
- **Input Validation** - All inputs are validated before processing

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Supabase** - Backend as a Service
- **Flutter** - Cross-platform mobile framework
- **Hugging Face** - NLP models
- **Leaflet** - Interactive maps
- **FastAPI** - Modern Python web framework

---

<p align="center">
  Made with ❤️ for Codehathon 4.0
</p>
