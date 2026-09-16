# Product Requirements Document (PRD)

## AI Crop Doctor — AI-Powered Crop Disease Diagnosis App for Farmers

**Version:** 1.0
**Date:** September 2026
**Status:** Draft — MVP Planning

---

## 1. Executive Summary

AI Crop Doctor is a mobile app that helps farmers diagnose crop diseases, pest damage, and nutrient deficiencies by scanning a leaf/plant photo with an on-device AI model. Unlike a simple "photo → disease name" scanner, it is built as a farm decision-support tool: it gives confidence-scored results in Hindi/vernacular language, tracks crop health history over time, and routes uncertain or severe cases to a human agriculture expert instead of guessing.

The product targets small and marginal farmers who lack quick access to agronomists, and is architected to run at near-zero infrastructure cost by keeping AI inference on-device and using free-tier cloud services for everything else.

## 2. Problem Statement

- Crop diseases and pests cause major yield loss every season; by the time symptoms are visibly obvious, damage is often already spreading.
- Access to a qualified agronomist or extension officer is slow or physically distant for most small farmers.
- Generic plant-ID apps only label a disease — they don't guide the farmer on what to do next, usually need internet, and are rarely in a local language.
- Farmers need fast, local-language, low-connectivity-friendly guidance they can act on immediately.

## 3. Goals & Objectives

**Product goals**
- Deliver a disease/pest/deficiency diagnosis from a photo in under ~10 seconds, even offline.
- Give guidance in Hindi/regional language a non-technical user can act on.
- Avoid false confidence — clearly separate "likely," "possible," and "uncertain, consult an expert."
- Build a crop-health history per farmer, not just a one-off scan.

**Project goals (for this build)**
- Ship a working, demoable MVP suitable as a college project / portfolio piece.
- Keep infra and AI cost at ~₹0 through MVP and early growth.
- Leave a clear path to a real product/startup if adoption and accuracy validate the idea.

## 4. Target Users

| Persona | Description | Key need |
|---|---|---|
| Small/marginal farmer | 1–5 acres, 1–2 main crops (e.g. wheat, tomato), limited English literacy, patchy mobile internet | Fast, local-language answer to "what's wrong with my crop" |
| Progressive/commercial farmer | Larger landholding, multiple crops, more tech-comfortable | Wants scan history and trends across fields |
| Agri-extension / KVK worker | Visits multiple farms, needs a quick triage tool | Wants to screen many farms fast and flag severe cases |

## 5. Scope

**In scope — V1 (MVP)**
- Farmer login & basic profile
- Crop selection
- Photo capture/upload of leaf or plant
- On-device AI detection (disease / pest / nutrient deficiency / healthy)
- Confidence-scored result with severity
- Static, curated management/prevention guidance
- Scan history per crop

**Out of scope — V1** (see Section 11 for phased rollout)
- Voice input/output
- Regional languages beyond Hindi + English
- Weather-based risk alerts
- Multi-field crop monitoring dashboard
- Live connection to a human agriculture expert
- Custom-trained proprietary AI model (V1 uses transfer learning on public datasets)

## 6. User Stories

1. As a farmer, I want to photograph a leaf and get a diagnosis, so I don't have to wait for an expert visit to know what's wrong.
2. As a farmer, I want the result explained in Hindi in plain language, so I can understand it without technical knowledge.
3. As a farmer, I want to know how confident the app is, so I don't act on a wrong guess.
4. As a farmer, I want to see my past scans per crop, so I can track if a problem is recurring or spreading.
5. As a farmer, I want to be told to consult an expert when the app isn't sure or the case looks severe, so I don't mistreat my crop.
6. As a new user, I want to sign up and start scanning with minimal friction.

## 7. Functional Requirements

### 7.1 Authentication & Profile
- Sign up/login via phone number or email (Firebase Auth)
- Basic profile: name, location (village/district), primary crops grown

### 7.2 Crop Selection
- Farmer selects crop from a supported list — start with 3–5 high-impact crops (e.g. tomato, wheat, potato, chili, cotton)

### 7.3 Photo Capture / Upload
- In-app camera capture or gallery upload
- Basic on-device blur/lighting check before submitting, so a bad photo is rejected before it wastes a scan

### 7.4 AI Detection Engine
- On-device model classifies the image as: specific disease, pest damage, nutrient deficiency, or healthy
- Returns a confidence score (0–100%)

### 7.5 Results Display
- Disease/pest/deficiency name
- Confidence percentage
- Severity indicator (Low/Medium/High)
- Plain-language explanation of what's happening to the plant

