# UI Audit & Navigation Update — Planten (AI Crop Doctor)

**Purpose:** Addendum to the existing 58-task implementation plan, based on (1) the actual Envato "Agriculture Monitoring" reference screenshots and (2) a frame-by-frame review of the current build's walkthrough recording. Primarily affects Phase 7 (Navigation & App Shell) and Phase 13 (Diagnosis Results & Guidance Presentation).
**References:** PRD · Tech Stack · Theme & Design Brief · existing Todo List (Tasks 21–23, 42–45)

---

## 1. Reference Theme — Confirmed From Actual Screenshots

The real preview images are now available; these patterns are confirmed and refine the earlier Theme & Design Brief:

- **Bottom nav is a 5-slot bar** in the reference kit: four flat tabs plus one elevated circular center button floating above the bar line, white bar, soft shadow, a white ring separating the FAB from the bar.
- **Cards:** white surface, ~16px rounded corners, soft shadow, photo-forward — a thumbnail image with a small rating/status chip overlaid on a corner.
- **Filter pills:** fully rounded; active = solid dark green fill with white text, inactive = white/outline with dark text.
- **Status chips** (e.g. "Low", "Optimal", "Deficient" on the reference's soil screen): colored dot/arrow + short label, small and inline — the same pattern this app already uses for confidence/severity.
- **Caution:** the reference kit's own category-pill labels ("Mains, Sides, Drinks, Dessert" on its field-overview screen) are leftover placeholder copy from a food-app template it was adapted from. Copy the visual pattern, never the labels, from the reference screenshots.

## 2. Current Build — Video Review Findings

Reviewed the walkthrough recording end to end. Already solid, no action needed:
- Bilingual EN/Hindi is thorough and consistent across every screen shown
- Offline-first with a visible sync-status indicator ("1 scan pending to sync")
- Uncertain-confidence handling includes a genuinely useful "why might this scan have failed" checklist
- Consult-KVK sheet has the correct, verified Kisan Call Centre number (1800-180-1551) and clear sample-submission steps
- Cloud Photo Backup defaults OFF — matches the PRD's privacy-by-default requirement

Four concrete issues found, with fixes below.

## 3. Fix 1 — Bottom Navigation: Add Search, Match Reference Polish

**Current:** Home | History | [Scan, center FAB] | Profile. There is no Search entry point anywhere in the app.

**New structure (5 slots):**

`Home  |  History  |  [ Scan — elevated center FAB ]  |  Search  |  Profile`

- Keep icon **+ text label** on all four regular tabs — do not switch to icon-only like the reference kit. Text labels matter for a low-literacy farmer audience; that was a deliberate choice in the original brief, not an oversight to "fix" now.
- Elevate the visual polish to match the reference: rounded top corners on the bar (or a fully floating rounded pill inset from the screen edges), soft shadow, white ring around the FAB separating it from the bar surface.
- **Search screen (new):** search across two sources — scan history (by crop name, disease name, or date) and the treatment knowledge base (by disease or symptom keyword). This must be a real, working destination, not an empty placeholder tab.

**Task additions (insert after existing Task 22):**

- **Task 22a — Update `MainScaffold` nav to 5 slots.** Add a Search destination between the center FAB and Profile in the `StatefulShellRoute` branches. Acceptance: all 4 tabs plus the center FAB are reachable and independently highlight when active.
- **Task 22b — Build `SearchScreen`.** One search field at top; below it, sectioned results from `HistoryService` (crop/disease/date match) and `KnowledgeBaseService` (disease/symptom match). Empty state before typing; "no results" state after. Acceptance: typing a known disease name returns matching history entries and the matching knowledge-base entry.

## 4. Fix 2 — Text Overflow (the "responsive" gap)

**Current:** On Home, the farmer's name ("Namaste, Aditya...") and village+district ("KIRWIL SONBHADRA, So...") both truncate mid-word. The same pattern cuts "Retake Photo" down to "Retake P..." on the Uncertain result screen.

**Fix:**
- Wrap the greeting name/location in `Flexible`/`Expanded` + `TextOverflow.ellipsis`, `maxLines: 1`, but size the card so realistic values (full Indian names, "village, district" pairs) fit before truncating — verify against long real values, not short test names.
- Any button holding a two-word label gets `FittedBox` or a guaranteed minimum width — a button must never truncate its own CTA text.
- Add a widget/golden test using a long name + long district string as a permanent regression guard.
- Test the same screens with Hindi strings, not only English — Devanagari text commonly runs 20–30% longer for the same meaning, so an English-only pass will miss overflow that only shows up in Hindi.
- Test at the largest Android accessibility font-scale setting, and at a small screen width (~360dp), in addition to the default preview size.

## 5. Fix 3 — Uncertain Result Screen: Duplicate Actions + a Severity Chip That Shouldn't Be There

**Current:** The Uncertain (<60% confidence) result screen shows "Retake Photo / Contact KVK" **twice** — once inline under the warning banner, once again as the sticky bottom bar. It also shows a "Medium Severity" chip next to "Uncertain (8%)".

**Fix (updates existing Task 44):**
- Remove the inline duplicate action row entirely; keep only the sticky bottom "Retake Photo / Contact KVK" pair.
- Suppress the Severity chip completely when the confidence category is Uncertain — severity is derived from a disease guess the screen has just said it doesn't trust, so showing it undercuts the "we're not sure" message. Severity should render only for Likely/Possible results.

## 6. Fix 4 — Verify Recent Scans Refreshes on Home

Worth an explicit check, not yet confirmed as a bug: does Home's "Recent Scans" list update immediately after a scan is saved, or only after a manual refresh or app restart? Add as a test case in Task 56/58.

## 7. Responsiveness Checklist (apply app-wide, not only to the screens above)

- No fixed-width `Text` holding user-generated or localized content without `Flexible`/`Expanded` and overflow handling
- Check both English and Hindi copy on every screen, not just one language
- Check at the largest system font-scale (accessibility setting)
- Check on a small-width device (~360dp) and a large one (~428dp) — nav bar and cards should neither overflow nor leave awkward gaps
- Re-run the existing Task 57 accessibility/touch-target audit after the nav bar change, since the FAB and its neighboring tabs are now the tightest touch-target area in the app
