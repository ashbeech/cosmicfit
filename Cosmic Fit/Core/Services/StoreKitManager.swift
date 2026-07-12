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

    // MARK: - Introductory Offer

    /// The annual product's free-trial introductory offer, if one is configured
    /// in App Store Connect. Nil for pay-as-you-go / pay-up-front intro offers.
    var annualFreeTrialOffer: Product.SubscriptionOffer? {
        guard let offer = annualProduct?.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        return offer
    }

    var annualTrialIsOneWeek: Bool {
        guard let period = annualFreeTrialOffer?.period else { return false }
        return (period.unit == .week && period.value == 1)
            || (period.unit == .day && period.value == 7)
    }

    /// e.g. "7 days" — for the paywall card ("7 days free, then …/year").
    var annualTrialDurationText: String? {
        guard let period = annualFreeTrialOffer?.period else { return nil }
        return Self.trialDurationText(value: period.value, unit: period.unit)
    }

    /// e.g. "7-day" — for the disclosure sentence ("a 7-day free trial").
    var annualTrialDurationAdjective: String? {
        guard let period = annualFreeTrialOffer?.period else { return nil }
        return Self.trialDurationAdjective(value: period.value, unit: period.unit)
    }

    /// Eligibility is tracked by Apple per subscription group. Fails closed
    /// (false) when products haven't loaded or no free trial is configured.
    func isEligibleForAnnualIntroOffer() async -> Bool {
        guard annualFreeTrialOffer != nil,
              let subscription = annualProduct?.subscription else { return false }
        return await subscription.isEligibleForIntroOffer
    }

    static func trialDurationText(value: Int, unit: Product.SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day:   return value == 1 ? "1 day" : "\(value) days"
        case .week:  return "\(value * 7) days"
        case .month: return value == 1 ? "1 month" : "\(value) months"
        case .year:  return value == 1 ? "1 year" : "\(value) years"
        @unknown default: return "\(value) days"
        }
    }

    static func trialDurationAdjective(value: Int, unit: Product.SubscriptionPeriod.Unit) -> String {
        switch unit {
        case .day:   return "\(value)-day"
        case .week:  return "\(value * 7)-day"
        case .month: return value == 1 ? "1-month" : "\(value)-month"
        case .year:  return value == 1 ? "1-year" : "\(value)-year"
        @unknown default: return "\(value)-day"
        }
    }
}