### 7.6 Confidence Handling (critical requirement)

| Confidence | Behavior |
|---|---|
| > 85% | Show as "Likely [disease]" with full guidance |
| 60–85% | Show as "Possible [disease]" + prompt to retake a clearer photo |
| < 60% | Show "Uncertain" + recommend contacting a local agriculture officer, no disease name asserted |

### 7.7 Treatment & Prevention Guidance
- Sourced from a static, pre-curated knowledge base (not generated live by an LLM), built from verified sources (ICAR, state agriculture department, Krishi Vigyan Kendra material)
- Per disease: symptoms, cultural/preventive steps (remove infected leaves, spacing, ventilation, etc.), general management category
- Never prescribes a specific pesticide name or dosage — always directs to "consult a local agriculture expert for product recommendation," to avoid liability and regional-regulation mismatches

### 7.8 Scan History
- Per-crop log: date, photo thumbnail, result, confidence
- Simple view: "My Farm → [Crop] → past scans"

## 8. Non-Functional Requirements

- **Offline-first:** the core scan-and-diagnose flow works with zero connectivity (on-device model); only history sync needs internet.
- **Latency:** result in under 3 seconds on a mid-range Android device.
- **Language:** Hindi + English at launch; UI and results both localized.
- **Privacy:** photos are processed on-device; only result metadata (not the raw photo) syncs to the cloud by default, with opt-in photo backup.
- **Cost:** infrastructure stays within free-tier limits through MVP and early growth (see Section 10).
- **Device support:** Android-first; iOS as a later consideration.

## 9. AI Model Requirements

- **Datasets:** PlantVillage (public, ~54K labeled leaf images across 14 crops/26 diseases) as the base, blended with PlantDoc (real-world field images) to close the "lab photo vs. real farm photo" accuracy gap.
- **Approach:** transfer learning on a mobile-optimized backbone (MobileNetV2 or EfficientNet-Lite) rather than training from scratch.
- **Deployment format:** quantized TensorFlow Lite model (~5–10MB) bundled into the Flutter app for on-device inference.
- **Output classes:** disease (per crop), pest damage, nutrient deficiency, healthy.
- **Retraining path:** as real farmer-submitted photos accumulate (with consent), periodically retrain and ship an improved model via app update.

## 10. Technical Architecture (High Level)

```
Flutter App (camera, UI, on-device TFLite inference)
        │
        ├── Firebase Auth (login)
        ├── Firestore (profile, crop list, scan results/history — free tier)
        └── Static treatment knowledge base (bundled JSON / Firestore)
```

- No dedicated AI backend server for V1 — inference runs on-device.
- Firebase Spark (free) plan covers auth, Firestore reads/writes, and minimal storage at MVP-to-moderate scale.
- Voice (V2+) uses on-device OS speech APIs rather than paid cloud speech services.

## 11. Roadmap

| Version | Scope |
|---|---|
| V1 (MVP) | Login, crop selection, photo scan, AI detection, confidence + severity, static treatment guidance, scan history |
| V2 | Voice input/output, additional regional languages |
| V3 | Weather-based disease-risk alerts |
| V4 | Multi-field crop monitoring dashboard |
| V5 | Live connection to human agriculture experts |

## 12. Success Metrics

- **Accuracy:** % of scans where the AI result matches an expert/ground-truth label (validation set, not just training accuracy)
- **Adoption:** registered farmers, scans/week
- **Retention:** % of farmers returning for a second scan within 30 days
- **Trust/safety:** % of low-confidence cases correctly routed to "consult expert" instead of a wrong confident answer
- **Cost:** infra cost per active user (target: ₹0 through MVP stage)

## 13. Risks & Assumptions

| Risk | Mitigation |
|---|---|
| AI misdiagnosis leads to a wrong farmer action | Confidence thresholds, no direct pesticide prescriptions, always offer "consult expert" path |
| Public datasets don't reflect local crop varieties/conditions | Blend in PlantDoc field images; collect local data over time with consent |
| Low smartphone/internet access among target users | Offline-first, on-device inference, lightweight app size |
| Liability if a farmer's crop is damaged after following app advice | Guidance stays informational/preventive only, never dosage-specific; clear in-app disclaimer |
| Firebase free-tier limits hit at scale | Store only result metadata by default, not raw photos, to keep Firestore/storage usage low |

## 14. Open Questions

- Which 3–5 crops should V1 launch with, based on the target region's dominant crops?
- Should scan-history sync be opt-in or on by default?
- What disclaimer/consent language is needed for photo storage and future model retraining?
