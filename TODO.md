# Planten (AI Crop Doctor) — Project Implementation Todo List

> **Architectural Standard:** Every task in this roadmap is strictly **atomic**, **sequentially ordered**, and designed to be executed **one task at a time** with no forward or overlapping dependencies. Each task produces a working, testable state before the next task begins.
>
> **References:**
> - PRD: `AI_Crop_Doctor_PRD.md`
> - Tech Stack: `AI_Crop_Doctor_Tech_Stack.md`
> - Theme & Design Brief: `AI_Crop_Doctor_Theme_Design_Brief.md`

---

## Progress Tracker

- [x] **Phase 1: Project Scaffolding & Dependencies** (Tasks 01–03)
- [x] **Phase 2: Design System & Theming Foundation** (Tasks 04–06)
- [x] **Phase 3: Localization & Multilingual Setup (Hindi/English)** (Tasks 07–09)
- [x] **Phase 4: Assets & Curated Knowledge Base** (Tasks 10–12)
- [x] **Phase 5: Domain Models & Local Storage Service** (Tasks 13–15)
- [x] **Phase 6: Reusable UI Component Library** (Tasks 16–20)
- [x] **Phase 7: Navigation & App Shell** (Tasks 21–23)
- [x] **Phase 8: Firebase & Authentication Layer** (Tasks 24–27)
- [x] **Phase 9: Onboarding & Profile Setup Flow** (Tasks 28–30)
- [x] **Phase 10: Home & Crop Selection Flow** (Tasks 31–33)
- [x] **Phase 11: Camera & Image Capture Engine** (Tasks 34–37)
- [x] **Phase 12: On-Device AI Inference Engine (LiteRT)** (Tasks 38–41)
- [x] **Phase 13: Diagnosis Results & Guidance Presentation** (Tasks 42–45)
- [x] **Phase 14: Scan History & Local Cache Management** (Tasks 46–48)
- [x] **Phase 15: Offline Sync & Cloud Firestore Integration** (Tasks 49–51)
- [x] **Phase 16: History & Farmer Profile Screens** (Tasks 52–54)
- [x] **Phase 17: Polish, Guardrails & End-to-End Verification** (Tasks 55–58)

---

## Phase 1: Project Scaffolding & Dependencies

### [x] Task 01: Configure Dependencies in `pubspec.yaml`
- **Objective:** Add all required production dependencies and dev packages aligned with the Tech Stack doc.
- **Dependencies:** None.
- **Files to update:**
  - `pubspec.yaml`
- **Details:**
  - Add state management: `provider: ^6.1.2`
  - Add routing: `go_router: ^14.8.1`
  - Add Firebase: `firebase_core: ^3.12.1`, `firebase_auth: ^5.5.1`, `cloud_firestore: ^5.6.5`, `firebase_storage: ^12.4.4`
  - Add AI runtime: `flutter_litert: ^0.1.0` (or current stable LiteRT plugin)
  - Add camera & media: `camera: ^0.11.1`, `image_picker: ^1.1.2`, `image: ^4.5.4`
  - Add utility & offline: `shared_preferences: ^2.3.5`, `connectivity_plus: ^6.1.3`, `uuid: ^4.5.1`, `path_provider: ^2.1.5`
  - Add styling & fonts: `google_fonts: ^6.2.1`, `flutter_svg: ^2.0.17`
  - Add localization: `flutter_localizations` (SDK), `intl: ^0.20.2`
  - Configure assets directories in `flutter:` section:
    - `assets/model/`
    - `assets/knowledge_base/`
    - `assets/icons/crops/`
    - `assets/images/`
- **Acceptance Criteria:** `flutter pub get` executes with exit code 0 and zero dependency conflicts.

---

### [x] Task 02: Clean Architecture Directory Structure Scaffolding
- **Objective:** Establish the modular, scalable directory structure per Tech Stack guidelines.
- **Dependencies:** Task 01.
- **Directories to create:**
  - `lib/core/constants/`
  - `lib/core/theme/`
  - `lib/core/utils/`
  - `lib/l10n/`
  - `lib/models/`
  - `lib/services/`
  - `lib/providers/`
  - `lib/widgets/`
  - `lib/screens/auth/`
  - `lib/screens/home/`
  - `lib/screens/scan/`
  - `lib/screens/result/`
  - `lib/screens/history/`
  - `lib/screens/profile/`
  - `assets/model/`
  - `assets/knowledge_base/`
  - `assets/icons/crops/`
  - `assets/images/`
- **Acceptance Criteria:** Directory tree matches architectural blueprint and contains placeholder `.gitkeep` files where necessary.

---

### [x] Task 03: Android Permissions & Hardware Manifest Configuration
- **Objective:** Configure Android camera, gallery, storage, and network permissions.
- **Dependencies:** Task 02.
- **Files to update:**
  - `android/app/src/main/AndroidManifest.xml`
  - `android/app/build.gradle` (verify `minSdkVersion` >= 21)
- **Details:**
  - Add permissions:
    - `android.permission.CAMERA`
    - `android.permission.INTERNET`
    - `android.permission.ACCESS_NETWORK_STATE`
    - `android.permission.READ_EXTERNAL_STORAGE` / `READ_MEDIA_IMAGES`
  - Add hardware feature declaration: `<uses-feature android:name="android.hardware.camera" android:required="true" />`
  - Add `tools:replace="android:label"` if required for manifest merging.
- **Acceptance Criteria:** Android project builds without manifest merge errors (`flutter build apk --config-only` passes).

---

## Phase 2: Design System & Theming Foundation

### [x] Task 04: Define Color Palette Tokens (`AppColors`)
- **Objective:** Implement the exact color tokens specified in the Theme & Design Brief.
- **Dependencies:** Task 03.
- **Files to create:**
  - `lib/core/theme/app_colors.dart`
