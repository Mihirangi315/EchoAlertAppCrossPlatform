# EchoAlert — Team Member AI Prompts & Task Guidelines

This document provides ready-to-use developer prompts for each team member. You can copy and paste your assigned prompt directly into your AI coding assistant (or use it as your task blueprint) to build your module.

---

## 📱 Member A: UI/UX Design & Navigation

**Scope:** Home Screen, Live Detection View, History Log Screen, Settings Screen, & Navigation Routing.

```markdown
### PROMPT FOR MEMBER A (UI/UX & Navigation)

Act as a Senior Flutter Developer building the UI/UX layer for EchoAlert (a cross-platform sound detection app for hard-of-hearing users).

Your Task:
Build the clean, accessible Material 3 user interface and navigation flow with 4 main screens:

1. **Home Screen (`home_screen.dart`):**
   - Hero toggle button to Start/Stop the background listening service.
   - Status card showing "Listening Active" (Green pulsing indicator) or "Stopped" (Grey).
   - Quick stats widget showing total alerts detected today and active monitored categories.
   - Shortcut buttons to Live Detection, History Log, and Settings.

2. **Live Detection Screen (`live_detection_screen.dart`):**
   - Real-time audio waveform / level meter animation.
   - Live category card showing the currently detected sound and its confidence percentage (e.g., "Doorbell: 87%").
   - Status log showing recent classifications in real time.

3. **History Log Screen (`history_screen.dart`):**
   - Chronological list of past `DetectionEvent` items (Sound Label, Timestamp, Confidence %).
   - Search bar and category filter chips (Doorbell, Smoke Alarm, Baby Crying, Phone Ringing, Door Knocking).
   - Ability to clear history or delete individual events.

4. **Settings Screen (`settings_screen.dart`):**
   - Toggle switches for each `SoundSetting` (Doorbell, Smoke Alarm, Baby Cry, Phone Ringing, Knocking).
   - Sensitivity slider (confidence threshold 0.5 to 0.95) for each sound type.
   - Vibration test button and Notification test button.

Requirements:
- Use high-contrast, accessible Material Design 3 components.
- Implement responsive layout using `LayoutBuilder` / `MediaQuery`.
- Expose state hooks so Member B (Service), Member C (ML), and Member D (Database) can plug in data effortlessly.
```

---

## 🎙️ Member B: Audio Capture & Foreground Service

**Scope:** Continuous Microphone Audio Streaming & Foreground Background Service.

```markdown
### PROMPT FOR MEMBER B (Audio Capture & Foreground Service)

Act as a Flutter Systems Engineer building the audio capture and background service layer for EchoAlert.

Your Task:
Implement a reliable Flutter foreground service that continuously streams microphone audio even when the app is minimized or the screen is off.

Key Deliverables:
1. **Foreground Service (`audio_foreground_service.dart`):**
   - Setup `flutter_background_service` to launch an Android Foreground Service with a persistent notification ("EchoAlert is actively listening...").
   - Provide clean `startListening()` and `stopListening()` public methods.

2. **Audio Streamer (`audio_stream_provider.dart`):**
   - Capture continuous raw PCM audio (16kHz sample rate, mono channel) from the microphone using `record` or `audio_streamer`.
   - Chunk audio into 0.975-second audio buffers (15600 samples) suitable for YAMNet model classification.
   - Pass audio buffer chunks to Member C's `SoundClassifier` via a `Stream<Float32List>`.

Requirements:
- Handle service lifecycle events (start, pause, resume, terminate) safely.
- Prevent thread blocking on the main UI thread.
- Expose service state via `ChangeNotifier` / `Stream` for Member A's Home screen toggle.
```

---

## 🧠 Member C: TensorFlow Lite & YAMNet Detection Logic

**Scope:** On-device Sound Classification with TFLite & Audio Tensor Processing.

