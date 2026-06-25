# Legal Production Audit — Handoff

**Date:** 2026-06-25  
**Status:** Legal copy updated (app + web aligned); supporting app/backend changes implemented and reviewed; edge function needs deploy before account deletion works in production  
**Source audit:** [legal-production-audit.canvas.tsx](/Users/ash/.cursor/projects/Users-ash-dev-mobile-apps-cosmicfit/canvases/legal-production-audit.canvas.tsx)  
**Trigger:** User requested ingestion of Legal Production Audit canvas and amendment of Privacy Policy and Terms of Use in both app and HTML forms so text is identical.

---

## Goal

Bring Cosmic Fit’s Privacy Policy and Terms of Use to production-ready alignment with:

1. Observed app/backend behaviour (data collection, sync, deletion, third parties)
2. UK entity framing (**THIS IS BULLISH LTD.**)
3. Comparable astrology-app legal patterns from the audit
4. App Store expectations (account deletion, accurate permission strings)

App Swift sources and web HTML must say the **same thing** (web is formatted for browsers; app uses `LegalDocumentViewController`).

---

## What Was Amended (Legal Text)

### Shared sources (must stay in sync)

| App (Swift) | Web (HTML) |
|-------------|------------|
| `Cosmic Fit/Legal/PrivacyPolicyContent.swift` | `web/privacy/index.html` |
| `Cosmic Fit/Legal/TermsOfUseContent.swift` | `web/terms/index.html` |

Effective / last updated date on both docs: **June 25, 2026**.

There is **no code generator** linking Swift ↔ HTML; edits were applied manually to all four files. Any future legal change must touch all four.

---

### Privacy Policy changes

#### Entity and jurisdiction

- Introduction names **THIS IS BULLISH LTD.** as operator of Cosmic Fit (cosmicfit.app).
- Contact Us names THIS IS BULLISH LTD.
- International Transfer: based in **United Kingdom** (was United States).
- **No registered address** added (user requested omission until confirmed).

#### Section 2 — Collection

- **Style Guide vs Daily Fit sync:** Split into two bullets. Style Guide may sync to cloud when signed in; **Daily Fit is stored locally only and is not currently synced to cloud.**
- **Local storage:** Explicit list — profile JSON, Style Guide blueprint, Daily Fit frozen payloads, UserDefaults location cache, UI preferences, reveal flags.
- **Current location / weather:** Discloses approximate lat/long cached on device for Daily Fit weather (not advertising).
- **App Store payments:** Apple only (Google Play references removed).

#### Section 4 — Disclosure

- Added **Open-Meteo** as service provider when approximate coordinates are sent for weather.

#### Section 5 — Third parties

- **Open-Meteo** paragraph (open-meteo.com, weather for Daily Fit).
- **Apple MapKit** paragraph (birth-location search / geocoding via `MKLocalSearchCompleter` / `MKLocalSearch`).
- **Apple App Store** only for subscriptions (Google Play removed).

#### Section 7 — Your privacy choices

- **Local profile deletion:** Describes removal of profile, Style Guide, Daily Fit cache, location cache, preferences.
- **Keychain preserved:** Deleting local profile does **not** remove device install identifier or promotional access grants in Keychain.
- **Cloud deletion:** Signed-in users can delete account **in the app**; email fallback at help@cosmicfit.app.
- **Subscriptions:** Apple account settings only; deletion does not cancel App Store billing.

#### Section 8 — Children

- UK GDPR / Data Protection Act 2018 (replaced COPPA reference).

#### Section 10 — Retention

- Category-level retention: OTP/rate-limit windows, synced profile/Style Guide, subscription ledgers, promo redemption records, server logs.

#### Section 14 — United Kingdom (replaced U.S. state disclosures)

- Controller: THIS IS BULLISH LTD.
- UK GDPR rights, no sale/sharing for targeted advertising, ICO complaint route.

#### Section 15 — EEA and Switzerland