- **Details:**
  - Define `static const Color`:
    - `primary = Color(0xFF2E7D32)` (Forest Green)
    - `primaryLight = Color(0xFF66BB6A)` (Leaf Green)
    - `secondary = Color(0xFF8D6E63)` (Soil Brown)
    - `accent = Color(0xFFF9A825)` (Harvest Amber)
    - `success = Color(0xFF43A047)` (Healthy Green)
    - `warning = Color(0xFFFB8C00)` (Amber Orange)
    - `error = Color(0xFFD84315)` (Deep Rust)
    - `background = Color(0xFFF7F9F5)` (Off-white)
    - `surface = Color(0xFFFFFFFF)` (White)
    - `textPrimary = Color(0xFF212121)` (Charcoal)
    - `textSecondary = Color(0xFF6B6B6B)` (Warm Grey)
    - `border = Color(0xFFE0E0E0)`
- **Acceptance Criteria:** `app_colors.dart` is clean, const-instantiated, and strictly contains only the ~10 approved tokens.

---

### [x] Task 05: Define Typography Tokens (`AppTypography`)
- **Objective:** Implement typography with dual support for Latin (Inter/Poppins) and Devanagari (Noto Sans Devanagari).
- **Dependencies:** Task 04.
- **Files to create:**
  - `lib/core/theme/app_typography.dart`
- **Details:**
  - Use `GoogleFonts.inter` for English and fallback to `GoogleFonts.notoSansDevanagari` for Hindi script.
  - Define text styles:
    - `headline`: 22sp, FontWeight.w600, `AppColors.textPrimary`
    - `sectionTitle`: 18sp, FontWeight.w600, `AppColors.textPrimary`
    - `body`: 14sp, FontWeight.w400, `AppColors.textPrimary` (never < 14sp for sunlight readability)
    - `bodyMedium`: 14sp, FontWeight.w500, `AppColors.textPrimary`
    - `caption`: 12sp, FontWeight.w400, `AppColors.textSecondary`
    - `button`: 15sp, FontWeight.w500, `Colors.white`
- **Acceptance Criteria:** Typography scales comply with the PRD outdoor/sunlight legibility rule (body >= 14sp).

---

### [x] Task 06: Assemble `AppTheme` (`ThemeData`)
- **Objective:** Create a unified `ThemeData` enforcing cards (12–16px radius, soft shadows), button heights (min 48dp), and app bars.
- **Dependencies:** Task 05.
- **Files to create:**
  - `lib/core/theme/app_theme.dart`
- **Details:**
  - Set `scaffoldBackgroundColor = AppColors.background`
  - Configure `AppBarTheme` with `backgroundColor: AppColors.primary`, elevation 0, white title
  - Configure `CardTheme` with shape `RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))`, elevation 1.5, color `AppColors.surface`
  - Configure `ElevatedButtonThemeData` with minimum touch target `Size.fromHeight(48)`, radius 12, background `AppColors.primary`
  - Configure `BottomNavigationBarThemeData` with selected item color `AppColors.primary`, unselected `AppColors.textSecondary`
- **Acceptance Criteria:** `AppTheme.lightTheme` compiles and renders consistently across test widgets.

---

## Phase 3: Localization & Multilingual Setup (Hindi & English)

### [x] Task 07: Configure Flutter Localization Engine (`l10n.yaml`)
- **Objective:** Enable automatic generation of localized strings for Hindi (`hi`) and English (`en`).
- **Dependencies:** Task 06.
- **Files to create/update:**
  - `l10n.yaml`
  - `lib/l10n/app_en.arb`
  - `lib/l10n/app_hi.arb`
- **Details:**
  - Setup `l10n.yaml` with `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`
  - Populate base strings in `app_en.arb`: app title, login, phone auth, select crop, scan leaf, healthy, disease severity (low, medium, high), confidence levels (likely, possible, uncertain), retake photo, consult expert, history, profile.
- **Acceptance Criteria:** Running `flutter gen-l10n` generates `AppLocalizations` class without syntax errors.

---

### [x] Task 08: Translate Strings into Vernacular Hindi (`app_hi.arb`)
- **Objective:** Add accurate, farmer-accessible Hindi translations without complex bureaucratic jargon.
- **Dependencies:** Task 07.
- **Files to update:**
  - `lib/l10n/app_hi.arb`
- **Details:**
  - Map English keys to natural Hindi:
    - "Select Crop" -> "अपनी फसल चुनें"
    - "Scan Leaf" -> "पत्ती की फोटो लें"
    - "Likely Disease" -> "संभावित रोग"
    - "Possible Disease" -> "यह रोग हो सकता है (पुष्टि आवश्यक)"
    - "Uncertain Diagnosis" -> "निदान अनिश्चित — कृषि विशेषज्ञ से संपर्क करें"
    - "Consult Agriculture Officer" -> "कृषि अधिकारी से सलाह लें"
    - "Healthy Crop" -> "फसल स्वस्थ है"
    - "Retake Photo" -> "साफ़ फोटो दोबारा लें"
- **Acceptance Criteria:** `app_hi.arb` has exact 1:1 key parity with `app_en.arb` and `flutter gen-l10n` produces zero missing-key warnings.

---

### [x] Task 09: Create `LocaleProvider` for Language Toggling
- **Objective:** Build a ChangeNotifier to switch between English and Hindi, persisting the selection locally.
- **Dependencies:** Task 08.
- **Files to create:**
  - `lib/providers/locale_provider.dart`
- **Details:**
  - Expose `Locale currentLocale`
  - Implement `Future<void> setLocale(Locale locale)`
  - Read/write selected locale code (`'hi'` or `'en'`) via `SharedPreferences`
  - Default to Hindi if device locale is Indian, else English
- **Acceptance Criteria:** Toggling locale emits notification and persists across app restarts.

---

## Phase 4: Assets & Curated Knowledge Base

### [x] Task 10: Curate Static Treatment Knowledge Base (`treatment_data.json`)
- **Objective:** Create verified, static disease management knowledge base sourced from ICAR/KVK principles.
- **Dependencies:** Task 09.
- **Files to create:**
  - `assets/knowledge_base/treatment_data.json`