```markdown
### PROMPT FOR MEMBER C (TensorFlow Lite & YAMNet Classification)

Act as an On-Device Machine Learning Engineer building the ML classification pipeline for EchoAlert.

Your Task:
Integrate the pre-trained YAMNet TensorFlow Lite model (`yamnet.tflite`) into the Flutter app to process live audio buffers and classify target sound categories.

Key Deliverables:
1. **Model Loader & Interpreter (`yamnet_classifier.dart`):**
   - Load `assets/models/yamnet.tflite` and class labels mapping file (`yamnet_label_list.txt`) using `tflite_flutter`.
   - Target Sound Mapping:
     * Doorbell -> "Doorbell" / "Ding-dong"
     * Smoke Alarm -> "Smoke detector, smoke alarm" / "Fire alarm" / "Siren"
     * Baby Crying -> "Crying, sobbing" / "Baby cry, infant cry"
     * Phone Ringing -> "Telephone" / "Ringtone" / "Cell phone"
     * Door Knocking -> "Knock" / "Tap"

2. **Inference Pipeline (`sound_classification_engine.dart`):**
   - Receive raw PCM float audio samples (15,600 samples @ 16kHz) from Member B.
   - Run TFLite inference to compute confidence scores for all YAMNet classes.
   - Filter predictions against target categories and check if `confidence >= sensitivityThreshold`.
   - Emit a `DetectionResult` event (soundLabel, confidence, timestamp) whenever a target sound is detected.

Requirements:
- Ensure inference runs under 100ms per audio frame.
- Allow dynamic updates of target sensitivities from Member D's settings database.
```

---

## 💾 📱 Member D: Database, Alert Overlay & Notifications

**Scope:** SQLite Persistence (`DetectionEvent` & `SoundSetting`), Haptic Vibration, & High-Priority Notifications.

```markdown
### PROMPT FOR MEMBER D (Database, Alert Overlay & Notifications)

Act as a Flutter Data & Systems Developer responsible for data persistence and real-time user alerting in EchoAlert.

Your Task:
Implement the local SQLite database schema, haptic vibration controller, high-priority notification manager, and visual alert overlay.

Key Deliverables:
1. **Database Layer (`app_database.dart`):**
   - Implement `sqflite` database with two tables:
     * `DetectionEvent`: `id` (INTEGER PK AUTOINCREMENT), `soundLabel` (TEXT), `confidence` (REAL), `timestamp` (INTEGER).
     * `SoundSetting`: `soundLabel` (TEXT PK), `isEnabled` (INTEGER/BOOLEAN), `sensitivity` (REAL).
   - Create helper methods: `insertEvent()`, `getEvents()`, `clearHistory()`, `updateSetting()`, `getSettings()`.

2. **Alert & Notification Manager (`alert_manager.dart`):**
   - Setup `flutter_local_notifications` with a high-priority notification channel (bypassing DND/silent settings where permitted).
   - Trigger distinct vibration patterns per sound using `vibration` plugin (e.g., rapid pulses for Smoke Alarm, rhythmic pattern for Doorbell).
   - Display a full-screen Alert Overlay dialog over Member A's UI when a detection occurs.

Requirements:
- Ensure database read/write calls are asynchronous and non-blocking.
- Guarantee alert delivery within 1 second of receiving a `DetectionResult` from Member C.
```

---

## 🧪 📑 Member E: Testing, Integration, Documentation & Demo

**Scope:** Integration Pipeline, End-to-End Testing, Permissions, & Final Demo Documentation.

```markdown
### PROMPT FOR MEMBER E (Integration, Testing & Documentation)

Act as a QA Lead & Technical Integration Engineer for EchoAlert.

Your Task:
Integrate modules from Members A, B, C, and D, implement runtime permission management, write test suites, and prepare project documentation.

Key Deliverables:
1. **Permission Handler (`permission_manager.dart`):**
   - Request runtime permissions for Microphone (`RECORD_AUDIO`) and Notifications (`POST_NOTIFICATIONS`) gracefully using `permission_handler`.
   - Provide clear UI dialogs explaining permission rationale if denied.

2. **Integration & E2E Testing (`test/`):**
   - Unit tests for database queries and settings updates.
   - Mock audio stream test to verify model classification triggers alerts correctly.
   - UI Widget tests for Home, History, and Settings screens.

3. **Documentation & Demo Preparation:**
   - Maintain repository project structure and code comments.
   - Prepare test audio samples (Doorbell WAV, Alarm WAV, Baby Cry WAV) for live demonstration.
   - Create final report and project architecture slides.
```