- UK removed from this section (now section 14); covers EEA/Switzerland only.

---

### Terms of Use changes

#### Entity

- New intro line: *Cosmic Fit is operated by THIS IS BULLISH LTD.*
- Company definition: THIS IS BULLISH LTD., which operates Cosmic Fit (cosmicfit.app).
- Contact and web footers: © THIS IS BULLISH LTD.

#### Section ii — Definitions

- App Store = **Apple App Store** only (Google Play removed).

#### Section iv.B — Accounts

- In-app account deletion described; email fallback.

#### Section iv.D — Subscriptions

- Apple App Store only throughout.
- Promo-code terms strengthened (no cash value, non-transferable, per user/device/install limits, revocation for misuse/fraud/etc.).

#### Section v.B — Your information

- Local profile deletion does **not** automatically delete cloud data or cancel subscriptions.

#### Section vi.B — Assumptions of risk

- **No-emergency disclaimer** added (not for medical/mental-health crises; contact emergency services).

#### Section vi.F — Disputes / arbitration

- UK framing: Arbitration Act 1996, CEDR, County Court of England and Wales small claims track, courts of England and Wales, laws of England and Wales.
- Collective proceedings waiver (replaced US jury trial / class action language).

#### Section vii — UK consumers (replaced California notice)

- Consumer Rights Act 2015; Citizens Advice and CMA references.

#### Copyright complaints

- Removed US “penalty of perjury”; uses UK “authorised” wording.

---

## Why Code Was Changed (Not Just Legal Text)

The re-audit after legal amendments found **concrete mismatches** between policy copy and implementation. User initially wanted text-only updates; follow-up work implemented matching behaviour where the audit required it.

| Audit finding | Resolution |
|---------------|------------|
| Policy said local deletion clears Style Guide / Daily Fit / location cache, but code only removed profile file + some DailyVibe keys | Implemented `clearLocalUserGeneratedContent()` |
| Policy said users can request cloud deletion by email; App Store expects in-app path when accounts exist | Added Delete Account UI + `delete-account` edge function |
| `NSLocationWhenInUseUsageDescription` said birth location; code uses current location for weather | Updated Info.plist string in `project.pbxproj` |
| Daily Fit described as cloud-synced | Legal text corrected; no Daily Fit cloud sync added |

---

## App / Backend Code Changes

### `UserProfileStorage.swift`

- **`deleteUserProfile()`** now calls **`clearLocalUserGeneratedContent()`**.
- **`clearLocalUserGeneratedContent()`** removes:
  - Profile file + legacy UserDefaults profile key
  - DailyVibe UserDefaults keys for that profile id
  - `BlueprintStorage.shared.delete()`
  - `DailyFitFrozenPayloadStorage.shared.removeAll()` (files + reveal/slider flags)
  - `LocationManager.shared.clearCachedLocation()`
  - Masculine/feminine slider preference key
  - Bumps `BlueprintStorage.remoteBlueprintPullEpoch` on MainActor
- **Does not clear:** Keychain install ID (`ClientInstallIdentity`), `CompAccessStorage` promo grants, welcome flag, auth keys.

### `LocationManager.swift`

- Added **`clearCachedLocation()`** — clears in-memory location and UserDefaults keys `CachedLocationLatitude`, `CachedLocationLongitude`, `CachedLocationTimestamp`, `CachedLocationAccuracy`.

### `DailyFitFrozenPayloadStorage.swift`

- **`removeAll()`** now also calls **`clearRevealAndSliderFlags()`** (prefixes `CardRevealed_`, `SliderEntrancePlayed_`).
- **`clearRevealAndSliderFlags()`** added as public method.

### `CosmicFitAuthService.swift`

- **`deleteAccount()`** added:
  1. POST to edge function `delete-account` with `{}` body
  2. On success: `try? await supabase.auth.signOut()` (must be `try?` — user already deleted server-side; strict `try` would show false error)
  3. `clearState(clearLocal: true)`, `clearAccountEmail()`, `clearLastUserId()`
  4. `UserProfileStorage.shared.clearLocalUserGeneratedContent()`