- **Details:**
  - Build entries for V1 launch crops (Tomato, Potato, Wheat, Chili, Cotton).
  - Include key diseases: Early Blight, Late Blight, Leaf Curl, Yellow Rust, Powdery Mildew, Bacterial Spot, Healthy.
  - JSON schema per item:
    - `disease_id`: string (e.g. `"tomato_early_blight"`)
    - `crop`: string (`"tomato"`)
    - `name_en`: string
    - `name_hi`: string
    - `symptoms_en`: string
    - `symptoms_hi`: string
    - `cultural_steps_en`: list of strings (e.g., "Remove and burn infected lower leaves", "Avoid overhead watering")
    - `cultural_steps_hi`: list of strings
    - `management_category`: string (`"fungal"`, `"viral"`, `"bacterial"`, `"pest"`, `"healthy"`)
    - `severity_level`: string (`"low"`, `"medium"`, `"high"`)
    - `disclaimer_en`: "Consult a local Krishi Vigyan Kendra (KVK) or agriculture officer for specific certified treatment products."
    - `disclaimer_hi`: "विशिष्ट प्रमाणित दवा या उपचार के लिए नजदीकी कृषि विज्ञान केंद्र (KVK) या कृषि अधिकारी से संपर्क करें।"
  - **Strict Constraint:** Never prescribe chemical dosage or specific commercial pesticide brand names.
- **Acceptance Criteria:** JSON parses validly with all required fields present for at least 8 crop-disease combinations.

---

### [x] Task 11: Implement `KnowledgeBaseService`
- **Objective:** Create a dedicated service to load and query treatment data behind an abstraction layer.
- **Dependencies:** Task 10.
- **Files to create:**
  - `lib/services/knowledge_base_service.dart`
- **Details:**
  - Implement `Future<void> init()` to load JSON from `rootBundle`
  - Implement `TreatmentGuidance? getGuidanceByDiseaseId(String diseaseId)`
  - Implement `List<TreatmentGuidance> getGuidanceForCrop(String cropId)`
  - Keep architecture swappable so it can pull from Firestore in future releases without changing screen logic.
- **Acceptance Criteria:** Unit test loads `treatment_data.json` and successfully retrieves guidance by `disease_id`.

---

### [x] Task 12: Bundle TFLite Model & Crop Assets
- **Objective:** Place the quantized TFLite model, labels file, and crop vector/PNG icons in assets.
- **Dependencies:** Task 11.
- **Files to add:**
  - `assets/model/crop_doctor_model.tflite` (placeholder/quantized model file)
  - `assets/model/labels.txt` (ordered classification labels matching model output classes)
  - `assets/icons/crops/tomato.png`
  - `assets/icons/crops/potato.png`
  - `assets/icons/crops/wheat.png`
  - `assets/icons/crops/chili.png`
  - `assets/icons/crops/cotton.png`
- **Acceptance Criteria:** All asset paths are declared in `pubspec.yaml` and verified to load via `rootBundle.load()`.

---

## Phase 5: Domain Models & Local Storage Service

### [x] Task 13: Create Core Domain Models (`Crop`, `DiagnosisResult`, `TreatmentGuidance`)
- **Objective:** Define strongly typed, immutable data models with JSON serialization.
- **Dependencies:** Task 12.
- **Files to create:**
  - `lib/models/crop.dart` (id, nameEn, nameHi, iconAssetPath)
  - `lib/models/treatment_guidance.dart`
  - `lib/models/diagnosis_result.dart` (id, cropId, diseaseId, diseaseNameEn, diseaseNameHi, confidenceScore, severity, timestamp, localImagePath, remoteImageUrl, isSynced)
  - `lib/models/confidence_category.dart` (enum: `likely`, `possible`, `uncertain`)
  - `lib/models/severity_level.dart` (enum: `healthy`, `low`, `medium`, `high`)
- **Acceptance Criteria:** Models compile with complete `toJson()` and `fromJson()` serialization methods.

---

### [x] Task 14: Create `FarmerProfile` Model
- **Objective:** Define the user profile entity for farmers.
- **Dependencies:** Task 13.
- **Files to create:**
  - `lib/models/farmer_profile.dart`
- **Details:**
  - Fields: `uid`, `phoneNumber`, `name`, `village`, `district`, `state`, `primaryCrops` (list of crop IDs), `photoBackupOptIn` (boolean, defaults to false per PRD privacy guidelines), `createdAt`.
  - Include `toMap()` and `fromMap()` for Firestore / SharedPreferences serialization.
- **Acceptance Criteria:** `FarmerProfile` serializes and deserializes accurately without data loss.

---

### [x] Task 15: Implement `LocalStorageService`
- **Objective:** Provide robust local key-value and JSON caching for offline-first operation.
- **Dependencies:** Task 14.
- **Files to create:**
  - `lib/services/local_storage_service.dart`
- **Details:**
  - Wrap `SharedPreferences`
  - Methods: `saveSelectedCrop(String cropId)`, `getSelectedCrop()`, `saveUserProfile(FarmerProfile profile)`, `getUserProfile()`, `saveOfflineScans(List<DiagnosisResult> scans)`, `getOfflineScans()`.
- **Acceptance Criteria:** Data written to `LocalStorageService` persists and retrieves identically in test mocks.

---

## Phase 6: Reusable UI Component Library

### [x] Task 16: Build `AppButton` Component
- **Objective:** Create accessible primary and secondary action buttons matching the design brief.
- **Dependencies:** Task 15.
- **Files to create:**
  - `lib/widgets/app_button.dart`
- **Details:**
  - Support `AppButtonType.primary` (Forest Green background, white text) and `AppButtonType.secondary` (Leaf Green / outline).
  - Guarantee minimum touch target height of 48dp.
  - Include loading indicator state (`isLoading`) and disabled state.
  - Support optional leading icon.
- **Acceptance Criteria:** Widget renders with 48dp height, rounded 12px corners, and handles tap events properly.

---

