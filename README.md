# EchoAlert - Cross-Platform Real-Time Sound Detection App

**EchoAlert** is a Flutter cross-platform mobile application designed for deaf and hard-of-hearing individuals, as well as users in noisy environments or wearing headphones. EchoAlert continuously listens to ambient audio in real time using an on-device machine learning model (YAMNet via TFLite) to identify critical sounds and alert users through vibration, visual overlays, and high-priority notifications.

Developed for **INTE 22283: Mobile Applications Development**.

---

## 📌 1. Problem Statement & Solution

- **Problem:** Everyday sounds (doorbells, smoke alarms, baby crying, phone ringing, door knocking) carry safety and social importance, but are missed by individuals with hearing impairments or those using noise-canceling headphones.
- **Solution:** EchoAlert continuously processes microphone audio via a background/foreground service using an on-device audio classification model. When target sounds exceed confidence thresholds, immediate visual and haptic alerts are triggered, and events are saved to local history.

---

## 🎯 2. Target Sound Categories

1. 🔔 **Doorbell**
2. 🚨 **Smoke / Fire Alarm**
3. 👶 **Baby Crying**
4. 📞 **Phone Ringing**
5. 🚪 **Door Knocking**

---

## 🏗️ 3. System Architecture & Tech Stack

- **Programming Language / Framework:** Flutter (Dart) — Cross-Platform
- **Sound Classification:** TensorFlow Lite (`tflite_flutter`) — Pre-trained YAMNet Model
- **Audio Capture & Background Service:** `flutter_background_service`, `record` / `audio_streamer`
- **Local Database:** SQLite (`sqflite`) / Hive matching Room DB Entity Specs
- **Alerts & Haptics:** `flutter_local_notifications` (High-priority channel) & `vibration`
- **UI Framework:** Flutter Material Design 3 Components

---

## 💾 4. Database Design

The local database contains two primary tables:

### 4.1 `DetectionEvent` Table
| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `Integer` (PK, autoincrement) | Unique identifier for the detection event. |
| `soundLabel` | `String` | Name of the detected sound (e.g., "Doorbell"). |
| `confidence` | `Float` | Model confidence score for the detection (0.0 to 1.0). |
| `timestamp` | `Integer / Long` | Unix timestamp of the detection event. |

### 4.2 `SoundSetting` Table
| Field | Type | Description |
| :--- | :--- | :--- |
| `soundLabel` | `String` (PK) | Name of the sound category (e.g., "Smoke Alarm"). |
| `isEnabled` | `Boolean` | Whether this sound category is actively monitored. |
| `sensitivity` | `Float` | Confidence threshold required to trigger an alert. |

---

## 👥 5. Group Task Allocation

| Team Member | Module Focus & Responsibility |
| :--- | :--- |
| **Member A** | **UI/UX Design & Navigation:** Home, Live Detection, Settings, & History screens. |
| **Member B** | **Audio Capture & Foreground Service:** Microphone PCM stream & background listener service. |
| **Member C** | **TensorFlow Lite & Detection Logic:** YAMNet model integration, audio tensor processing & scoring. |
| **Member D** | **Database, Alert Overlay & Notifications:** SQLite persistence, vibration haptics & high-priority alerts. |
| **Member E** | **Testing, Documentation & Integration:** E2E testing, pipeline integration, demo prep & user guides. |

*(Detailed AI Developer Prompts for each team member are available in [TEAM_TASK_PROMPTS.md](file:///c:/Users/User/AndroidStudioProjects/EchoAlertAppCrossPlatform/TEAM_TASK_PROMPTS.md))*

---

## 🛠️ Getting Started

### Prerequisites

- Flutter SDK (v3.x+)
- Android Studio / VS Code
- Android / iOS Device or Simulator

### Installation

```bash
# Clone the repository
git clone https://github.com/Mihirangi315/EchoAlertAppCrossPlatform.git

# Navigate to project root
cd EchoAlertAppCrossPlatform

# Get Flutter dependencies
flutter pub get

# Run application
flutter run
```
