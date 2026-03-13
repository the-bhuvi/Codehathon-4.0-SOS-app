# SafeAlert - AI-Powered SOS Emergency App

A Flutter mobile application for emergency SOS response with AI-powered severity classification.

## Features

- **🔴 SOS Panic Button** — Long-press to trigger emergency alert with pulsing animation
- **📍 Auto GPS Location** — Captures and sends your precise coordinates
- **🤖 AI Severity Classification** — Backend AI classifies emergencies as HIGH/MEDIUM/LOW
- **📡 Offline Support** — Queues SOS when offline, auto-sends on reconnection
- **📋 Incident History** — View all past SOS incidents with real-time updates from Supabase
- **👥 Emergency Contacts** — Store contacts locally for quick access
- **🌙 Dark Theme** — Modern dark UI with red/orange accent colors

## Architecture

```
safe_alert/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── models/
│   │   ├── incident.dart                  # Incident data model
│   │   ├── sos_models.dart                # SOS request/response models
│   │   └── emergency_contact.dart         # Emergency contact model
│   ├── services/
│   │   ├── api_service.dart               # FastAPI backend calls
│   │   ├── supabase_service.dart          # Supabase DB queries
│   │   ├── location_service.dart          # GPS location service
│   │   ├── storage_service.dart           # SharedPreferences storage
│   │   └── offline_queue_service.dart     # Offline SOS queue
│   ├── providers/
│   │   └── app_providers.dart             # Riverpod state management
│   ├── screens/
│   │   ├── home/home_screen.dart          # Main SOS screen
│   │   ├── confirmation/confirmation_screen.dart  # SOS active screen
│   │   ├── history/history_screen.dart    # Incident history
│   │   └── settings/settings_screen.dart  # App settings
│   ├── widgets/
│   │   ├── sos_button.dart                # Animated SOS button
│   │   ├── status_badge.dart              # Safe/Active status badge
│   │   └── severity_chip.dart             # HIGH/MEDIUM/LOW chip
│   └── theme/
│       └── app_theme.dart                 # Dark theme configuration
├── android/app/src/main/
│   └── AndroidManifest.xml                # Android permissions
└── pubspec.yaml                           # Dependencies
```

## Prerequisites

- **Flutter SDK** >= 3.2.0
- **Dart** >= 3.2.0
- **Android Studio** or **VS Code** with Flutter extension
- **FastAPI Backend** running (for SOS endpoint)
- **OpenStreetMap** — Free map tiles, no API key needed

## Setup

### 1. Clone & Navigate
```bash
cd safe_alert
```

### 2. Install Dependencies
```bash
flutter pub get
```

### 3. Configure Backend URL
Open **Settings** in the app and set your FastAPI server URL, or edit the default in `lib/services/api_service.dart`:
```dart
static const String _defaultBaseUrl = 'http://10.0.2.2:8000'; // Android emulator
// For physical device, use your machine's LAN IP: http://192.168.x.x:8000
```

### 4. Run the App
```bash
flutter run
```

## Backend Services

### FastAPI AI Backend
The app sends SOS alerts to:
```
POST http://<server-ip>:8000/sos
```
Request body:
```json
{
  "message": "Help! I'm in danger",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "timestamp": "2026-03-10T15:00:00Z"
}
```

### Supabase
Real-time incident tracking via Supabase:
- **URL**: `https://zzatwehdudhztqyblrpa.supabase.co`
- **Table**: `incidents` (id, lat, lng, severity, message, status, created_at)

## App Screens

| Screen | Description |
|--------|-------------|
| **Home** | Large pulsing SOS button, status badge, GPS coordinates, emergency contacts |
| **Confirmation** | AI severity level, elapsed timer, location pin, cancel SOS button |
| **History** | Real-time list of all past incidents with status and severity |
| **Settings** | Profile name, server URL, language, live location toggle, emergency contacts |

## Key Behaviors

- **Long-press** the SOS button to activate (prevents accidental triggers)
- **Offline resilience** — SOS is queued locally and sent when internet returns
- **Auto-location fallback** — Uses last known position if GPS is slow
- **Real-time updates** — History screen streams live from Supabase

## Permissions Required

| Permission | Purpose |
|------------|---------|
| `ACCESS_FINE_LOCATION` | GPS coordinates for SOS |
| `ACCESS_COARSE_LOCATION` | Fallback location |
| `INTERNET` | API calls to FastAPI & Supabase |
| `RECORD_AUDIO` | Voice distress messages (optional) |

## License

Built for Codehathon 4.0