### [x] Task 17: Build `ConfidenceBadge` & `SeverityChip` Components
- **Objective:** Create pill-shaped indicator chips that never rely on color alone.
- **Dependencies:** Task 16.
- **Files to create:**
  - `lib/widgets/confidence_badge.dart`
  - `lib/widgets/severity_chip.dart`
- **Details:**
  - `ConfidenceBadge`:
    - Confidence > 85%: Forest Green background, "Likely" label + check icon
    - Confidence 60–85%: Amber Orange background, "Possible" label + info icon
    - Confidence < 60%: Deep Rust background, "Uncertain" label + alert icon
  - `SeverityChip`:
    - Low: Green (`AppColors.success`)
    - Medium: Amber (`AppColors.warning`)
    - High: Deep Rust (`AppColors.error`)
  - Always render text label alongside color chip.
- **Acceptance Criteria:** Badges correctly map score ranges to correct text labels, icons, and colors per PRD Section 7.6.

---

### [x] Task 18: Build `CropTileCard` Component
- **Objective:** Create visual crop selection card for the grid view.
- **Dependencies:** Task 17.
- **Files to create:**
  - `lib/widgets/crop_tile_card.dart`
- **Details:**
  - Display crop icon/illustration, crop name (localized), and active selection highlight border (`AppColors.primary`).
  - Large tap target (minimum 100x100dp), card radius 14px, gentle shadow.
  - Accessible checkmark overlay when selected.
- **Acceptance Criteria:** Card renders with rounded corners, visual highlight state, and responds to tap.

---

### [x] Task 19: Build `ScanHistoryCard` Component
- **Objective:** Create scan summary card for history lists.
- **Dependencies:** Task 18.
- **Files to create:**
  - `lib/widgets/scan_history_card.dart`
- **Details:**
  - Layout: Left thumbnail (64x64 with 8px radius), center title (disease/healthy) + formatted date, right `ConfidenceBadge`.
  - Background: `AppColors.surface`, elevation 1, padding 12dp.
  - Supports tap navigation to full result view.
- **Acceptance Criteria:** Card displays thumbnail, localized disease name, formatted date, and confidence badge.

---

### [x] Task 20: Build `LanguageToggleWidget` Component
- **Objective:** Provide a compact, ubiquitous toggle between English (EN) and Hindi (हिन्दी).
- **Dependencies:** Task 19.
- **Files to create:**
  - `lib/widgets/language_toggle_widget.dart`
- **Details:**
  - Segmented pill or chip switcher showing "English" and "हिन्दी".
  - Directly interacts with `LocaleProvider`.
  - Accessible on Auth screen, App Bar, and Profile screen.
- **Acceptance Criteria:** Tapping either language instantly updates active app locale across current widget tree.

---

## Phase 7: Navigation & App Shell

### [x] Task 21: Configure Declarative Routing with `GoRouter`
- **Objective:** Set up complete declarative route hierarchy.
- **Dependencies:** Task 20.
- **Files to create:**
  - `lib/core/router/app_router.dart`
- **Details:**
  - Define routes:
    - `/splash`: Splash & auth state check
    - `/login`: Phone/Email login screen
    - `/profile-setup`: Onboarding profile creation
    - `/home`: Crop dashboard (ShellRoute tab 1)
    - `/scan`: Full-screen camera scan (elevated center tab or direct push)
    - `/scan/preview`: Photo blur/lighting verification preview
    - `/result`: Full-screen diagnosis result
    - `/history`: Scan history list (ShellRoute tab 2)
    - `/profile`: Farmer profile & settings (ShellRoute tab 3)
- **Acceptance Criteria:** `GoRouter` compiles with all route definitions and parameter parsers.

---

### [x] Task 22: Build `MainScaffold` with Custom Bottom Navigation Bar
- **Objective:** Implement bottom navigation with elevated center "Scan" button per design brief.
- **Dependencies:** Task 21.
- **Files to create:**
  - `lib/screens/main_scaffold.dart`
- **Details:**
  - Bottom navigation items:
    - Tab 0: Home (Forest green active icon)
    - Tab 1: Scan (Center floating/elevated green circle button with camera icon)
    - Tab 2: History (Archive/clock icon)
    - Tab 3: Profile (Person/farmer icon)
  - Integrated with `StatefulShellRoute` in `GoRouter`.
- **Acceptance Criteria:** Tapping navigation items switches tabs with preserved state; center scan button triggers camera route.

---

### [x] Task 23: Create Splash Screen & Auth Gate Flow
- **Objective:** Check stored credentials and route to `/login` or `/home`.
- **Dependencies:** Task 22.
- **Files to create:**
  - `lib/screens/splash_screen.dart`
- **Details:**
  - Display Planten logo + tagline ("Your AI Crop Doctor").
  - Initialize `LocalStorageService`, `KnowledgeBaseService`, check Firebase auth state.
  - Route to `/home` if authenticated and profile exists; route to `/profile-setup` if auth exists but no profile; otherwise route to `/login`.
- **Acceptance Criteria:** App boots to splash screen and routes cleanly to appropriate screen within 1.5 seconds.

---

## Phase 8: Firebase & Authentication Layer

### [x] Task 24: Initialize Firebase Services (`FirebaseService`)
- **Objective:** Set up Firebase core initialization with graceful offline fallback.
- **Dependencies:** Task 23.
- **Files to create:**
  - `lib/services/firebase_service.dart`
- **Details:**
  - Call `Firebase.initializeApp()` with environment configurations.
  - Configure Firestore offline cache persistence: `FirebaseFirestore.instance.settings = Settings(persistenceEnabled: true)`.
  - Handle initialization errors gracefully if device is completely offline.
- **Acceptance Criteria:** App initializes Firebase on startup without throwing unhandled exceptions.

---

### [x] Task 25: Implement `AuthService`
- **Objective:** Handle farmer authentication via Phone Number (OTP) and Email/Password fallback.
- **Dependencies:** Task 24.
- **Files to create:**
  - `lib/services/auth_service.dart`
