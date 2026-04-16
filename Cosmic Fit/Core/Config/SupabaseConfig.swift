import Foundation
import Supabase

/// Reads Supabase credentials from Info.plist, which are injected from the
/// active xcconfig (Dev.xcconfig / Prod.xcconfig) via build settings.
enum SupabaseConfig {
    static let url: URL? = {
        guard let str = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              !str.isEmpty,
              let url = URL(string: str),
              let scheme = url.scheme?.lowercased(),
              (scheme == "https" || scheme == "http"),
              let host = url.host,
              !host.isEmpty else {
            return nil
        }
        return url
    }()

    static let publishableKey: String? = {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_PUBLISHABLE_KEY") as? String,
              !key.isEmpty else {
            return nil
        }
        return key
    }()

    static var isConfigured: Bool {
        url != nil && publishableKey != nil
    }
}

let supabase: SupabaseClient = {
    guard let url = SupabaseConfig.url, let key = SupabaseConfig.publishableKey else {
        return SupabaseClient(
            supabaseURL: URL(string: "https://placeholder.supabase.co")!,
            supabaseKey: "placeholder",
            options: .init(auth: .init(redirectToURL: URL(string: "cosmicfit://login"),
                                       flowType: .implicit))
        )
    }
    return SupabaseClient(
        supabaseURL: url,
        supabaseKey: key,
        options: .init(auth: .init(redirectToURL: URL(string: "cosmicfit://login"),
                                   flowType: .implicit))
    )
}()
