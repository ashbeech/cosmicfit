import StoreKit

@MainActor
final class StoreKitManager {
    static let shared = StoreKitManager()

    private(set) var monthlyProduct: Product?
    private(set) var annualProduct: Product?

    private var transactionListener: Task<Void, Error>?

    static let monthlyProductID = "com.cosmicfit.full.monthly"
    static let annualProductID  = "com.cosmicfit.full.annual"

    enum PurchaseError: LocalizedError {
        case productNotFound
        case unverified
        case pending
        case unknown

        var errorDescription: String? {
            switch self {
            case .productNotFound: return "Unable to find the requested product."
            case .unverified:      return "The transaction could not be verified."
            case .pending:         return "Your purchase is waiting for approval."
            case .unknown:         return "An unknown error occurred."
            }
        }
    }

    private init() {}

    // MARK: - Product Loading

    func loadProducts() async {
        do {
            let products = try await Product.products(for: [
                Self.monthlyProductID,
                Self.annualProductID
            ])
            for product in products {
                switch product.id {
                case Self.monthlyProductID: monthlyProduct = product
                case Self.annualProductID:  annualProduct = product
                default: break
                }
            }
            if products.isEmpty {
                print("⚠️ StoreKit returned zero products — check App Store Connect IDs")
            } else {
                print("✅ StoreKit products loaded: \(products.map { $0.id })")
            }
        } catch {
            print("❌ StoreKit product load failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                await EntitlementManager.shared.checkEntitlement()
            case .unverified(_, let error):
                print("❌ Unverified transaction: \(error.localizedDescription)")
                throw PurchaseError.unverified
            }
        case .userCancelled:
            break
        case .pending:
            throw PurchaseError.pending
        @unknown default:
            throw PurchaseError.unknown
        }
    }

    // MARK: - Restore

    func restorePurchases() async throws {
        try await AppStore.sync()
        await EntitlementManager.shared.checkEntitlement()
    }

    // MARK: - Transaction Listener

    func listenForTransactions() {
        transactionListener = Task.detached {
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await EntitlementManager.shared.checkEntitlement()
            }
        }
    }

    // MARK: - Savings Helper

    var annualSavingsPercent: Int? {
        guard let monthly = monthlyProduct, let annual = annualProduct else { return nil }
        let yearlyAtMonthly = monthly.price * 12
        guard yearlyAtMonthly > 0 else { return nil }
        let savings = (yearlyAtMonthly - annual.price) / yearlyAtMonthly * 100
        return NSDecimalNumber(decimal: savings).intValue
    }
}