- **Details:**
  - `Future<void> verifyPhoneNumber({required String phoneNumber, ...})`
  - `Future<UserCredential> signInWithOtp({required String verificationId, required String smsCode})`
  - `Future<UserCredential> signInWithEmailPassword(String email, String password)`
  - `Future<void> signOut()`
  - Stream `User? authStateChanges`
- **Acceptance Criteria:** Mock/Firebase auth calls succeed; auth state changes trigger expected stream events.

---

### [x] Task 26: Implement `UserProfileService`
- **Objective:** Manage Firestore CRUD for farmer profiles (`farmers/{uid}`).
- **Dependencies:** Task 25.
- **Files to create:**
  - `lib/services/user_profile_service.dart`
- **Details:**
  - `Future<void> createOrUpdateProfile(FarmerProfile profile)`
  - `Future<FarmerProfile?> getProfile(String uid)`
  - Cache active profile in `LocalStorageService` for instant offline availability.
  - Respect Spark free-tier limits: minimal reads/writes.
- **Acceptance Criteria:** Profile data saves to Firestore and caches locally in SharedPreferences.

---

### [x] Task 27: Implement `AuthProvider`
- **Objective:** State management provider exposing authentication and profile state to UI.
- **Dependencies:** Task 26.
- **Files to create:**
  - `lib/providers/auth_provider.dart`
- **Details:**
  - Expose `User? user`, `FarmerProfile? profile`, `bool isLoading`, `String? errorMessage`.
  - Methods: `sendOtp()`, `verifyOtp()`, `updateProfile()`, `logout()`.
- **Acceptance Criteria:** Auth state changes propagate to listening UI widgets.

---

## Phase 9: Onboarding & Profile Setup Flow

### [x] Task 28: Build Login Screen (`LoginScreen`)
- **Objective:** Implement simple, large-button login screen with language toggle.
- **Dependencies:** Task 27.
- **Files to create:**
  - `lib/screens/auth/login_screen.dart`
- **Details:**
  - Top header: Planten logo, tagline, and prominent `LanguageToggleWidget`.
  - Form: Phone number input with `+91` prefix (or email tab).
  - Large primary `AppButton` ("Send OTP" / "ओटीपी भेजें").
  - Clean error banner on invalid input.
- **Acceptance Criteria:** Screen complies with Design Brief (clean off-white background, forest green CTA, min 48dp input targets).

---

### [x] Task 29: Build OTP Verification Dialog / View
- **Objective:** Implement 6-digit OTP entry with auto-resend timer.
- **Dependencies:** Task 28.
- **Files to create:**
  - `lib/screens/auth/otp_verification_view.dart`
- **Details:**
  - 6-digit numeric input with auto-focus.
  - Resend OTP countdown (60 seconds).
  - Submit button triggering `AuthProvider.verifyOtp()`.
  - Transition to `/home` or `/profile-setup` on success.
- **Acceptance Criteria:** Valid OTP submission successfully authenticates user and navigates.

---

### [x] Task 30: Build Farmer Profile Setup Screen (`ProfileSetupScreen`)
- **Objective:** Allow new users to enter name, village/district, and select primary crops.
- **Dependencies:** Task 29.
- **Files to create:**
  - `lib/screens/profile/profile_setup_screen.dart`
- **Details:**
  - Text fields: Farmer Name, Village, District.
  - Multi-select crop chip selector (Tomato, Wheat, Potato, Chili, Cotton).
  - Privacy toggle: "Opt-in to back up scan photos to cloud" (defaults to OFF).
  - "Save & Continue" button creating profile via `AuthProvider`.
- **Acceptance Criteria:** Profile saves to both Firestore and local cache; user routes to `/home`.

---

## Phase 10: Home & Crop Selection Flow

### [x] Task 31: Implement `CropProvider`
- **Objective:** Manage supported crops, active crop selection, and persisted preference.
- **Dependencies:** Task 30.
- **Files to create:**
  - `lib/providers/crop_provider.dart`
- **Details:**
  - Maintain list of 5 V1 crops: Tomato, Wheat, Potato, Chili, Cotton with icons and localization keys.
  - `Crop? selectedCrop`
  - `void selectCrop(Crop crop)` (persists to `LocalStorageService`).
- **Acceptance Criteria:** Changing selected crop updates state and survives app restarts.

---

### [x] Task 32: Build Home Dashboard Screen (`HomeScreen`)
- **Objective:** Create the main farm screen showcasing active crop, quick scan CTA, and recent health summary.
- **Dependencies:** Task 31.
- **Files to create:**
  - `lib/screens/home/home_screen.dart`
- **Details:**
  - Header: Greeting with farmer name, village, and current date.
  - Active Crop Card: Shows current selected crop with "Change" button.
  - Large Hero CTA: "Scan Leaf for Disease" (`AppColors.primary`, camera icon, full-width).
  - Recent Scans Section: Displays last 3 scans for active crop or empty state prompting first scan.
- **Acceptance Criteria:** Home screen displays all sections cleanly and passes WCAG AA contrast against `#F7F9F5` background.

---

### [x] Task 33: Build Crop Selection Modal / Screen (`CropSelectionScreen`)
- **Objective:** Visual grid of crop cards for fast, low-literacy selection.
- **Dependencies:** Task 32.
- **Files to create:**
  - `lib/screens/home/crop_selection_screen.dart`
- **Details:**
  - 2-column GridView of `CropTileCard` widgets (Tomato, Wheat, Potato, Chili, Cotton).
  - No dropdowns; visual card tap selection.
  - Confirmation button returns to Home or Scan flow.
- **Acceptance Criteria:** Tapping a crop card sets it as active in `CropProvider` and returns to previous screen.

---

## Phase 11: Camera & Image Capture Engine

### [x] Task 34: Implement `CameraService`
- **Objective:** Initialize and manage device camera lifecycle safely.
- **Dependencies:** Task 33.
- **Files to create:**
  - `lib/services/camera_service.dart`
