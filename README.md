# EchoAlert - Cross-Platform Real-Time Sound Detection App

**EchoAlert** is a Flutter cross-platform mobile application designed for deaf and hard-of-hearing individuals, as well as users in noisy environments or wearing headphones. EchoAlert continuously listens to ambient audio in real time using an on-device machine learning model (YAMNet via TFLite) to identify critical sounds and alert users through vibration, visual overlays, and high-priority notifications.

Developed for **INTE 22283: Mobile Applications Development**.

---

## 📌 Problem Statement & Solution

- **Problem:** Everyday sounds (doorbells, smoke alarms, baby crying, phone ringing, door knocking) carry safety and social importance, but are missed by individuals with hearing impairments or those using noise-canceling headphones.
- **Solution:** EchoAlert continuously processes microphone audio via a background/foreground service using an on-device audio classification model. When target sounds exceed confidence thresholds, immediate visual and haptic alerts are triggered, and events are saved to local history.

---

## 🚀 Key Features

| Screen / Feature | Description |
| :--- | :--- |
| **Home Screen** | Quick toggle for starting/stopping listening service, system status, and recent activity preview. |
| **Live Detection** | Real-time waveform / audio meter, current sound classification confidence level, and live indicator. |
| **History Log** | Chronological log of detected sounds with timestamps, audio category tags, filter, and search. |
| **Settings** | Configure monitored sound categories (doorbell, alarm, baby cry, ring, knock), sensitivity thresholds, alert preferences. |
| **Alert Overlay & Haptics** | High-priority pop-up overlay and distinct vibration pattern per sound category. |

---

## 🎯 Target Sound Categories

1. 🔔 **Doorbell**
2. 🚨 **Smoke / Fire Alarm**
3. 👶 **Baby Crying**
4. 📞 **Phone Ringing**
5. 🚪 **Door Knocking**

---

## 🏗️ System Architecture & Tech Stack

- **Framework:** Flutter (Dart) - Cross-Platform (Android & iOS)
- **State Management:** Provider / Riverpod / BLoC (MVVM Pattern)
- **ML / Audio Engine:** TensorFlow Lite (`tflite_flutter`) with YAMNet pre-trained audio classification model
- **Audio Capture:** `record` / `flutter_sound` / `audio_streamer`
- **Background Engine:** `flutter_background_service` (Foreground service with notification banner)
- **Local Storage:** `sqflite` / `hive` / `isar` for persistent event history & user settings
- **Alerts & Haptics:** `flutter_local_notifications` & `vibration`

---

## 👥 5-Member Team Workload Breakdown

| Team Member | Module Focus & Responsibilities |
| :--- | :--- |
| **Member 1 (Lead / Audio & Service)** | Foreground service setup, real-time microphone audio stream capturing (`flutter_background_service`, `record`). |
| **Member 2 (ML / Sound Classification)** | TensorFlow Lite Integration, YAMNet model loading, audio processing/tensor conversion, confidence thresholding. |
| **Member 3 (UI / Presentation Layer)** | Core 5 UI screens (Home, Live Detection, History Log, Settings, Alert Overlay), theme & accessibility. |
| **Member 4 (Data & Persistence)** | Local database setup (`sqflite`), storage repository for detection logs, settings persistence (`shared_preferences`). |
| **Member 5 (Alerts, Permissions & Testing)** | Notification manager (`flutter_local_notifications`), vibration patterns, runtime permission handling, integration testing. |

---

## 🛠️ Getting Started

### Prerequisites

- Flutter SDK (v3.x+)
- Android Studio / VS Code
- Android Device (API Level 24+) or iOS Device/Simulator

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
