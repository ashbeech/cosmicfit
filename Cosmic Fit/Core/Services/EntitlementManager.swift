import StoreKit

@MainActor
final class EntitlementManager {
    static let shared = EntitlementManager()

    private(set) var hasFullAccess: Bool = false
    private(set) var hasStoreKitSubscription: Bool = false
    private(set) var hasCompAccess: Bool = false
    var appliedCompCode: String? { CompAccessStorage.load()?.code }

    static let entitlementDidChange = Notification.Name("CosmicFitEntitlementDidChange")

    private init() {}

    func checkEntitlement() async {
        #if DEBUG
        if DebugConfiguration.overrideEntitlementUnlocked {
            let changed = !hasFullAccess
            hasStoreKitSubscription = false
            hasCompAccess = false
            hasFullAccess = true
            if changed {
                NotificationCenter.default.post(name: Self.entitlementDidChange, object: nil)
            }
            return
        }
        #endif

        // 1. Prune expired comp grant
        if let grant = CompAccessStorage.load(), !grant.isValid {
            CompAccessStorage.clear()
        }

        // 2. Check comp access
        let compValid = CompAccessStorage.load()?.isValid == true

        // 3. Check StoreKit
        var storeKitActive = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            let id = transaction.productID
            guard id == StoreKitManager.monthlyProductID || id == StoreKitManager.annualProductID else { continue }
            if transaction.revocationDate == nil {
                storeKitActive = true
                break
            }
        }

        let oldFullAccess = hasFullAccess
        let oldCompAccess = hasCompAccess
        let oldStoreKit = hasStoreKitSubscription
        hasStoreKitSubscription = storeKitActive
        hasCompAccess = compValid
        hasFullAccess = storeKitActive || compValid

        if oldFullAccess != hasFullAccess
            || oldCompAccess != hasCompAccess
            || oldStoreKit != hasStoreKitSubscription {
            NotificationCenter.default.post(name: Self.entitlementDidChange, object: nil)
        }
    }
}