- **Details:**
  - Discover available cameras via `availableCameras()`.
  - Initialize back camera with high resolution preset.
  - Methods: `initialize()`, `takePicture()`, `dispose()`, `setFlashMode()`.
  - Fallback to `image_picker` if camera hardware fails or permission is permanently denied.
- **Acceptance Criteria:** Camera controller initializes without memory leaks and captures photo file to temporary storage.

---

### [x] Task 35: Build Full-Screen Camera Screen (`ScanScreen`)
- **Objective:** Implement full-screen viewfinder with on-screen leaf alignment guide frame.
- **Dependencies:** Task 34.
- **Files to create:**
  - `lib/screens/scan/scan_screen.dart`
- **Details:**
  - Full-screen `CameraPreview`.
  - Rounded rectangular guide overlay ("Align infected leaf inside box / पत्ती को चौखट के अंदर रखें").
  - Top bar: Close button, flash toggle, active crop indicator.
  - Bottom bar: Gallery picker icon, large circular shutter button, helper text.
- **Acceptance Criteria:** Camera renders smoothly with centered alignment guide; shutter triggers photo capture.

---

### [x] Task 36: Implement Image Quality / Blur & Lighting Pre-check Utility
- **Objective:** Check captured photo for severe blur or darkness before running AI inference.
- **Dependencies:** Task 35.
- **Files to create:**
  - `lib/core/utils/image_quality_checker.dart`
- **Details:**
  - Read captured image pixels via `image` package.
  - Calculate average luminance (detect underexposed/too dark photo).
  - Calculate variance of Laplacian / gradient sharpness (detect extreme blur).
  - Return `ImageQualityResult(bool isValid, String? warningMessageEn, String? warningMessageHi)`.
- **Acceptance Criteria:** Unit test detects black/blurry test image and flags it as invalid.

---

### [x] Task 37: Build Photo Preview & Quality Verification Screen (`PhotoPreviewScreen`)
- **Objective:** Show captured leaf image with retake option if lighting/blur check warns user.
- **Dependencies:** Task 36.
- **Files to create:**
  - `lib/screens/scan/photo_preview_screen.dart`
- **Details:**
  - Display captured image full size.
  - If quality check warns of low light or blur: display amber warning banner with "Retake Photo" prominent button.
  - If photo is accepted: "Analyze Leaf / रोग की जांच करें" primary action button.
- **Acceptance Criteria:** User can either discard and retake photo or accept it to proceed to AI inference.

---

## Phase 12: On-Device AI Inference Engine (LiteRT)

### [x] Task 38: Implement `ImagePreprocessor` Utility
- **Objective:** Resize, crop, and normalize camera images to match TFLite input tensor requirements.
- **Dependencies:** Task 37.
- **Files to create:**
  - `lib/core/utils/image_preprocessor.dart`
- **Details:**
  - Resize image to model dimensions (e.g. 224x224 or 256x256 RGB).
  - Normalize pixel values: float32 in `[0.0, 1.0]` or uint8 depending on model quantization spec.
  - Convert image to 4D tensor buffer `[1, height, width, 3]`.
- **Acceptance Criteria:** Preprocessor outputs correctly shaped Float32List/Uint8List tensor buffer.

---

### [x] Task 39: Implement `InferenceService` (LiteRT / TFLite)
- **Objective:** Load model file and run on-device inference using `flutter_litert`.
- **Dependencies:** Task 38.
- **Files to create:**
  - `lib/services/inference_service.dart`
- **Details:**
  - Load `crop_doctor_model.tflite` from assets.
  - Load `labels.txt`.
  - Method `Future<RawInferenceOutput> runInference(File imageFile)`:
    - Preprocess image.
    - Run interpreter with tensor input and output buffers.
    - Extract raw probability array and map top predictions.
  - Target latency: under 3 seconds on mid-range Android device.
- **Acceptance Criteria:** Model runs inference on sample leaf image and returns probability array summing to ~1.0.

---

### [x] Task 40: Implement `ConfidenceEvaluationEngine`
- **Objective:** Apply PRD confidence thresholds and rule engine to raw model outputs.
- **Dependencies:** Task 39.
- **Files to create:**
  - `lib/services/confidence_evaluation_engine.dart`
- **Details:**
  - Rules mapped to PRD Section 7.6:
    - Confidence > 0.85: Category = `Likely`, assign predicted disease, full guidance unlocked.
    - Confidence 0.60 – 0.85: Category = `Possible`, prompt to retake clearer photo, partial guidance.
    - Confidence < 0.60: Category = `Uncertain`, do NOT assert a disease name, route to "Consult Agriculture Expert".
  - Filter predictions based on current selected crop context (prevent tomato disease reported on wheat).
- **Acceptance Criteria:** Logic unit tests verify all 3 confidence brackets adhere strictly to PRD behavior table.

---

### [x] Task 41: Implement `DiagnosisProvider`
- **Objective:** Coordinate scanning, inference, and guidance lookup in state provider.
- **Dependencies:** Task 40.
- **Files to create:**
  - `lib/providers/diagnosis_provider.dart`
- **Details:**
  - States: `idle`, `processing`, `success`, `error`.
  - Method `Future<DiagnosisResult> diagnoseLeaf(File imageFile, Crop selectedCrop)`:
    - Calls `InferenceService`
    - Evaluates via `ConfidenceEvaluationEngine`
    - Attaches `TreatmentGuidance` from `KnowledgeBaseService`
    - Creates `DiagnosisResult`
- **Acceptance Criteria:** Provider executes diagnosis flow and updates state within < 3 seconds on device.

---

## Phase 13: Diagnosis Results & Guidance Presentation

### [x] Task 42: Build Diagnosis Result Screen (`ResultScreen`)
- **Objective:** Full-screen diagnosis view with clear visual hierarchy (photo, disease name, confidence, severity).
- **Dependencies:** Task 41.
- **Files to create:**
  - `lib/screens/result/result_screen.dart`