- **`purgeLocalUserData()`** (different user sign-in) now calls `clearLocalUserGeneratedContent()` instead of duplicate profile + blueprint deletes.

### `ProfileViewController.swift`

- **`deleteAccountButton`** — visible when signed in; **Delete profile** hidden when signed in.
- **`deleteAccount()`** — async flow with activity indicator, error alert with help@cosmicfit.app fallback, success → `navigateToOnboarding()`.
- **`navigateToOnboarding()`** — extracted shared navigation after profile/account deletion.
- **`updateAuthUI()`** called from `viewDidLoad` for correct initial button visibility.
- **`deleteButtonTapped`** — uses `[weak self]` in alert action.

### `SignedOutLandingViewController.swift`

- **`performStartFresh()`** — removed redundant `BlueprintStorage.shared.delete()` after `deleteUserProfile()` (blueprint already cleared inside `clearLocalUserGeneratedContent()`).

### `Cosmic Fit.xcodeproj/project.pbxproj`

- **`INFOPLIST_KEY_NSLocationWhenInUseUsageDescription`** (Debug + Release):
  - *"Your location is used for Daily Fit weather features and related calculations based on where you are now."*

### `supabase/functions/delete-account/index.ts` (NEW — not deployed by this handoff)

- Authenticates user via JWT (`createUserClient`).
- Rate limit: 3 requests/hour per user id.
- **`svc.auth.admin.deleteUser(user.id)`** — cascades to `profiles`, `user_preferences`, `user_blueprints` via `ON DELETE CASCADE` on `auth.users` (see `001_initial_schema.sql`).
- Returns `{ success: true }`.
- Promo/subscription audit tables may retain records per retention policy (not deleted by user cascade — verify if needed).

---

## Post-Implementation Review Fixes (Same Conversation)

These were found during user-requested code review and **fixed**:

1. **`deleteAccount()` critical bug:** `try await signOut()` after server-side user deletion could throw and show “Could Not Delete Account” even when deletion succeeded → changed to `try?` + explicit `clearState(clearLocal: true)`.
2. **Double blueprint delete** in `SignedOutLandingViewController.performStartFresh()` → removed duplicate call.
3. **Strong self** in delete-profile alert → `[weak self]`.
4. **Re-enabling buttons** on successful account delete before window transition → removed on success path.

---

## Files Touched (Summary)

### Legal / web

```
M Cosmic Fit/Legal/PrivacyPolicyContent.swift
M Cosmic Fit/Legal/TermsOfUseContent.swift
M web/privacy/index.html
M web/terms/index.html
```

### App / backend

```
M Cosmic Fit/Core/Utilities/UserProfileStorage.swift
M Cosmic Fit/Core/Utilities/LocationManager.swift
M Cosmic Fit/Core/Utilities/DailyFitFrozenPayloadStorage.swift
M Cosmic Fit/Core/Services/CosmicFitAuthService.swift
M Cosmic Fit/UI/ViewControllers/ProfileViewController.swift
M Cosmic Fit/UI/ViewControllers/SignedOutLandingViewController.swift
M Cosmic Fit.xcodeproj/project.pbxproj
A supabase/functions/delete-account/index.ts
```

### Reference (not modified)

```
canvases/legal-production-audit.canvas.tsx  (Cursor canvas — audit source)
```

---

## Deployment & Verification Checklist

### Required before production

1. **Deploy edge function:**
   ```bash
   supabase functions deploy delete-account
   ```
2. **Deploy web legal pages** (`web/privacy/index.html`, `web/terms/index.html`) to cosmicfit.app hosting.
3. **Ship app build** with updated legal Swift content and Info.plist location string.

### Manual test plan

