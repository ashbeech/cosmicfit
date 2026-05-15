import StoreKit

@MainActor
final class EntitlementManager {
    static let shared = EntitlementManager()

    private(set) var hasFullAccess: Bool = false

    static let entitlementDidChange = Notification.Name("CosmicFitEntitlementDidChange")

    private init() {}

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

        var foundAccess = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            let id = transaction.productID
            guard id == StoreKitManager.monthlyProductID || id == StoreKitManager.annualProductID else { continue }
            if transaction.revocationDate == nil {
                foundAccess = true
                break
            }
        }

        let oldValue = hasFullAccess
        hasFullAccess = foundAccess

        if oldValue != hasFullAccess {
            NotificationCenter.default.post(name: Self.entitlementDidChange, object: nil)
        }
    }
}