- **Details:**
  - Top: Leaf photo thumbnail (rounded 12px) with scan timestamp and crop badge.
  - Center: Disease Title (Large, Semibold, localized) + `ConfidenceBadge` + `SeverityChip`.
  - Description: Plain-language explanation of what is happening to the plant.
  - Sticky Bottom: "Consult Local Agriculture Officer" CTA or "Save to History" button.
- **Acceptance Criteria:** Result screen matches design brief layout and displays appropriate confidence state.

---

### [x] Task 43: Build Expandable Treatment & Prevention Guidance Section
- **Objective:** Display cultural and preventative management steps from knowledge base.
- **Dependencies:** Task 42.
- **Files to create:**
  - `lib/widgets/treatment_guidance_view.dart`
- **Details:**
  - Expandable accordion cards for:
    - "Symptoms / लक्षण"
    - "Preventive Actions / रोकथाम के उपाय" (numbered bullet points)
    - "Important Safety Advice / महत्वपूर्ण सूचना" (no pesticide brand names; verified KVK advice only)
  - Clear ICAR/KVK attribution note.
- **Acceptance Criteria:** Guidance renders cleanly in selected language; does not display any unauthorized chemical dosages.

---

### [x] Task 44: Build Low-Confidence / Uncertain Result Screen State
- **Objective:** Handle <60% confidence cases with safe fallbacks.
- **Dependencies:** Task 43.
- **Files to update:**
  - `lib/screens/result/result_screen.dart`
- **Details:**
  - Hide specific disease assertions.
  - Display "Uncertain Diagnosis / निदान अनिश्चित" warning card in Harvest Amber / Deep Rust.
  - Prominently display two primary actions:
    1. "Retake Photo in Better Light / अच्छी रोशनी में दोबारा फोटो लें"
    2. "Contact Local Krishi Vigyan Kendra (KVK) / नजदीकी कृषि केंद्र से संपर्क करें"
  - Display checklist of why photo might have failed (shadow, leaf too far, multiple leaves in frame).
- **Acceptance Criteria:** Scans with confidence < 0.60 never display a guessed disease name.

---

### [x] Task 45: Build "Consult Agriculture Expert" Action Sheet
- **Objective:** Provide direct contact info for regional agriculture helplines / Kisan Call Center.
- **Dependencies:** Task 44.
- **Files to create:**
  - `lib/widgets/consult_expert_bottom_sheet.dart`
- **Details:**
  - Displays national Kisan Call Center toll-free number (`1800-180-1551`) with one-tap dialer (`url_launcher`).
  - Explains how to present the sample to a local Krishi Vigyan Kendra (KVK) officer.
  - Includes prompt to save/share diagnosis card with extension worker.
- **Acceptance Criteria:** Tapping dialer opens phone dialer with Kisan Call Center number pre-filled.

---

## Phase 14: Scan History & Local Cache Management

### [x] Task 46: Implement `HistoryService` (Offline-First Storage)
- **Objective:** Store scan history locally on device before attempting cloud sync.
- **Dependencies:** Task 45.
- **Files to create:**
  - `lib/services/history_service.dart`
- **Details:**
  - Store scan metadata as JSON in local storage.
  - Store compressed leaf thumbnail in app's local document directory (`path_provider`).
  - Methods: `Future<void> saveScan(DiagnosisResult scan)`, `Future<List<DiagnosisResult>> getScansByCrop(String cropId)`, `Future<List<DiagnosisResult>> getAllScans()`.
- **Acceptance Criteria:** Scans saved offline can be queried and loaded with working image thumbnails while device is in Airplane mode.

---

### [x] Task 47: Implement `HistoryProvider`
- **Objective:** State provider managing scan history, filtering by crop, and sync state.
- **Dependencies:** Task 46.
- **Files to create:**
  - `lib/providers/history_provider.dart`
- **Details:**
  - Expose `List<DiagnosisResult> scans`, `String? activeFilterCropId`.
  - Methods: `loadHistory()`, `filterByCrop(String? cropId)`, `deleteScan(String scanId)`.
- **Acceptance Criteria:** History provider automatically reloads when new scan is completed.

---

### [x] Task 48: Build History List Screen (`HistoryScreen`)
- **Objective:** Grouped scan history list with crop filter chips.
- **Dependencies:** Task 47.
- **Files to create:**
  - `lib/screens/history/history_screen.dart`
- **Details:**
  - Top filter bar: Horizontal scrollable crop filter chips ("All", "Tomato", "Wheat", etc.).
  - Body: ListView of `ScanHistoryCard` items grouped by date.
  - Empty state: Clean agriculture illustration/icon + "No scans yet for this crop. Tap Scan to diagnose your first leaf."
  - Tapping an item navigates to `ResultScreen` in review mode.
- **Acceptance Criteria:** Tapping history item reopens complete result view with saved diagnosis and guidance.

---

## Phase 15: Offline Sync & Cloud Firestore Integration

### [x] Task 49: Implement `NetworkMonitorService`
- **Objective:** Listen to connectivity changes and trigger background sync.
- **Dependencies:** Task 48.
- **Files to create:**
  - `lib/services/network_monitor_service.dart`
- **Details:**
  - Wrap `connectivity_plus`.
  - Expose `Stream<bool> isOnlineStream` and `bool get isOnline`.
  - Trigger sync callback when transitioning from offline to online.
- **Acceptance Criteria:** Service accurately detects internet connect/disconnect events.

---

### [x] Task 50: Implement Cloud Sync Engine (`FirestoreSyncService`)
- **Objective:** Sync unsynced scan metadata to Cloud Firestore (`scans/{scanId}`).
- **Dependencies:** Task 49.
- **Files to create:**
  - `lib/services/firestore_sync_service.dart`
- **Details:**
  - Query unsynced scans (`isSynced == false`) from `HistoryService`.
  - Upload metadata only: `userId`, `cropId`, `diseaseId`, `confidenceScore`, `severity`, `timestamp`.
  - Do NOT upload raw photo unless farmer explicitly enabled `photoBackupOptIn`.
  - Batch write to Firestore to respect Spark free tier limits.
  - Mark local records as `isSynced = true`.
