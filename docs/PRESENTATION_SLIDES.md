# EchoAlert — Project Presentation Slides & Speaker Guide

**Module:** Mobile Applications Development (INTE 22283)  
**Project Title:** EchoAlert — Accessible Real-Time Sound Detection Application  
**Team Allocation:** Members A, B, C, D, and E  

---

## Slide 1: Title Slide
* **Title:** EchoAlert
* **Subtitle:** An Accessible, On-Device Real-Time Sound Detection System
* **Course:** INTE 22283: Mobile Applications Development
* **Presenter:** Group Project Team
* **Speaker Notes:**
  > "Good morning, everyone. Today we are excited to present EchoAlert, a mobile application engineered to bridge the accessibility gap for individuals who are deaf or hard of hearing by detecting critical everyday sounds in real time."

---

## Slide 2: Problem Statement & Motivation
* **The Problem:**
  - 430+ million people worldwide experience disabling hearing loss.
  - Individuals wearing noise-cancelling headphones or working in loud environments face similar auditory blindspots.
  - Missing critical sounds—such as a smoke alarm, crying baby, or knocking door—poses severe safety hazards and daily friction.
* **The Gap:**
  - Dedicated assistive IoT hardware is expensive, non-portable, and vendor-locked.
* **Speaker Notes:**
  > "Hearing loss or situational hearing impairment can make someone completely unaware of danger, such as a fire alarm in another room, or important everyday events like a knock at the door. Our objective was to turn any standard smartphone into a reliable, always-available assistive listening sentinel."

---

## Slide 3: The EchoAlert Solution
* **Lightweight & Ubiquitous:** Runs on standard mobile devices without external sensors.
* **100% On-Device:** Zero cloud dependencies; completely private and operates offline.
* **Multi-Modal Alerts:**
  - High-priority full-screen visual notifications.
  - Unique haptic vibration signatures per sound.
  - Audible and visual alert dialog overlay.
* **Persistent Audit Log:** Local SQLite database logs every detection event chronologically.
* **Speaker Notes:**
  > "EchoAlert continuously listens to ambient audio through an Android foreground service. When a sound of interest is classified with high confidence, the user is alerted immediately through strong, distinct vibration rhythms and high-priority visual notifications."

---

## Slide 4: Target Sound Categories
| Category | Safety Significance | YAMNet Output Classes | Vibration Pattern |
|---|---|---|---|
| 🚨 **Smoke / Fire Alarm** | Life Safety | Smoke detector, fire alarm, siren | Fast urgent pulses |
| 🔔 **Doorbell** | Social & Delivery | Doorbell, ding-dong, chime | Double long chime pulse |
| 👶 **Baby Crying** | Caretaking & Safety | Crying, sobbing, infant cry | Rapid short flutter |
| 📞 **Phone Ringing** | Communication | Telephone, ringtone, cell phone | Rhythmic cadence |
| 🚪 **Door Knocking** | Security & Visitors | Knock, tap | Triple percussive tap |
* **Speaker Notes:**
  > "We selected five core sound categories representing safety, caretaking, and home awareness. Each category is mapped to Google YAMNet classes and has a custom vibration signature so users can distinguish what happened without even glancing at the screen."

---

## Slide 5: System Architecture & Data Pipeline
```
[ Ambient Microphone ]
        │ (16kHz PCM Stream)
        ▼
[ Android Foreground Service ] (AudioRecord 15,600 samples = 0.975s)
        │
        ▼
[ TensorFlow Lite YAMNet Model ] (On-Device Inference < 60ms)
        │
        ▼
[ Threshold & Category Filters ] ◀── [ User Settings in SQLite ]
        │
   ┌────┴───────────────────────────┬───────────────────────────┐
   ▼                                ▼                           ▼
[ Distinct Vibration ]   [ High-Priority Push ]       [ SQLite Event History ]
```
* **Speaker Notes:**
  > "Our architecture is divided into clear layers. Audio is sampled at 16kHz in 0.975-second chunks, fed into our on-device TensorFlow Lite interpreter, filtered against user sensitivity preferences, and immediately dispatched to our haptic and notification systems."

