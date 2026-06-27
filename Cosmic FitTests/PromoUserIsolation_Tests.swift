import Testing
import Foundation
@testable import Cosmic_Fit

// MARK: - Promo Code User Isolation Tests

struct PromoUserIsolation_Tests {

    // MARK: - CompAccessStorage basics

    @Test("CompAccessStorage save/load/clear round-trips")
    func compAccessStorageRoundTrip() {
        let grant = CompAccessGrant(
            code: "FIRST50",
            grantedAt: Date(),
            expiresAt: nil,
            redemptionPosition: 7
        )
        CompAccessStorage.save(grant)
        let loaded = CompAccessStorage.load()
        #expect(loaded != nil)
        #expect(loaded?.code == "FIRST50")
        #expect(loaded?.redemptionPosition == 7)

        CompAccessStorage.clear()
        #expect(CompAccessStorage.load() == nil)
    }

    @Test("CompAccessStorage.clear removes an existing grant")
    func compAccessStorageClearRemovesGrant() {
        let grant = CompAccessGrant(
            code: "FIRST50",
            grantedAt: Date(),
            expiresAt: nil,
            redemptionPosition: 1
        )
        CompAccessStorage.save(grant)
        #expect(CompAccessStorage.load() != nil)

        CompAccessStorage.clear()
        #expect(CompAccessStorage.load() == nil)
    }

    // MARK: - Restore guard

    @Test("restoreCompAccessIfNeeded is a no-op when not authenticated")
    @MainActor
    func restoreGuardRequiresAuth() async {
        #expect(!CosmicFitAuthService.shared.isAuthenticated)
        CompAccessStorage.clear()

        await PromoCodeService.shared.restoreCompAccessIfNeeded()

        #expect(CompAccessStorage.load() == nil,
                "Restore must not proceed when user is not authenticated")
    }

    // MARK: - Expired grant pruning

    @Test("EntitlementManager prunes expired comp grants during check")
    @MainActor
    func expiredGrantPruned() async {
        let expired = CompAccessGrant(
            code: "FIRST50",
            grantedAt: Date.distantPast,
            expiresAt: Date.distantPast,
            redemptionPosition: 1
        )
        CompAccessStorage.save(expired)
        #expect(CompAccessStorage.load() != nil)

        await EntitlementManager.shared.checkEntitlement()

        #expect(CompAccessStorage.load() == nil,
                "Expired grant should be pruned by checkEntitlement")
        #expect(!EntitlementManager.shared.hasCompAccess)
    }

    // MARK: - Valid grant survives entitlement check

    @Test("Valid comp grant survives entitlement check and sets hasCompAccess")
    @MainActor
    func validGrantSurvives() async {
        let valid = CompAccessGrant(
            code: "FIRST50",
            grantedAt: Date(),
            expiresAt: nil,
            redemptionPosition: 3
        )
        CompAccessStorage.save(valid)

        await EntitlementManager.shared.checkEntitlement()

        #expect(EntitlementManager.shared.hasCompAccess)
        #expect(EntitlementManager.shared.hasFullAccess)

        CompAccessStorage.clear()
        await EntitlementManager.shared.checkEntitlement()
    }
}