- **Acceptance Criteria:** Unsynced records write to Firestore when online; local `isSynced` flag updates.

---

### [x] Task 51: Implement Optional Cloud Photo Backup (Opt-In Only)
- **Objective:** Conditionally upload compressed photo to Firebase Storage only if user opted in.
- **Dependencies:** Task 50.
- **Files to update:**
  - `lib/services/firestore_sync_service.dart`
- **Details:**
  - Check `FarmerProfile.photoBackupOptIn`.
  - If false: skip image upload completely; set `remoteImageUrl = null`.
  - If true: compress image (<200KB) and upload to `users/{uid}/scans/{scanId}.jpg`, saving download URL in metadata.
- **Acceptance Criteria:** Photos are never uploaded by default, protecting farmer bandwidth and Firebase free tier storage.

---

## Phase 16: History & Farmer Profile Screens

### [x] Task 52: Build Farmer Profile Screen (`ProfileScreen`)
- **Objective:** Manage farmer details, primary crops, language preference, and privacy settings.
- **Dependencies:** Task 51.
- **Files to create:**
  - `lib/screens/profile/profile_screen.dart`
- **Details:**
  - Farmer info card (Name, Phone number, Village/District).
  - Primary Crops selector (allows updating grown crops).
  - Language switcher tile with `LanguageToggleWidget`.
  - Privacy Settings tile: "Back up photos to cloud" switch toggle.
  - Offline sync status indicator ("All scans synced" or "X scans waiting for internet").
  - "Log Out" button with confirmation dialog.
- **Acceptance Criteria:** Changes made in Profile Screen immediately persist and reflect across app.

---

### [x] Task 53: Build In-App Disclaimer & Legal Notice View
- **Objective:** Prominently display liability disclaimer per PRD Section 13.
- **Dependencies:** Task 52.
- **Files to create:**
  - `lib/screens/profile/disclaimer_screen.dart`
- **Details:**
  - Explicit statement: "Planten is an AI-powered decision support tool. It does not replace certified agronomist advice. Always consult local agriculture authorities before applying chemical treatments."
  - Available in both English and Hindi.
- **Acceptance Criteria:** Disclaimer is accessible from Profile screen and during initial onboarding.

---

### [x] Task 54: Build Offline Status Banner Component
- **Objective:** Provide a non-intrusive status banner when app is operating offline.
- **Dependencies:** Task 53.
- **Files to create:**
  - `lib/widgets/offline_banner.dart`
- **Details:**
  - Compact amber pill/strip: "Offline Mode — AI Diagnosis Works Normally / ऑफलाइन मोड — एआई जांच चालू है".
  - Shows when `NetworkMonitorService.isOnline == false`.
- **Acceptance Criteria:** Banner appears when network is disconnected and disappears when restored without interrupting camera or AI scanning.

---

## Phase 17: Polish, Guardrails & End-to-End Verification

### [x] Task 55: Assemble `main.dart` with Providers and Root Observers
- **Objective:** Tie together all providers, localization, router, and error boundary in `main.dart`.
- **Dependencies:** Task 54.
- **Files to update:**
  - `lib/main.dart`
- **Details:**
  - MultiProvider setup: `LocaleProvider`, `AuthProvider`, `CropProvider`, `DiagnosisProvider`, `HistoryProvider`.
  - MaterialApp.router with `AppTheme.lightTheme`, `locale: localeProvider.currentLocale`, `localizationsDelegates`, `supportedLocales`.
  - Global error handler (`FlutterError.onError`) logging to debug console.
- **Acceptance Criteria:** Application boots smoothly into splash screen and completes full route lifecycle.

---

### [x] Task 56: Unit & Integration Tests for Diagnosis & Confidence Logic
- **Objective:** Automated test suite verifying PRD core requirements.
- **Dependencies:** Task 55.
- **Files to create:**
  - `test/confidence_evaluation_test.dart`
  - `test/knowledge_base_test.dart`
  - `test/image_quality_test.dart`
- **Details:**
  - Test >85% confidence returns `Likely` and assigns disease.
  - Test 60–85% confidence returns `Possible` and warns user.
  - Test <60% confidence returns `Uncertain` and withholds disease name.
  - Test knowledge base returns cultural steps and never mentions dosage.
- **Acceptance Criteria:** `flutter test` passes all tests with 100% success rate.

---

### [x] Task 57: Outdoor Readability & Touch Target Accessibility Audit
- **Objective:** Verify UI complies with Theme Brief ergonomics.
- **Dependencies:** Task 56.
- **Details:**
  - Audit touch targets across all screens: every interactive button/chip >= 48x48dp.
  - Audit typography: all body text >= 14sp; headings >= 18sp.
  - Audit contrast ratio: verify text on `#F7F9F5` background achieves WCAG AA (>= 4.5:1).
  - Verify Devanagari text alignment with Noto Sans Devanagari font.
- **Acceptance Criteria:** Zero accessibility or contrast violations in layout inspector.

---

### [x] Task 58: End-to-End Workflow Verification on Device
- **Objective:** Complete physical walk-through of the entire farmer user journey.
- **Dependencies:** Task 57.
- **Flow to verify:**
  1. Boot app -> select Hindi language -> login with phone.
  2. Complete profile -> select Tomato as primary crop.
  3. Home screen shows Tomato -> tap "Scan Leaf".
  4. Viewfinder opens with guide overlay -> take photo of leaf.
  5. Blur/lighting pre-check passes -> proceed to analysis.
  6. On-device LiteRT inference runs in < 3 seconds with zero internet.
  7. Result screen renders disease name, confidence badge, severity chip, and ICAR cultural steps.
  8. Scan auto-saves to local history.
  9. Turn on internet -> verify Firestore metadata syncs without uploading raw photo.
- **Acceptance Criteria:** Complete flow executes without crashes, errors, or latency exceeding 3 seconds.
