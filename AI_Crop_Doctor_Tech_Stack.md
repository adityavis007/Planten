# Tech Stack Document

## AI Crop Doctor

**Purpose:** Exact technologies, frameworks, libraries, and services to implement the app — for a coding agent (e.g., Antigravity) or developer to follow directly.
**Companion docs:** PRD · UI Theme & Design Brief

---

## 1. Stack Overview

| Layer | Choice |
|---|---|
| Frontend framework | Flutter (Dart) |
| State management | Provider (upgrade path to Riverpod post-V1) |
| Backend/Cloud | Firebase — Spark (free) plan |
| AI inference | On-device, via LiteRT (formerly TensorFlow Lite) |
| AI training | Google Colab / Kaggle Notebooks (free GPU) |
| Database | Cloud Firestore |
| Auth | Firebase Authentication |
| Voice (V2+) | On-device OS speech APIs |
| Version control | Git + GitHub |

## 2. Frontend

- **Framework:** Flutter, latest stable channel (3.47.x as of Sept 2026 — build against whatever is current stable, don't pin an old version)
- **Language:** Dart, null-safe
- **State management:** `provider` for V1 simplicity; move to `flutter_riverpod` if complexity grows from V2 onward
- **Navigation:** `go_router` — declarative routing, easier deep-linking later
- **Key packages:**
  - `camera` — in-app photo capture
  - `image_picker` — gallery upload fallback
  - `flutter_litert` — on-device model inference (LiteRT, formerly TensorFlow Lite; auto-bundles native libraries, no manual `.so`/`.dylib` setup — this is the current actively-maintained successor to `tflite_flutter`)
  - `firebase_core`, `firebase_auth`, `cloud_firestore` — Firebase SDKs
  - `firebase_storage` — only if photo backup is enabled (opt-in, per PRD privacy notes)
  - `connectivity_plus` — detect offline state, gate sync accordingly
  - `flutter_localizations` + `intl` — Hindi/English localization
  - `shared_preferences` — lightweight local settings (language choice, onboarding flag)
  - `speech_to_text`, `flutter_tts` — V2 voice features, not needed for V1

## 3. Backend / Cloud (Firebase — Spark/free plan)

- **Authentication:** Firebase Auth — email or phone-number sign-in
- **Database:** Cloud Firestore — farmer profile, crop list, scan results/history (metadata only, not raw photos, by default)
- **Storage:** Firebase Storage — only used if a farmer opts in to photo backup
- **No custom backend server for V1** — the app talks directly to Firebase; AI inference runs on-device, so there is no inference API to host or scale

## 4. AI / ML Pipeline

| Stage | Tool/Choice |
|---|---|
| Dataset | PlantVillage (~54K images, 14 crops/26 diseases) + PlantDoc (real-world field images) |
| Training approach | Transfer learning, not training from scratch |
| Base model | MobileNetV2 or EfficientNet-Lite0 (mobile-optimized) |
| Training framework | TensorFlow/Keras |
| Training compute | Kaggle Notebooks or Google Colab (free-tier GPU) |
| Export format | `.tflite` model file |
| On-device runtime | LiteRT (formerly TensorFlow Lite — same `.tflite` format, new runtime name) |
| Flutter plugin | `flutter_litert` |
| Model size target | 5–10MB after quantization |

## 5. Treatment Knowledge Base

- Static content, not LLM-generated per request
- Bundled JSON for V1; movable to a Firestore collection later if it needs remote updates without an app release
- Sourced and verified from ICAR / state agriculture department / Krishi Vigyan Kendra material
- Entry structure: `disease_id`, `crop`, `symptoms`, `management_steps[]`, `severity_notes`

## 6. Dev Tools & Environment

- **IDE / coding agent:** Antigravity (VS Code or Android Studio as fallback)
- **Version control:** Git, hosted on GitHub (free)
- **CI (recommended):** GitHub Actions free tier — run `flutter analyze` + `flutter test` on each push
- **Design reference:** Figma / the Envato UI kit + the UI Theme & Design Brief doc
- **Crash/error monitoring:** Firebase Crashlytics (free)

## 7. Testing

- `flutter_test` for widget/unit tests
- Manual QA on a physical mid-range Android device — camera- and lighting-dependent flows don't represent well on emulators
- A held-out validation image set (separate from training data) to track real detection accuracy, not just training accuracy

## 8. Suggested Repo Structure

```
lib/
 ├── main.dart
 ├── models/            # ScanResult, CropProfile, etc.
 ├── services/          # firebase_service.dart, inference_service.dart
 ├── screens/           # login, crop_select, scan, result, history
 ├── widgets/           # reusable cards, badges, buttons (per theme brief)
 └── l10n/              # Hindi/English localization files
assets/
 ├── model/             # crop_doctor_model.tflite
 └── knowledge_base/    # treatment_data.json
```

## 9. Notes for the Coding Agent

- Do not build a custom backend/API server for V1 — inference is on-device by design (see PRD Section 10 and the free-scale cost strategy)
- Use `flutter_litert`, not the older `tflite_flutter` — same `.tflite` format, current actively-maintained plugin
- Treat Firebase Spark (free) limits as a real constraint: avoid write-heavy patterns (e.g., don't write to Firestore per camera frame — only on final scan submission)
- Keep the treatment knowledge base swappable (JSON now, Firestore-backed later) behind a single service class, not hardcoded across screens
