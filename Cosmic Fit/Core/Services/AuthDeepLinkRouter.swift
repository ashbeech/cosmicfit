import Foundation

final class AuthDeepLinkRouter {
    static let shared = AuthDeepLinkRouter()
    private init() {}

    var pendingDeepLink: (email: String, code: String)?

    @discardableResult
    func handle(url: URL) -> Bool {
        guard url.scheme == "cosmicfit",
              url.host == "login",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let email = components.queryItems?.first(where: { $0.name == "email" })?.value,
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value
        else { return false }

        pendingDeepLink = (email: email, code: code)
        NotificationCenter.default.post(name: .cosmicFitDeepLinkReceived, object: nil)
        print("🔗 Deep link stored — email: \(email)")
        return true
    }

    func consumePendingLink() -> (email: String, code: String)? {
        defer { pendingDeepLink = nil }
        return pendingDeepLink
    }
}