---

## Slide 6: Mobile Technology Stack
* **Language & Framework:** Flutter (Dart 3.x) with Material Design 3.
* **Machine Learning:** TensorFlow Lite (`tflite_flutter`) running pre-trained YAMNet (15.35 MB).
* **Audio & Background Service:** Kotlin Android Foreground Service (`AudioRecord`, `AudioFormat.ENCODING_PCM_16BIT`).
* **Local Persistence:** SQLite (`sqflite`) for detection history and user thresholds.
* **Haptics & Notifications:** `flutter_local_notifications` with channel priority `Importance.max` and `vibration` API.
* **Speaker Notes:**
  > "We utilized Flutter for responsive cross-platform UI, combined with native Kotlin Android services for low-latency audio capture, and TFLite for on-device neural network execution."

---

## Slide 7: Five Core Screens Demonstration
1. **Home Screen:** One-tap hero listening toggle with pulsing animated feedback and daily statistics.
2. **Live Detection View:** Real-time audio waveform visualizer, active sound card, and rolling candidate feed.
3. **History Log Screen:** Chronological log with search filter, category chips, and swipe-to-delete.
4. **Settings Screen:** Individual category toggles, sensitivity threshold sliders (50%–95%), and diagnostic test buttons.
5. **Alert Overlay Dialog:** Full-screen emergency modal with instant dismiss action.
* **Speaker Notes:**
  > "The UI follows accessible design principles: high-contrast colors, large touch targets, intuitive iconography, and quick diagnostic test buttons to verify vibration and notification channels."

---

## Slide 8: Technical Challenges & Solutions
1. **Challenge:** Android 14+ background microphone restrictions.
   - *Solution:* Implemented a native Kotlin foreground service with type `FOREGROUND_SERVICE_MICROPHONE` and persistent ongoing notification.
2. **Challenge:** Minimizing false alarms from normal ambient speech.
   - *Solution:* Integrated configurable sensitivity thresholds (0.50 to 0.95) and multi-band spectral DSP filtering for web/mobile fallbacks.
3. **Challenge:** Alert flooding during continuous sounds (e.g. ongoing alarm).
   - *Solution:* Implemented a 5-second dynamic cooldown window in `DetectionBridge` to prevent repetitive alert spam.
4. **Challenge:** Non-blocking inference on UI thread.
   - *Solution:* Asynchronous buffer dispatch via Dart event streams and background service worker threads.
* **Speaker Notes:**
  > "Running continuous audio capture without draining battery or triggering Android system kills required strict adherence to modern foreground service specifications and multi-threading best practices."

---

## Slide 9: Live Demonstration Walkthrough
* **Step 1: Permission Onboarding:** Show graceful rationale dialogs for microphone and notification access.
* **Step 2: Start Monitoring:** Tap the hero button; observe the pulsing radar animation and persistent notification.
* **Step 3: Play Demonstration Audio:**
  - Play `alarm.wav` $\rightarrow$ Immediate Smoke Alarm visual alert + 3-pulse vibration.
  - Play `doorbell.wav` $\rightarrow$ Doorbell alert + dual chime vibration.
* **Step 4: History & Customization:** Open History to show timestamped records; adjust sensitivity sliders in Settings.
* **Speaker Notes:**
  > "Now let us demonstrate the live application. We will start the service, play our prepared test audio samples, and observe the sub-second detection response and database persistence."

---

## Slide 10: Conclusion & Future Scope
* **Achievements:**
  - Functional, fully integrated cross-platform Android application completed on schedule.
  - 100% offline, privacy-first on-device ML sound classification.
  - Accessible Material 3 user interface with full test coverage.
* **Future Work:**
  - Support for custom user-trained sound profiles (e.g., specific home appliance beeps).
  - Smartwatch companion app integration (Wear OS / Apple Watch haptics).
  - Directional sound localization using multi-microphone beamforming.
* **Thank You!** Questions & Answers.
* **Speaker Notes:**
  > "EchoAlert proves that accessible, safety-critical machine learning applications can run reliably on commodity mobile hardware. Thank you for your time, and we are happy to take any questions."

