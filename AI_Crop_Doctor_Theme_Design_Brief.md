# UI Theme & Design Brief

## AI Crop Doctor — Visual Direction for Implementation

**Reference inspiration:** Envato Elements — "Agriculture Monitoring Mobile App" (Penatic_Studio), Figma-compatible agriculture UI kit
**Purpose:** Theme/visual specification for an AI coding agent (e.g., Antigravity) to implement, alongside the AI Crop Doctor PRD
**Note on source:** This brief is built from the established design conventions shared across this genre of agriculture-monitoring UI kits, combined with the AI Crop Doctor PRD's screen and feature list. It is not a pixel-for-pixel extraction of the specific licensed Envato asset — share 2–3 preview screenshots from that kit and this brief can be tightened to match it exactly.

---

## 1. Design Philosophy

- **Mood:** Trustworthy, calm, natural — "an extension officer in your pocket." Not clinical, not flashy, not a panic-inducing medical-app feel.
- **Principles:**
  - Farmer-first clarity: large tap targets, icon + label pairing, minimal jargon
  - Nature-inspired but modern: earthy palette and clean geometry, not a childish or overly playful farm theme
  - Data feels calm, not alarming: even disease alerts use confident, warm color rather than harsh red-only panic states

## 2. Color Palette

| Role | Name | Hex | Usage |
|---|---|---|---|
| Primary | Forest Green | `#2E7D32` | App bar, primary buttons, active nav icon |
| Primary Light | Leaf Green | `#66BB6A` | Secondary buttons, progress indicators, highlights |
| Secondary | Soil Brown | `#8D6E63` | Secondary accents, farm/soil-related icons |
| Accent | Harvest Amber | `#F9A825` | Medium-confidence badges, CTAs needing attention |
| Success | Healthy Green | `#43A047` | "Healthy" results, completed states |
| Warning | Amber Orange | `#FB8C00` | Medium severity, "possible disease" |
| Error / Severe | Deep Rust | `#D84315` | High severity, "consult expert now" |
| Background | Off-white | `#F7F9F5` | Screen background |
| Surface / Card | White | `#FFFFFF` | Cards, sheets |
| Text Primary | Charcoal | `#212121` | Headlines, body text |
| Text Secondary | Warm Grey | `#6B6B6B` | Captions, timestamps, helper text |

Keep the whole app to these ~10 color tokens — don't introduce new colors per screen.

## 3. Typography

- **Latin/English:** Inter or Poppins — clean, geometric, legible at small sizes
- **Hindi/Devanagari:** Noto Sans Devanagari, weight-matched to the Latin font so mixed Hindi+English lines look consistent
- **Scale:** Headline 20–24sp · Section title 16–18sp · Body 14sp · Caption 12sp — keep body text no smaller than 14sp for outdoor/sunlight readability
- **Weight usage:** Semibold for disease names/results, Regular for descriptions, Medium for buttons

## 4. Iconography & Imagery

- Line icons, ~2px stroke, rounded caps — consistent with the modern-clean agriculture style, not skeuomorphic
- Crop-specific icons (tomato, wheat, potato, chili, cotton) used as visual tags throughout the app
- Real leaf/crop photography for scan and result screens; illustration/line art reserved for onboarding and empty states only

## 5. Core Layout Patterns

- **Navigation:** Bottom tab bar — Home / Scan (center, elevated) / History / Profile
- **Cards:** Rounded corners (12–16px radius), soft shadow — used for crop tiles, scan results, history entries
- **Confidence/severity badge:** Pill-shaped chip, color-coded per Section 2, always paired with a text label — never color alone
- **Scan flow:** Full-screen camera → full-screen result (not a modal), so a high-severity result gets the visual weight it deserves

## 6. Screen-by-Screen Notes

Mapped to the PRD's functional requirements:

| Screen | Key UI notes |
|---|---|
| Login / Signup | Minimal fields, large buttons, logo + tagline, language toggle (Hindi/English) visible before login |
| Farmer Profile | Simple form; crop icons as multi-select chips for "primary crops grown" |
| Crop Selection | Grid of crop icon cards, not a dropdown — visual selection is faster for lower-literacy users |
| Scan (camera) | Full-screen camera, large shutter button, on-screen guide frame ("align leaf here"), prominent retake option |
| Result Screen | Photo thumbnail at top, disease name + confidence badge, severity chip, expandable "what to do" section, sticky "Consult expert" button when confidence < 60% or severity is high |
| Scan History | List grouped by crop — thumbnail + result + date, tap to reopen full result |

## 7. Accessibility & Localization

- Minimum touch target: 48×48dp
- Never rely on color alone for severity — always pair with text or an icon
- All primary flows available in Hindi at launch; UI strings externalized for easy addition of more regional languages later
- High color contrast (WCAG AA minimum) given outdoor daylight use

## 8. Handoff Notes for the Coding Agent

- Treat this as a direction, not a locked spec — hex values and spacing are defaults to implement, adjustable once the exact Envato kit assets are downloaded
- Build as a Flutter `ThemeData` with the palette above as named color constants, so the whole app can be restyled from one file if the actual kit's colors differ
- Keep components (cards, badges, buttons) as reusable widgets, not screen-specific one-offs, so visual consistency holds as V2+ screens are added