| Scenario | Expected |
|----------|----------|
| Signed out → Delete profile | Local data cleared; onboarding; Keychain install ID + comp grant remain |
| Signed in → Delete account (function deployed) | Cloud user deleted; local data cleared; onboarding; no false error alert |
| Signed in → Delete account (function NOT deployed) | Error alert; account still exists |
| Sign out | Local profile/data **retained** (by design — only auth state cleared) |
| Birth location search | MapKit still works; policy discloses Apple |
| Location permission prompt | New string about Daily Fit weather / current location |
| Restore purchases / subscription | Still Apple-only flows |

### Legal / product items still open

| Item | Notes |
|------|--------|
| **Registered address** | User said entity is THIS IS BULLISH LTD.; address omitted for now. Add to Contact Us / intro when confirmed. |
| **Counsel review** | UK arbitration, CEDR, entity/jurisdiction — recommended before treating as “watertight”. |
| **Promo/subscription retention on account delete** | Policy says some records may be retained; edge function only deletes auth user (cascade). Confirm whether `promo_redemptions` etc. need explicit handling. |
| **Android / Google Play** | All Google Play references removed from legal text; app is iOS-focused. Re-add if Android ships. |

---

## Architecture Notes for Pick-Up Dev

### Legal document rendering

- App: `PrivacyPolicyViewController` / `TermsOfUseViewController` → `LegalDocumentViewController` reads `PrivacyPolicyContent.configuration` / `TermsOfUseContent.configuration`.
- Inline links: `LegalDocumentLink` phrases (e.g. help@cosmicfit.app, Terms of Use URL).
- Web: static HTML with `web/shared/legal.css`.

### Delete profile vs delete account

| Action | Auth | Cloud | Local user content | Keychain install / comp |
|--------|------|-------|--------------------|-------------------------|
| Delete profile | Unchanged | Unchanged | Cleared via `clearLocalUserGeneratedContent()` | Preserved |
| Delete account | Signed out | User deleted via Supabase Admin API | Cleared via same helper | Preserved |
| Sign out | Signed out | Unchanged | **Not** cleared | Preserved |

### Cloud sync scope (actual behaviour)

- **Synced when signed in:** `profiles` table, `user_blueprints` (Style Guide JSON) via `SupabaseSyncService`.
- **Local only:** Daily Fit frozen payloads (`DailyFitFrozenPayloadStorage`), reveal flags, most UserDefaults prefs.
- Legal text now matches this split.

### Location usage (two distinct purposes)

1. **Birth location** — user-selected via MapKit autocomplete during onboarding/profile (not device GPS for that flow).
2. **Current device location** — `LocationManager` at launch / Daily Fit for weather via Open-Meteo.

Permission string now describes (2). MapKit disclosed for (1) search.

---

## Suggested Next Steps

1. Deploy `delete-account` and run signed-in deletion on a test account in staging/production.
2. Confirm registered address with user/counsel and add to legal docs if required.
3. Optional: add unit test for `clearLocalUserGeneratedContent()` verifying files/keys removed and Keychain untouched.
4. Optional: consolidate “start fresh” paths (`SignedOutLandingViewController`, auth purge) to always use `clearLocalUserGeneratedContent()` + explicit auth key clears only.
5. If legal text changes again, update **all four** files and re-run a quick diff between Swift paragraph strings and HTML body text.

---

## Conversation Arc (For Context)

1. Ingest Legal Production Audit canvas → amend Privacy + Terms (app + web).
2. User confirmed entity: **THIS IS BULLISH LTD.** (no address).
3. User requested UK equivalents (replace California/US arbitration, COPPA, California notice, etc.).
4. Re-audit identified policy/code mismatches → legal text updates **plus** local cleanup, MapKit disclosure, Apple-only store refs, location plist string, in-app account deletion.
5. User flagged unintended code changes → full code review, bug fixes on `deleteAccount()` signOut path and minor cleanup.

This handoff reflects the state after step 5.
