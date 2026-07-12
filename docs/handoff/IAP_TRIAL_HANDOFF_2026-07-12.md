# Handoff: Full Access IAP — 7-Day Free Trial on Annual (iOS, 2026-07-12)

Audience: dev handling the Android conversion. This documents the monetization model as now implemented on iOS, so the Android build matches product behaviour — not the iOS APIs.

## 1. Product model (platform-agnostic — replicate exactly)

**Free tier is deliberately thin and unchanged:**
- The **first Daily Fit a user ever reveals is free**, permanently, for that calendar day only. Every other day's Daily Fit is gated behind a "torn paper" teaser: content is cut off at a tear, with a CTA block over a glyph background.
- The **Style Guide is always gated** for free users (same torn-paper treatment).
- No other free days, no metered trial of content.

**Paid tier ("Full Access")** — one subscription group, two auto-renewing plans:

| Plan | Product ID (iOS) | Period | Price | Intro offer |
|---|---|---|---|---|
| Monthly | `com.cosmicfit.full.monthly` | 1 month | £7.99 / $7.99 | none |
| Annual | `com.cosmicfit.full.annual` | 1 year | £49.99 / $49.99 | **7-day free trial** |

**How the trial works (critical framing — all copy must match):**
1. User taps **"Start Free Week"** on the annual plan.
2. They get full paid access for 7 days, charged **nothing**.
3. On day 7, unless cancelled, the store charges the annual price once.
4. The paid year runs from trial end. Never frame it as "pay up front, get 7 free days".

**Eligibility:** one trial per user across the subscription group, enforced by the store (Apple: per subscription group; Google: offer eligibility on the base plan). Users who already consumed a trial or previously subscribed see the standard non-trial paywall. **Always fail closed**: if eligibility/offer data can't be determined (products not loaded, network, no offer configured), show non-trial copy — the paywall then behaves byte-identically to the pre-trial app.

**Entitlement rule:** `hasFullAccess = activeStoreSubscription(either product) || validCompGrant`. Trial-period transactions count as an active subscription — **no special-casing of trials anywhere in gating**. Comp grants are promo codes redeemed via Supabase edge functions (`redeem-code` / `check-comp-access` / `revoke-comp-access`), keyed by a client install identity and stored in secure local storage (iOS: Keychain). Android needs the same comp path if promo codes are in scope.

## 2. Copy (exact strings, share across platforms)

| Surface | Trial-eligible | Not eligible / monthly |
|---|---|---|
| Daily Fit teaser button | `Try 7 Days Free` | `Unlock Your Daily Fit` |
| Style Guide teaser button | `Try 7 Days Free` | `Unlock Your Style Guide` |
| Paywall annual card | `7 days free, then <price>/year` | `<price>/year` |
| Paywall monthly card | `<price>/month` (always) | same |
| Paywall CTA (annual selected) | `Start Free Week` | `Subscribe Now` |
| Paywall CTA (monthly selected) | `Subscribe Now` | `Subscribe Now` |
| Annual card badge | `Save <n>%` where n = (12×monthly − annual) / (12×monthly) × 100, from live store prices (currently 47%) | same |

Trial disclosure appended **before** the standard auto-renew disclosure when eligible:

> Annual plan starts with a 7-day free trial. You will not be charged until the trial ends; £49.99/year is then charged unless you cancel at least 24 hours before the trial ends.

Standard disclosure (always shown):

> Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in Settings.

Notes: durations are **derived from the store's offer object**, not hardcoded — a 1-week offer renders as "7 days"/"7-day"; if the offer were ever reconfigured (e.g. 1 month), copy follows automatically, and non-1-week trials use CTA fallback `Start Free Trial`. Replicate this derivation on Android (Play's `pricingPhases` gives ISO-8601 periods like `P1W`).

## 3. iOS implementation map (for reference / behaviour parity)

- `Cosmic Fit/Core/Services/StoreKitManager.swift` — StoreKit 2 singleton. New intro-offer section (~lines 111–166): `annualFreeTrialOffer` (only returns offers with `paymentMode == .freeTrial`), `annualTrialIsOneWeek`, duration formatters `trialDurationText` / `trialDurationAdjective` (pure statics, unit-tested), `isEligibleForAnnualIntroOffer()` (async, store-tracked, fails closed). **No eligibility caching** — refetched per paywall/teaser presentation because it flips after a trial purchase or restore.
- `Cosmic Fit/Core/Services/EntitlementManager.swift` — untouched. Recomputes entitlement from live store state on every launch/transaction update; nothing persisted for the store path. Posts `CosmicFitEntitlementDidChange`; all gated screens re-render on it (this is how UI unlocks mid-session after purchase).
- `Cosmic Fit/UI/ViewControllers/PurchaseViewController.swift` — paywall. `showTrialOffer` state set once per presentation from the eligibility fetch; card copy / CTA / disclosure all derive from it. Also fixed: CTA title no longer force-resets to "Subscribe Now" after a cancelled/failed purchase, and the price label got a leading constraint + autoshrink for the longer trial string.
- `DailyFitViewController.swift` (`configureRestrictedUnlockButton()`) and `StyleGuideDetailViewController.swift` (`setupGatedCTA()`) — each fires an async eligibility check at gated-layout setup and swaps the button title to `Try 7 Days Free` only on a confirmed-eligible, one-week offer.
- `Cosmic FitTests/TrialCopyTests.swift` — 4 passing tests on the duration formatters.
- `Cosmic Fit.storekit` (repo root) + shared scheme `Cosmic Fit.xcodeproj/xcshareddata/xcschemes/Cosmic Fit.xcscheme` — local store config for simulator testing only (Run action only; never ships). At repo root because the Xcode project is file-system-synchronized and anything under `Cosmic Fit/` auto-bundles.

## 4. Store configuration state

- **App Store Connect (done 2026-07-12):** both products in one group; introductory offer on annual = Free, first week, 175 territories, no end date. Some metadata still flagged missing (localizations / review screenshot) — must be cleared before submission; while flagged, sandbox may return zero products.
- **Google Play equivalent (to do):** one subscription with two base plans (monthly P1M, annual P1Y), plus an **offer on the annual base plan**: single free pricing phase, `P1W`, eligibility "new customer acquisition" (never had this subscription) to mirror Apple's once-per-group rule. Play Billing surfaces it via `SubscriptionOfferDetails.pricingPhases`; "eligibility" on Android = whether Play returns the offer for this user, so the same fail-closed rule applies naturally.

## 5. Behavioural edge cases the Android build must preserve

- Eligibility false / unknown / slow → standard non-trial UI everywhere (teasers keep "Unlock…" copy; no spinner waiting on eligibility).
- Purchase pending (Ask to Buy / parental approval) → inform user ("Your purchase is waiting for approval."), restore correct CTA title, do not unlock.
- Cancelled purchase → paywall unchanged, correct CTA title restored.
- Restore purchases → recheck entitlement; a restored subscription (including one still in trial) unlocks; a user who restores nothing keeps non-trial or trial copy per store eligibility.
- Comp-grant users have full access and never see teasers/paywall — trial logic never interacts with comp logic.
- Trial→paid conversion requires no app-side handling: it's just the subscription continuing.

## 6. Status / pending on iOS

Code complete, builds, unit tests pass. Pending: manual simulator pass with the local store config (trial sheet shows $0 due today; accelerated renewal converts trial→paid; ineligible fallback), then a device sandbox pass with the scheme's StoreKit config set back to None, ASC metadata completion, and commit (work is uncommitted on `refactor/style-guide` as of this handoff).
