# In-App Purchase — Implementation Handoff

## Goal

Add auto-renewable subscription products to Cosmic Fit so users can unlock the full app experience. Free users get a meaningful taste of the product (today's Daily Fit + Style Core + Palette sections of the Style Guide). Subscribers unlock tomorrow's Daily Fit and all eight Style Guide sections.

**Out of scope for this release**: The calendar timeline feature (accessed via the calendar button on the Daily Fit header) is a future feature. It is **not** part of this subscription unlock. The calendar button is hidden entirely for this release (see Daily Fit gating section below). Do not build calendar functionality.

## Products

Two auto-renewable subscriptions in a single **Subscription Group** (Apple mandates that mutually exclusive durations live in the same group so the user can only hold one active subscription at a time):

| Product ID                         | Duration | UK Price | Display                  |
| ---------------------------------- | -------- | -------- | ------------------------ |
| `com.cosmicfit.full.monthly` | 1 month  | £7.99    | "£7.99/month"            |
| `com.cosmicfit.full.annual`  | 1 year   | £49.99   | "£49.99/year — Save 48%" |

**Savings copy**: Monthly × 12 = £95.88. Annual = £49.99. Saving = £45.89, which is **48%** when rounded to the nearest whole percent (45.89 ÷ 95.88 ≈ 47.9%). Display this as **"Save 48%"** next to the annual option. The actual displayed price and savings label must use the localised `Product.displayPrice` from StoreKit so it renders correctly in every currency; the **percentage must still be computed in code** from `Product.price` values (do not hardcode `48` for non-UK storefronts).

### Product Type (resolved)

Products were originally created in App Store Connect as **Consumable**. These were deleted and replaced with **Auto-Renewable Subscriptions** inside a **Subscription Group** ("Cosmic Fit Full Access"). The original `fullaccess` product IDs could not be reused; the current IDs are `com.cosmicfit.full.monthly` and `com.cosmicfit.full.annual`, referenced only via constants in `StoreKitManager`.

No StoreKit 1 or consumable-specific code was ever in the Swift codebase (the app launched with StoreKit 2). No legacy cleanup was needed beyond the App Store Connect product-type change.

### Subscription Group Setup in App Store Connect

1. Go to **Monetization > Subscriptions** (not In-App Purchases)
2. Create a **Subscription Group**: "Cosmic Fit Full Access"
3. Add two subscriptions within that group:
   - Monthly: Reference Name "Monthly Full Access", Product ID `com.cosmicfit.full.monthly`, Duration 1 Month, Price Tier = £7.99
   - Annual: Reference Name "Annual Full Access", Product ID `com.cosmicfit.full.annual`, Duration 1 Year, Price Tier = £49.99
4. For each subscription, add localisation (Display Name, Description)
5. Add a review screenshot before submission (can be deferred until the purchase UI is built)

## Deployment Target

iOS 18.4. StoreKit 2 (Swift-native `StoreKit` framework) is fully supported. Use StoreKit 2 exclusively — do not use the legacy `SKProduct`/`SKPaymentQueue` APIs.

## Branch

All implementation work lives on the `products` git branch (already created from `main`). Commit regularly with clear messages. Do not merge to `main` until the full feature is tested.

---

## Apple ID vs Cosmic Fit account — restore, persistence, auth (implementer MUST follow)

This section is **normative** for the implementation. It prevents accidental coupling of Supabase auth with App Store entitlements and ensures recovery behaviour matches Apple’s model and review expectations.

### Two parallel identities (do not conflate)

| Identity                                | Role                                                                                                               | Who owns it           |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | --------------------- |
| **App Store / Apple ID**                | Pays for the subscription; StoreKit exposes entitlements for the Apple ID signed into the App Store on this device | Apple                 |
| **Cosmic Fit user (guest or Supabase)** | Syncs blueprint/profile data across devices when signed in                                                         | Cosmic Fit + Supabase |

**Purchasing does not require** Cosmic Fit sign-in. **Entitlement must not** be stored in or read from Supabase, UserDefaults keyed by user id, or any server flag in v1. The subscription is **not** “attached” to an email address in your backend for unlocking the app.

### Source of truth (v1)

- **`EntitlementManager.checkEntitlement()`** resolves `hasFullAccess` **only** from StoreKit 2: verified transactions in `Transaction.currentEntitlements` for the known product IDs, per the existing spec (active / grace via Apple’s rules; expired or revoked → no access).
- **`StoreKitManager.restorePurchases()`** calls `AppStore.sync()`, then **`await EntitlementManager.shared.checkEntitlement()`** — same code path whether invoked from the paywall or from Profile.

**Forbidden:** setting `hasFullAccess` from `CosmicFitAuthService.shared.isAuthenticated`, profile payloads, or any API response. **Forbidden:** persisting “isSubscribed” to Supabase or local storage as the authority for gating (caching StoreKit output for UX is unnecessary in v1; if you ever add caching, it must still be refreshed from StoreKit on launch and after transactions).

### New install, reinstall, same Apple ID (explicit behaviour)

1. User installs the app (new or reinstall), completes onboarding. Local birth/profile data is created/stored as today — **unchanged** by this feature.
2. On launch, **`checkEntitlement()`** runs. If this device’s App Store account has an **active** subscription for your product IDs, **`hasFullAccess`** becomes `true` **without** the user opening the purchase screen and **without** Cosmic Fit sign-in.
3. If the user is subscribed but entitlements are not yet visible (e.g. rare timing, network), they can use **Restore** (paywall or Profile) which triggers `AppStore.sync()` and then `checkEntitlement()`.

Document for QA: **same Apple ID** after reinstall should recover access automatically or via Restore; **different Apple ID** cannot “inherit” a subscription from another Apple account (Apple limitation — not a bug).

### Restore purchases — TWO entry points (required)

Apple requires a visible, functional **Restore** affordance; reviewers and users also expect it **outside** the paywall.

| Location                     | Requirement                                                                                                                                                                                                                                                                       |
| ---------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **`PurchaseViewController`** | Keep **“Already subscribed? Restore”** as specified (calls `StoreKitManager.shared.restorePurchases()`).                                                                                                                                                                          |
| **`ProfileViewController`**  | Add a dedicated row/control: **“Restore purchases”** (copy may be title case per app style). **Always visible** to all users (guest and signed-in). Tapping it must call the **same** `StoreKitManager.shared.restorePurchases()` as the paywall — do not duplicate logic inline. |

**UX for both entry points:**

- Disable the control or show a blocking progress indicator while `restorePurchases()` / sync is in flight; re-enable on completion.
- On completion, UI already updates via `checkEntitlement()` + `entitlementDidChange`; optionally show a lightweight confirmation: e.g. if `hasFullAccess` became `true`, brief success message; if still `false`, neutral copy such as **“No active subscription found for this Apple ID.”** (Avoid promising a refund or support resolution in-app.)
- Errors (network, StoreKit): show a clear alert or inline message; do not crash.

**Optional but recommended** on Profile (same area as Restore): a **“Manage subscription”** control that opens `https://apps.apple.com/account/subscriptions` via `UIApplication.shared.open`. This complements the auto-renewal copy on the paywall and reduces support friction. Not a substitute for Restore.

### Sign-in, sign-out, and entitlement (explicit rules)

| Event                                      | Required behaviour                                                                                                                                                                                                                                                                       |
| ------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **User signs in**                          | Do **not** grant or revoke subscription based on login. After successful auth (and any existing blueprint hydration), you may call **`await EntitlementManager.shared.checkEntitlement()`** to refresh from StoreKit (usually unchanged). **Never** set `hasFullAccess` from auth state. |
| **User signs out**                         | Do **not** clear `hasFullAccess` or reset subscription UI solely because `isAuthenticated` became false. Subscription belongs to the **Apple ID**, not the Cosmic Fit session. Locks must reflect StoreKit only.                                                                         |
| **`handleAuthStateChanged` / tab refresh** | Continue to refresh nudge banner, Profile buttons, and hydration as today. **Do not** remove or bypass StoreKit when updating UI after auth changes.                                                                                                                                     |

**Journey — guest subscribes, then signs in:** Same device, same Apple ID → remains subscribed; sign-in only affects sync. **Journey — signed-in user signs out:** If their Apple ID still has a valid subscription, **paid content stays unlocked** until StoreKit says otherwise.

### Account deletion vs App Store subscription (required product/engineering note)

If the app offers **account deletion** (Supabase / Cosmic Fit profile deletion):

- **Deleting a Cosmic Fit account does NOT cancel** an App Store subscription. The user must cancel in **Settings → Apple ID → Subscriptions** (or the manage-subscriptions URL above).
- Spec copy for support/legal (and optionally in-account deletion confirmation): make clear that **billing continues until they cancel with Apple**, and that **reinstalling** and signing in with the **same Apple ID** can still unlock features via StoreKit even after profile deletion, as long as the subscription is active.
- Implementation: deleting server-side user data **must not** delete or corrupt local StoreKit state; do not “fake” revoke `hasFullAccess` on account deletion. After deletion, `checkEntitlement()` should still reflect Apple’s entitlements for the current Apple ID.

If account deletion is **not** in this release, still **do not** tie entitlement revocation to sign-out or profile removal in a way that contradicts StoreKit.

### Onboarding and “local user”

Onboarding continues to collect birth data and build the experience **locally** first. IAP does not change that: free tier and purchase flows work for **guests**. Nothing in this document requires creating a Supabase row before purchase.

---

## Architecture Overview

### New Files to Create

| File                                                | Purpose                                                                |
| --------------------------------------------------- | ---------------------------------------------------------------------- |
| `Cosmic Fit/Core/Services/StoreKitManager.swift`    | StoreKit 2 product loading, purchasing, transaction listening, restore |
| `Cosmic Fit/Core/Services/EntitlementManager.swift` | Single source of truth for subscription state; consumed by all UI      |

### Existing Files to Modify

| File                                                                      | Changes                                                                                                                                                                                                                                                                                                           |
| ------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `AppDelegate.swift`                                                       | Boot `EntitlementManager` + `StoreKitManager` transaction listener on launch; change landing tab to 0                                                                                                                                                                                                             |
| `PaymentPlaceholderViewController.swift`                                  | Convert from static placeholder to live subscription purchase screen; rename to `PurchaseViewController.swift`                                                                                                                                                                                                    |
| `DailyFitViewController.swift`                                            | Gate tomorrow button behind entitlement; hide calendar button; observe entitlement changes                                                                                                                                                                                                                        |
| `StyleGuideViewController.swift`                                          | Gate 6 of 8 section tiles behind entitlement; add lock visual state to `StyleGuideGridButton`; observe entitlement changes                                                                                                                                                                                        |
| `CosmicFitTabBarController.swift`                                         | Always show `DailyFitViewController` on tab 0 (remove auth gate swap); observe entitlement changes                                                                                                                                                                                                                |
| `OnboardingFormViewController.swift`                                      | Change post-onboarding landing tab from `selectedIndex = 1` to `selectedIndex = 0`                                                                                                                                                                                                                                |
| `ProfileViewController.swift`                                             | Add "Sign in to sync" for guests; add **always-visible "Restore purchases"** (same `StoreKitManager.restorePurchases()` as paywall); optional **"Manage subscription"** link to Apple’s subscriptions URL; update sign-out alert copy; **do not** tie entitlement to auth state (see Apple ID vs account section) |
| `AuthNudgeBannerView.swift` / handler in `StyleGuideViewController.swift` | Change tap handler from tab-switch to modal presentation of `AuthGateViewController`                                                                                                                                                                                                                              |
| `DebugConfiguration.swift`                                                | Add `overrideEntitlementUnlocked` flag                                                                                                                                                                                                                                                                            |

### No StoreKit Configuration File

Xcode's StoreKit Configuration File (`*.storekit`) is an optional local testing tool. If it does not appear in `File > New > File…` templates (search "StoreKit" in the template filter), this is likely because the project does not yet have the StoreKit framework linked, or the Xcode version in use does not surface it prominently. It is **not required**. Testing can be done entirely via **Sandbox accounts** in App Store Connect (see Testing section below). If it becomes available later, it can be added for convenience but is not a blocker.

---

## `StoreKitManager.swift` — Specification

```swift
import StoreKit

@MainActor
final class StoreKitManager {
    static let shared = StoreKitManager()

    private(set) var monthlyProduct: Product?
    private(set) var annualProduct: Product?

    private var transactionListener: Task<Void, Error>?

    static let monthlyProductID = "com.cosmicfit.full.monthly"
    static let annualProductID = "com.cosmicfit.full.annual"

    private init() {}
}
```

### Required methods

**`loadProducts()`** — Calls `Product.products(for:)` with both product IDs. Stores them on `monthlyProduct` / `annualProduct`. Log errors if products are empty (means App Store Connect is misconfigured or IDs don't match).

**`purchase(_ product: Product)`** — Calls `product.purchase()`. Handles the result:

- `.success(.verified(let transaction))`: call `transaction.finish()`, then `EntitlementManager.shared.checkEntitlement()`.
- `.success(.unverified(_, let error))`: log error, do not grant access.
- `.userCancelled`: no-op.
- `.pending`: inform the user that the purchase is pending approval (e.g. Ask to Buy).

**`restorePurchases()`** — Calls `AppStore.sync()`. After completion, call `EntitlementManager.shared.checkEntitlement()`. This is the **single** implementation used by **both** the purchase screen’s restore control **and** Profile’s **“Restore purchases”** row (required: two UI entry points, one method — see Apple ID vs account section).

**`listenForTransactions()`** — Starts a long-running `Task` that iterates `Transaction.updates`. For each verified transaction, finishes it and refreshes entitlement. Called once from `AppDelegate` at launch.

### Savings percentage helper

Expose a computed property or method that calculates the savings percentage dynamically from the two `Product.price` values:

```swift
var annualSavingsPercent: Int? {
    guard let monthly = monthlyProduct, let annual = annualProduct else { return nil }
    let yearlyAtMonthly = monthly.price * 12
    guard yearlyAtMonthly > 0 else { return nil }
    let savings = (yearlyAtMonthly - annual.price) / yearlyAtMonthly * 100
    return Int(savings.rounded())
}
```

---

## `EntitlementManager.swift` — Specification

```swift
import StoreKit

@MainActor
final class EntitlementManager {
    static let shared = EntitlementManager()

    private(set) var hasFullAccess: Bool = false

    /// Posted when entitlement state changes so UI can react.
    static let entitlementDidChange = Notification.Name("CosmicFitEntitlementDidChange")

    private init() {}
}
```

### Required methods

**`checkEntitlement()`** — Iterates `Transaction.currentEntitlements`. For each verified transaction matching one of the two product IDs, check the subscription status:

- **Active** (`transaction.revocationDate == nil`): set `hasFullAccess = true`.
- **Grace period / billing retry**: StoreKit 2 continues to include the subscription in `currentEntitlements` during Apple's billing retry window (up to 60 days). `hasFullAccess` remains `true` automatically — no special handling needed. The user keeps access while Apple retries billing.
- **Expired / revoked**: the transaction will no longer appear in `currentEntitlements`. `hasFullAccess = false`.
- **No matching transactions at all**: `hasFullAccess = false`.

Posts `entitlementDidChange` notification only when `hasFullAccess` actually changes value (compare old vs new before posting to avoid spurious UI refreshes).

**Important**: `checkEntitlement()` is the single source of truth. No other code should directly set `hasFullAccess`. Every path that may change entitlement state (purchase, restore from paywall **or Profile**, transaction listener, app launch) must funnel through this method.

**Auth lifecycle (non-source of truth):** Sign-in and sign-out **must not** set `hasFullAccess` from `CosmicFitAuthService`. Optionally invoke `checkEntitlement()` after auth transitions to refresh from StoreKit (see Apple ID vs account section).

**Subscription status display**: For v1, there is no in-app subscription management screen (users manage via iOS Settings). If a future version needs to show "Your plan: Annual, renews 15 June 2027", the verified transaction contains `expirationDate` and `productID` — but do not build this UI in this release.

### Debug Override

```swift
func checkEntitlement() async {
    #if DEBUG
    if DebugConfiguration.overrideEntitlementUnlocked {
        let changed = !hasFullAccess
        hasFullAccess = true
        if changed {
            NotificationCenter.default.post(name: Self.entitlementDidChange, object: nil)
        }
        return
    }
    #endif

    // ... real StoreKit entitlement check ...
}
```

This is the dev toggle mechanism — see Debug Override section below.

---

## Debug Override — Development Unlock Toggle

Add to `DebugConfiguration.swift`:

```swift
/// When true, `EntitlementManager` bypasses StoreKit and reports full access.
/// Set to `true` during feature development so locked sections are accessible.
/// Defaults to `false` so the app launches in production-like mode for testing.
/// Only compiles under #if DEBUG — zero footprint in release builds.
#if DEBUG
static var overrideEntitlementUnlocked: Bool = false
#endif
```

**Behaviour**:

- Default is `false` → app behaves exactly like production (locks enforced, purchase required).
- Developer sets to `true` in code → all content unlocked, no StoreKit calls needed.
- The flag is `#if DEBUG` guarded — it does not exist in release/archive builds. No App Store review risk.
- No runtime toggle UI needed. Flip the `false` to `true` in source, rebuild. This is intentionally source-level, not a hidden settings screen, to avoid any risk of accidental exposure.

**Security note**: Because the flag is compiled out entirely via `#if DEBUG`, there is no attack surface in production builds. Apple's review will never see or interact with it.

---

## `AppDelegate.swift` — Boot Sequence Changes

In `application(_:didFinishLaunchingWithOptions:)`, after auth bootstrap and before window setup:

```swift
// Subscription bootstrap
StoreKitManager.shared.listenForTransactions()
Task { await StoreKitManager.shared.loadProducts() }
Task { await EntitlementManager.shared.checkEntitlement() }
```

This ensures transaction listening starts immediately (catches pending transactions, refunds, subscription renewals), products are loaded for the purchase screen, and current entitlement is resolved before any UI appears.

---

## What Gets Locked & What Stays Free

### Daily Fit (Tab 0)

| Content                                | Free                          | Subscribed                 |
| -------------------------------------- | ----------------------------- | -------------------------- |
| Today's card reveal + full content     | YES                           | YES                        |
| Tomorrow button ("SEE TOMORROW'S FIT") | NO — presents purchase screen | YES — works as it does now |
| Calendar button (top-right)            | HIDDEN                        | HIDDEN                     |

**Calendar button**: The calendar button is a placeholder for a future feature. For this release, **hide it entirely** for all users regardless of subscription state. Set `calendarButton.isHidden = true` in `setupUI()` (or remove it from the view hierarchy). Do not gate it behind entitlement — it has no functional destination. This avoids a confusing "Coming Soon" dead-end for paying subscribers.

**Implementation in `DailyFitViewController.swift`:**

1. **`dayNavigationButtonTapped()`**: Before calling `switchToTomorrow()`, check `EntitlementManager.shared.hasFullAccess`. If `false`, present the purchase screen instead.

2. **`calendarButtonTapped()`**: Remove this method or make it a no-op. The calendar button is hidden for this release.

3. **Tomorrow tease text** at the bottom of today's content: Keep the existing text ("Tomorrow's energy is already shifting...") — it's a natural hook. Change the button below it:
   - Free: Button text = "UNLOCK FULL ACCESS" (styled as primary CTA). Tapping presents purchase screen.
   - Subscribed: Button text = "SEE TOMORROW'S FIT ›" (existing behaviour).

4. **Observe entitlement changes**: Register for `EntitlementManager.entitlementDidChange` in `viewDidLoad` and refresh the tomorrow button state when entitlement changes (covers the case where user purchases from the purchase screen and returns).

### Style Guide (Tab 1) — 8-Section Grid

| #   | Section       | Free   | Subscribed |
| --- | ------------- | ------ | ---------- |
| 1   | Style Core    | YES    | YES        |
| 2   | The Textures  | LOCKED | YES        |
| 3   | The Palette   | YES    | YES        |
| 4   | The Occasions | LOCKED | YES        |
| 5   | The Hardware  | LOCKED | YES        |
| 6   | The Code      | LOCKED | YES        |
| 7   | The Accessory | LOCKED | YES        |
| 8   | The Pattern   | LOCKED | YES        |

**Why these two free?** Style Core is the emotional hook — personalised narrative about who they are stylistically. The Palette is the visual hook — their personalised colour grid is striking and tangible. Together they prove the product is real and personal. The remaining 6 sections contain the actionable guidance (what to wear, what to avoid, how to dress for occasions) — this is the value worth subscribing for.

**Implementation in `StyleGuideViewController.swift`:**

1. **Define free sections** as a constant:

   ```swift
   private static let freeSections: Set<StyleGuideDetailContent.StyleGuideSection> = [.styleCore, .palette]
   ```

2. **`navigateToDetail(section:)`**: Check if the section is in `freeSections` or `EntitlementManager.shared.hasFullAccess`. If neither, present the purchase screen instead of the detail view.

3. **Visual lock state on grid tiles** — Modify `StyleGuideGridButton` to support a locked appearance:
   - Add a `var isLocked: Bool` property with a `didSet` that applies/removes the locked styling.
   - **Locked styling**: reduce the button's `alpha` to `0.45`, add a small `lock.fill` SF Symbol (12pt, positioned bottom-right with 12pt inset), desaturate via a grey-tinted overlay or reduced alpha (do not use `CAFilter` — keep it simple with alpha).
   - **Unlocked styling**: full alpha, no lock icon.
   - Call a method like `updateLockStates()` in `viewWillAppear` and in the entitlement-change notification handler to refresh all tiles.

4. **Observe entitlement changes**: Same pattern as Daily Fit — register for `EntitlementManager.entitlementDidChange` and call `updateLockStates()`.

### Guest vs. Authenticated — Auth Gate Change

**Current behaviour**: Unauthenticated users see `AuthGateViewController` on tab 0 instead of `DailyFitViewController`. `AuthGateViewController` is the **only** sign-in entry point in the app (email → OTP flow).

**New behaviour**: All users (guest and authenticated) see `DailyFitViewController` on tab 0. The auth gate is removed from the tab swap logic in `setupViewControllers()`.

**Rationale**: The Daily Fit for today is the strongest demonstration of value. Blocking it behind sign-in before the user can even see what they'd be paying for is a conversion killer. Their birth data is already stored locally from onboarding — the Daily Fit can be generated without authentication.

**CRITICAL — Preserving the sign-in path**: Removing the auth gate from tab 0 removes the only current sign-in UI. The following replacement entry points **must** be implemented to ensure users can still authenticate:

1. **Auth nudge banner on Style Guide tab** (`AuthNudgeBannerView`) — already exists. Currently tapping it switches to tab 0 (which was the auth gate). **Change the tap handler** so it now presents `AuthGateViewController` modally (wrapped in a `UINavigationController` so the OTP push works), rather than switching tabs. After successful OTP verification and auth state change, dismiss the modal.

2. **Menu → Profile** — `ProfileViewController` already shows a sign-out button when authenticated. When unauthenticated, add a **"Sign in to sync your data"** button in the same position. Tapping it presents `AuthGateViewController` modally (same pattern as the nudge banner). The sign-out button remains hidden when not authenticated (existing behaviour via `signOutButton.isHidden = !CosmicFitAuthService.shared.isAuthenticated`).

3. **`ProfileViewController` sign-out alert copy** — currently says "You will need to sign in again to access your Daily Fit." Update to "You will need to sign in again to sync your data across devices." (Daily Fit is no longer gated behind auth.)

**Do not delete `AuthGateViewController.swift`** — it is reused as a modal. Only remove the tab-0 swap logic from `CosmicFitTabBarController.setupViewControllers()`.

**Implementation in `CosmicFitTabBarController.setupViewControllers()`:**

Remove the `if CosmicFitAuthService.shared.isAuthenticated` / `else` branching for tab 0. Always create `DailyFitViewController`.

**Keep the auth-state notification handler** (`handleAuthStateChanged`) but change its behaviour: instead of swapping the tab 0 VC, it should trigger a Supabase blueprint hydration attempt (which it already does) and call `setupViewControllers()` to refresh UI (e.g. to update the auth nudge banner visibility).

**Landing tab on launch**: Change **both** of these to `selectedIndex = 0` (Daily Fit):

- `AppDelegate.setupExistingUserFlow` — currently sets `selectedIndex = 1`
- `OnboardingFormViewController.navigateToMainApp` — currently sets `selectedIndex = 1`

This ensures consistent Daily Fit landing for both returning and new users.

---

## Purchase Screen — `PaymentPlaceholderViewController.swift` Refactor

Rename to **`PurchaseViewController.swift`** (update all references in `DailyFitViewController.swift` and any other call sites).

### Layout (top to bottom)

1. **Logo** — existing `CosmicFitLogo` image view (keep as-is)
2. **Headline** — "UNLOCK YOUR\nCOSMIC STYLE" (serif font, existing style)
3. **Benefits intro** — "Full access includes" (existing)
4. **Benefits list** (4 bullet points, using existing `DosAndDontsSectionView.bulletPointRow`):
   - "Your Daily Fit every day — today, tomorrow, and beyond"
   - "All 8 sections of your personalised Cosmic Style Guide"
   - "Outfit direction grounded in your birth chart"
   - "New insights every day as the stars shift"
5. **Subscription options** — two selectable cards, stacked vertically:
   - **Annual card** (recommended, visually emphasised):
     - Left-aligned: "Annual"
     - Right-aligned: `product.displayPrice` + "/year"
     - Badge: "Save {annualSavingsPercent}%" (e.g. "Save 48%" at UK monthly £7.99 vs annual £49.99)
     - Pre-selected by default (highlighted border / filled background)
   - **Monthly card**:
     - Left-aligned: "Monthly"
     - Right-aligned: `product.displayPrice` + "/month"
     - No badge
     - Deselected style (outline only)
   - Tapping either card selects it (toggle selection state)
6. **CTA button** — "Subscribe Now" (primary style, enabled, full width)
   - Tapping initiates `StoreKitManager.shared.purchase(selectedProduct)`
   - Show activity indicator on the button during purchase flow
   - On success: dismiss the purchase screen, post entitlement change
   - On cancellation: re-enable button, no action
   - On error: show inline error label
7. **Restore link** — "Already subscribed? Restore" (small text button, centred)
   - Calls `StoreKitManager.shared.restorePurchases()`
   - Required by Apple review guidelines
8. **Legal links** — tiny text: "Terms of Use · Privacy Policy" linking to your web pages
   - Also required by Apple review guidelines
   - Use `UIApplication.shared.open(url)` for each
   - If you don't have these URLs yet, use placeholder URLs and update before submission
9. **Auto-renewal disclosure** (required by Apple):
   - Small grey text below the CTA: "Subscription automatically renews unless cancelled at least 24 hours before the end of the current period. Manage subscriptions in Settings."

### Product loading state

Products are loaded asynchronously via `StoreKitManager`. The purchase screen should handle three states:

- **Loading**: Show activity indicator where subscription cards will appear. CTA disabled.
- **Loaded**: Show subscription cards with live prices. CTA enabled.
- **Failed**: Show "Unable to load subscription options. Please check your connection and try again." with a retry button.

### Presentation

The purchase screen is presented the same way the current `PaymentPlaceholderViewController` is — via `CosmicFitTabBarController.presentDetailViewController` wrapped in a `GenericDetailViewController`. This gives it the slide-up animation, dimming overlay, and dismiss-on-swipe that the app already uses for detail views.

---

## Notification Flow

```
User taps locked content
       │
       ▼
PurchaseViewController presented
       │
       ▼
User selects plan, taps "Subscribe Now"
       │
       ▼
StoreKitManager.purchase(product)
       │
       ├── .success(.verified) ──► transaction.finish()
       │                                │
       │                                ▼
       │                    EntitlementManager.checkEntitlement()
       │                                │
       │                                ▼
       │                    hasFullAccess = true
       │                                │
       │                                ▼
       │                    Post EntitlementManager.entitlementDidChange
       │                                │
       │                    ┌───────────┴───────────┐
       │                    ▼                       ▼
       │           DailyFitVC                StyleGuideVC
       │           updates tomorrow          updates lock states
       │           button
       │                                │
       │                                ▼
       │                    Dismiss PurchaseViewController
       │
       ├── .userCancelled ──► no-op
       │
       └── .pending ──► show "Purchase pending approval" message
```

---

## User Journeys

### Journey 1: New user, no subscription

1. First launch → animated welcome → onboarding (name, DOB, location)
2. Onboarding completes → lands on **Daily Fit tab** (tab 0) — changed from current Style Guide landing
3. Sees today's tarot card back → taps to reveal → full today's content visible (style edit, palette, vibe, silhouettes, wardrobe reflection)
4. Scrolls to bottom → sees "Tomorrow's energy is already shifting..." + **"UNLOCK FULL ACCESS"** button
5. Taps it → purchase screen slides up → sees annual (recommended, save ~48% at UK prices) and monthly options
6. Decides not now → dismisses → continues using today's Daily Fit
7. Switches to Style Guide tab → sees 8-tile grid → **Style Core** and **The Palette** are tappable → other 6 tiles show lock icon + reduced opacity
8. Taps Style Core → reads full personalised narrative → thinks "this is actually about me"
9. Taps The Palette → sees their personalised colour grid → impressed
10. Taps a locked tile (e.g. The Textures) → purchase screen slides up
11. No sign-in required to purchase — Apple ID handles the transaction

### Journey 2: User subscribes

1. Taps "Subscribe Now" on annual plan → Apple payment sheet → Face ID → confirmed
2. Purchase screen dismisses automatically
3. Daily Fit: tomorrow button now reads "SEE TOMORROW'S FIT ›" and works
4. Style Guide: all 8 tiles are now fully styled and tappable
5. Subscription renews automatically each year

### Journey 3: Returning subscriber (same device, reinstall, or new device — same Apple ID)

1. Opens app → `EntitlementManager.checkEntitlement()` finds active subscription in `Transaction.currentEntitlements` for the App Store account on the device (no Cosmic Fit sign-in required).
2. `hasFullAccess = true` as soon as StoreKit returns current entitlements (typically early in launch).
3. All content unlocked — UI should reflect subscription state as soon as `entitlementDidChange` fires; avoid flashing paid content as locked if you can show a neutral launch state until the first `checkEntitlement()` completes.

### Journey 4: Subscription expires / cancelled

1. User cancels subscription in iOS Settings
2. When the current period ends, `Transaction.currentEntitlements` no longer returns a valid transaction
3. `EntitlementManager` sets `hasFullAccess = false`, posts notification
4. UI reverts to locked state: tomorrow button → purchase CTA, locked tiles re-lock
5. Today's Daily Fit remains fully accessible (free tier)

### Journey 5: New device / delayed entitlement — automatic + Restore

1. User installs on a **new device** (or reinstalls), completes onboarding — still **guest** or signed-in; irrelevant for Apple’s billing.
2. **`checkEntitlement()`** at launch reads `Transaction.currentEntitlements`. If the user is signed into the **same Apple ID** that subscribed, access is usually granted **without** tapping Restore.
3. If access is not yet reflected: user opens **Menu → Profile → Restore purchases** **or** opens the purchase screen and taps **“Already subscribed? Restore”** — both call `StoreKitManager.shared.restorePurchases()` → `AppStore.sync()` → `checkEntitlement()`.
4. If Restore still shows no subscription: user may be on a **different Apple ID** than the one that purchased — clarify in support-style copy, not as an app bug.

### Journey 6: Guest signs in (auth flow after gate removal)

1. User has been using the app as a guest (no sign-in)
2. Sees auth nudge banner at bottom of Style Guide tab: "Sign in to sync your data" → taps it
3. `AuthGateViewController` appears as a modal sheet (not tab swap) → enters email → receives OTP → verifies
4. Modal dismisses → `cosmicFitAuthStateChanged` fires → `CosmicFitTabBarController` triggers Supabase blueprint hydration → UI refreshes
5. Alternatively: user opens Menu → Profile → taps "Sign in to sync your data" → same modal flow
6. All existing functionality (Supabase sync, blueprint hydration, profile persistence) works exactly as before — only the entry point to `AuthGateViewController` has changed from tab-swap to modal

---

## Edge Cases

| Scenario                                   | Handling                                                                                                                                                                                                                                    |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Products fail to load from App Store       | Purchase screen shows error state with retry button. Lock states still enforced (no access without confirmed transaction).                                                                                                                  |
| Purchase interrupted (app killed mid-flow) | `Transaction.updates` listener catches the unfinished transaction on next launch, finishes it, grants access.                                                                                                                               |
| Family Sharing                             | StoreKit 2 handles this transparently if enabled on the subscription group in App Store Connect. `Transaction.currentEntitlements` includes family-shared subscriptions.                                                                    |
| Ask to Buy (child accounts)                | `.pending` result from `purchase()`. Show message: "Your purchase is waiting for approval." Entitlement granted when parent approves (caught by `Transaction.updates`).                                                                     |
| Refund                                     | Apple may revoke the transaction. `Transaction.updates` emits a revocation event. `checkEntitlement()` will no longer find a valid transaction → `hasFullAccess = false`.                                                                   |
| Subscription upgrade (monthly → annual)    | Apple handles proration. `Transaction.updates` emits the new transaction. `checkEntitlement()` still finds a valid entitlement. Seamless.                                                                                                   |
| Billing retry / grace period               | Apple retries failed payments for up to 60 days. During this period, `Transaction.currentEntitlements` still includes the subscription. `hasFullAccess` remains `true`. No special handling needed — StoreKit 2 manages this transparently. |
| Offline purchase attempt                   | StoreKit surfaces the error. Show "Unable to connect to the App Store. Please check your internet connection."                                                                                                                              |
| User not signed into App Store             | StoreKit prompts for Apple ID sign-in automatically when `purchase()` is called.                                                                                                                                                            |
| Sign-in path after auth gate removal       | `AuthGateViewController` is still reachable via: (a) auth nudge banner on Style Guide tab, (b) "Sign in" button on Profile page. Both present it modally. If these are missing, users cannot authenticate.                                  |
| User signs out of Cosmic Fit               | **Do not** revoke `hasFullAccess` based on auth alone. Subscription remains per Apple ID. Refresh UI for auth-specific controls only.                                                                                                       |
| User signs in after subscribing as guest   | Same Apple ID → subscription unchanged. **Do not** merge or copy entitlement from server; re-run `checkEntitlement()` if helpful.                                                                                                           |
| User deletes Cosmic Fit / Supabase account | **Does not** cancel App Store billing. **Do not** force `hasFullAccess = false` unless StoreKit no longer shows an active entitlement. Deletion flows should warn about Apple-managed billing (see Apple ID vs account section).            |
| Restore tapped while already subscribed    | Idempotent: sync completes, `checkEntitlement()` remains true, optional brief “You’re subscribed” confirmation is fine.                                                                                                                     |
| Profile Restore vs paywall Restore         | **Must** invoke the same `restorePurchases()` implementation (no drift).                                                                                                                                                                    |

---

## Testing

### Sandbox Testing (Recommended Primary Method)

1. In App Store Connect → **Users and Access** → **Sandbox** → create a sandbox tester account
2. On device: Settings → App Store → sign out of real Apple ID → sign in with sandbox tester when prompted during purchase
3. Sandbox purchases are free and auto-renew on an accelerated schedule (1 month = 5 minutes, 1 year = 1 hour)
4. Test: purchase monthly, purchase annual, **restore from paywall and from Profile** (same behaviour), cancel (via Settings), expiry, re-subscribe; **sign out while subscribed** and confirm paid content remains unlocked per StoreKit

### Debug Override Testing

1. Set `DebugConfiguration.overrideEntitlementUnlocked = true`
2. Rebuild → all content unlocked regardless of subscription state
3. Use this mode during day-to-day feature development when you need access to locked sections
4. Set back to `false` before testing the actual purchase flow or before archiving for submission

### Checklist Before Submission

- [ ] Products are Auto-Renewable Subscriptions (not Consumable) in App Store Connect
- [ ] Both products are in "Ready to Submit" status with localisation + review screenshot
- [ ] `DebugConfiguration.overrideEntitlementUnlocked` defaults to `false` (verified in source)
- [ ] Purchase flow works end-to-end in sandbox
- [ ] Restore Purchases works from **purchase screen** and from **Profile**
- [ ] After sign-out, paid content stays unlocked if Apple ID still has an active subscription (StoreKit truth)
- [ ] After sign-in, entitlement is not “invented” from server — still StoreKit only
- [ ] Account deletion flow (if present) does not incorrectly revoke access; user warned that Apple subscription is separate
- [ ] Lock states apply correctly when not subscribed
- [ ] Lock states clear correctly when subscribed
- [ ] Terms of Use and Privacy Policy URLs are live and functional
- [ ] Auto-renewal disclosure text is present on purchase screen
- [ ] Subscription management text is present ("Manage subscriptions in Settings")
- [ ] App does not crash if products fail to load
- [ ] Family Sharing behaviour tested if enabled
- [ ] Sign-in is reachable for unauthenticated users via nudge banner AND Profile page
- [ ] Sign-in completes successfully via modal `AuthGateViewController` → OTP → dismiss
- [ ] Sign-out works and UI reverts to unauthenticated state (nudge banner visible, sign-in button on Profile)
- [ ] Calendar button is hidden for all users
- [ ] Both new and returning users land on Daily Fit tab (tab 0)

---

## App Store Review Compliance

Apple will reject the app if any of these are missing:

1. **Restore Purchases** — must be visible and functional on the **purchase screen** **and** on **Profile** (Menu → Profile). Both must call the same `StoreKitManager.restorePurchases()` / `checkEntitlement()` path. Reviewers often expect restore without hunting the paywall.
2. **Terms of Use + Privacy Policy links** — must be on or accessible from the purchase screen
3. **Auto-renewal disclosure** — must state that the subscription auto-renews, the price, and how to cancel
4. **Subscription management instructions** — must tell users they can manage/cancel in iOS Settings (paywall copy already specifies this). Optional: Profile **“Manage subscription”** deep link to `https://apps.apple.com/account/subscriptions` for convenience.
5. **Price fetched from StoreKit** — never hardcode prices. Use `product.displayPrice` so Apple shows the correct localised currency
6. **Clear description of what's unlocked** — the benefits list must accurately describe what the subscription provides
7. **No misleading UI** — locked content must be clearly indicated, not hidden or confusing

---

## Files Quick Reference

| Concern                                     | Path                                                                                                                                                                                                                |
| ------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| StoreKit manager (NEW)                      | `Cosmic Fit/Core/Services/StoreKitManager.swift`                                                                                                                                                                    |
| Entitlement manager (NEW)                   | `Cosmic Fit/Core/Services/EntitlementManager.swift`                                                                                                                                                                 |
| Purchase screen (REFACTOR + RENAME)         | `Cosmic Fit/UI/ViewControllers/PaymentPlaceholderViewController.swift` → rename to `PurchaseViewController.swift`                                                                                                   |
| Daily Fit gating (MODIFY)                   | `Cosmic Fit/UI/ViewControllers/DailyFitViewController.swift`                                                                                                                                                        |
| Style Guide gating (MODIFY)                 | `Cosmic Fit/UI/ViewControllers/StyleGuideViewController.swift`                                                                                                                                                      |
| Style Guide grid button (MODIFY)            | Defined inline in `StyleGuideViewController.swift` (class `StyleGuideGridButton`, line ~679)                                                                                                                        |
| Tab bar auth gate removal (MODIFY)          | `Cosmic Fit/UI/ViewControllers/CosmicFitTabBarController.swift`                                                                                                                                                     |
| App boot sequence (MODIFY)                  | `Cosmic Fit/App/AppDelegate.swift`                                                                                                                                                                                  |
| Onboarding landing tab (MODIFY)             | `Cosmic Fit/UI/ViewControllers/OnboardingFormViewController.swift` — change `selectedIndex = 1` to `0`                                                                                                              |
| Profile — sign-in, restore, manage (MODIFY) | `Cosmic Fit/UI/ViewControllers/ProfileViewController.swift` — guest “Sign in to sync”; **always-visible Restore purchases**; optional Manage subscription URL; sign-out copy; **no** entitlement logic tied to auth |
| Auth nudge banner (MODIFY)                  | `Cosmic Fit/UI/Views/AuthNudgeBannerView.swift` + handler in `StyleGuideViewController.swift` — change tap to present `AuthGateViewController` modally                                                              |
| Auth gate (KEEP — reused as modal)          | `Cosmic Fit/UI/ViewControllers/AuthGateViewController.swift` — do NOT delete; no longer used as tab-0 swap                                                                                                          |
| Debug toggle (MODIFY)                       | `Cosmic Fit/Core/Config/DebugConfiguration.swift`                                                                                                                                                                   |
| Blueprint model (READ ONLY)                 | `Cosmic Fit/InterpretationEngine/BlueprintModels.swift`                                                                                                                                                             |
| Auth service (READ ONLY)                    | `Cosmic Fit/Core/Services/CosmicFitAuthService.swift`                                                                                                                                                               |

---

## Implementation Order

1. **`DebugConfiguration.swift`** — add `overrideEntitlementUnlocked` flag
2. **`EntitlementManager.swift`** — create with `checkEntitlement()`, debug override, notification posting
3. **`StoreKitManager.swift`** — create with product loading, purchasing, restore, transaction listener, savings helper
4. **`AppDelegate.swift`** — add boot sequence for StoreKit + entitlement; change `selectedIndex` to `0`
5. **`OnboardingFormViewController.swift`** — change post-onboarding `selectedIndex` from `1` to `0`
6. **`PurchaseViewController.swift`** — refactor from `PaymentPlaceholderViewController`; live purchase screen with product cards, CTA, restore, legal links, auto-renewal disclosure
7. **`DailyFitViewController.swift`** — gate tomorrow button behind entitlement; hide calendar button; observe entitlement changes
8. **`StyleGuideViewController.swift`** + **`StyleGuideGridButton`** — add lock state to tiles; gate `navigateToDetail` behind entitlement; observe entitlement changes
9. **`CosmicFitTabBarController.swift`** — remove auth gate swap for tab 0; always show `DailyFitViewController`; observe entitlement
10. **`ProfileViewController.swift`** — add "Sign in to sync" for guests; **add Profile “Restore purchases”** (shared `restorePurchases()`); optional “Manage subscription” link; update sign-out alert copy; verify sign-out does **not** clear StoreKit-derived access
11. **`AuthNudgeBannerView.swift`** / **`StyleGuideViewController.swift`** — change nudge tap handler to present `AuthGateViewController` modally instead of switching tabs
12. **Smoke test** — verify sign-in still works via nudge banner and profile; verify sign-out works; verify auth state notifications still refresh UI correctly; verify **Profile → Restore purchases** and paywall restore both call `restorePurchases()` and refresh locks; verify **sign-out does not lock** paid content if the Apple ID is still subscribed
13. **Subscription test** — sandbox purchases, restore, lock/unlock, expiry, upgrade, edge cases
14. **Submit** — ensure App Store Connect products are correct type (auto-renewable, NOT consumable), add screenshots, set to "Ready to Submit"

---

## App Store Server Notifications (V2)

### Overview

Apple sends webhook POSTs for subscription lifecycle events (new purchase, renewal, cancellation, refund, billing retry, etc.) to a URL you configure in App Store Connect. This is backend audit/reconciliation only — **client entitlement remains StoreKit 2 on-device** and is not replaced by server state.

### URLs

| Slot | URL |
|------|-----|
| **Production Server URL** | `https://fkzxcxycyvzutbvgjzwu.supabase.co/functions/v1/app-store-notifications` |
| **Sandbox Server URL** | Same URL (handler branches on `environment` in the verified payload) |

Version: **Notification Version 2** (selected in ASC).

### Identifiers

| Identifier | Value | Where used |
|------------|-------|------------|
| **Bundle ID** | `com.thisisbullish.cosmicfit` | Checked against every incoming notification; reject mismatches |
| **App Apple ID** | Numeric ID from ASC (set as secret `APP_APPLE_ID`) | Checked on production payloads when present |
| **Product IDs** | `com.cosmicfit.full.monthly`, `com.cosmicfit.full.annual` | Transaction payloads validated against allowlist |

### Security

1. **JWS verification**: every incoming `signedPayload` (and nested `signedTransactionInfo`) is verified via the x5c certificate chain pinned to Apple Root CA - G3. No payload is trusted or stored without passing verification.
2. **Bundle ID / App Apple ID / Product ID allowlists**: reject any verified notification that doesn't match this app.
3. **No Supabase JWT**: Apple does not send `apikey` / Bearer tokens. The Edge Function has `verify_jwt = false` in `config.toml`.
4. **Service role only DB access**: the `subscription_events` table has RLS enabled with no policies, so only the Edge Function (service role) can write.
5. **Redacted logging**: full JWS, raw POST body, and API keys are never logged. Structured log lines include only `notificationUUID`, `notificationType`, `subtype`, `environment`, `productId`, `originalTransactionId`.

### HTTP response semantics

| Condition | Status | Apple behavior |
|-----------|--------|----------------|
| Invalid method / missing body / bad JSON | 400 | No retry |
| JWS verify fail / wrong bundle / wrong product | 400 | No retry |
| Verified + inserted (or duplicate UUID) | 200 | Ack |
| Verified + unknown `notificationType` | 200 | Ack + audit row |
| Verified + transient DB failure | **500** | Apple retries |
| Config missing (`APP_STORE_BUNDLE_ID` not set) | **500** | Apple retries |

### Code

| File | Purpose |
|------|---------|
| `supabase/functions/app-store-notifications/index.ts` | HTTP handler |
| `supabase/functions/_shared/app-store-jws.ts` | JWS verify, cert chain, allowlist checks |
| `supabase/migrations/002_subscription_events.sql` | `subscription_events` table |
| `supabase/config.toml` | `[functions.app-store-notifications] verify_jwt = false` |

### Deploy

```bash
supabase db push                                          # apply 002 migration
supabase secrets set APP_STORE_BUNDLE_ID=com.thisisbullish.cosmicfit
supabase secrets set APP_APPLE_ID=<numeric-id-from-asc>
supabase functions deploy app-store-notifications
```

### Post-deploy validation

Run `supabase/functions/app-store-notifications/test-matrix.sh <url>` for automated HTTP-level checks. Then:

1. ASC → Send Test Notification → verify 200 + row in `subscription_events`
2. Sandbox purchase → SUBSCRIBED event received
3. Sandbox renewal → DID_RENEW event received
4. Query: `SELECT * FROM subscription_events ORDER BY received_at DESC LIMIT 10`

### Ops runbook

**Rotate secrets**: `supabase secrets set APP_STORE_BUNDLE_ID=... APP_APPLE_ID=...` → redeploy function.

**Pause notifications**: clear the URL in ASC → App Store Server Notifications. Apple stops sending.

**Investigate a subscription**: `SELECT * FROM subscription_events WHERE original_transaction_id = '<id>' ORDER BY received_at`.

**Redeploy after code change**: `supabase functions deploy app-store-notifications` (migration only needs re-push if schema changed).

**Alerts (recommended)**: monitor Edge Function 5xx rate, spike in 400 verification failures, and zero notifications over 24h when live subscription activity is expected.

### StoreKit-only policy (unchanged)

This webhook does **not** change how the iOS app gates access. `EntitlementManager.checkEntitlement()` remains the single source of truth, reading from `Transaction.currentEntitlements`. The webhook exists for backend audit, support tooling, and future reconciliation. Do not wire `hasFullAccess` to Supabase or server state without revising this policy.

### Phase 2 (implemented — requires 003 migration)

**`subscription_status` table**: keyed by `original_transaction_id`, updated via `upsert_subscription_status()` — a Postgres function with a monotonic guard (`WHERE EXCLUDED.last_event_signed_at > subscription_status.last_event_signed_at`). Out-of-order events (e.g. stale EXPIRED arriving after a newer DID_RENEW) are silently ignored.

**Notification type mapping** (in handler):

| Notification type | Subtype | Status |
|-------------------|---------|--------|
| SUBSCRIBED, DID_RENEW, RENEWAL_EXTENDED | — | active |
| DID_CHANGE_RENEWAL_STATUS | AUTO_RENEW_DISABLED | active (still valid until expiry) |
| DID_CHANGE_RENEWAL_STATUS | other | expired |
| DID_FAIL_TO_RENEW | GRACE_PERIOD | grace_period |
| DID_FAIL_TO_RENEW | other | billing_retry |
| GRACE_PERIOD_EXPIRED | — | billing_retry |
| REFUND | — | refunded |
| REVOKE | — | revoked |
| EXPIRED | — | expired |
| Unknown types | — | No status change; audit row only |

**Migration**: `supabase/migrations/003_subscription_status.sql`. Deploy with `supabase db push`.

**Status upsert failure is non-fatal**: the audit row in `subscription_events` is already persisted; a warning is logged but the handler returns 200.

**Future**: App Store Server API reconciliation job (requires `.p8` API key secrets: `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_PRIVATE_KEY`).

### Observability

**Structured log fields** (emitted by handler for every verified notification): `notificationUUID`, `notificationType`, `subtype`, `environment`, `productId`, `originalTransactionId`. Filter on `event: "app_store_notification_*"`.

**Recommended alerts** (configure in Supabase dashboard or external monitoring):

- Edge Function 5xx rate > 5% over 10 minutes
- `app_store_notification_rejected` (400) spike: > 10 in 5 minutes
- Zero `app_store_notification_verified` events in 24h when live subscription activity is expected
- `app_store_status_upsert_error` count > 0

**Support queries**:

```sql
-- All events for a subscription
SELECT notification_type, subtype, environment, product_id, event_signed_at, received_at
FROM subscription_events
WHERE original_transaction_id = '<id>'
ORDER BY received_at;

-- Current status for a subscription
SELECT * FROM subscription_status
WHERE original_transaction_id = '<id>';

-- Events in the last 24h
SELECT notification_type, count(*), max(received_at)
FROM subscription_events
WHERE received_at > now() - interval '24 hours'
GROUP BY notification_type
ORDER BY count(*) DESC;

-- Active subscriptions
SELECT original_transaction_id, product_id, environment, last_notification_type, updated_at
FROM subscription_status
WHERE status = 'active'
ORDER BY updated_at DESC;
```

**Retention**: consider pruning `subscription_events` older than 24 months via pg_cron once data volume warrants it. `subscription_status` rows are small and should be kept indefinitely.
