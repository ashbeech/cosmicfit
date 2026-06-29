import Foundation
import UIKit
import Supabase

enum FeedbackError: Error {
    case notConfigured
    case notAuthenticated
    case serverError(code: String, message: String)
    case rateLimited
    case unexpectedResponse
}

struct FeedbackMetadata: Encodable {
    let displayDate: String?
    let deviceModel: String
    let iosVersion: String
    let appVersion: String
}

final class FeedbackService {
    static let shared = FeedbackService()
    private init() {}

    private struct RequestBody: Encodable {
        let message: String
        let metadata: FeedbackMetadata
    }

    private struct ErrorBody: Decodable {
        let error: ErrorDetail
    }

    private struct ErrorDetail: Decodable {
        let code: String
        let message: String
    }

    func sendFeedback(message: String, displayDate: Date?) async throws {
        guard let baseURL = SupabaseConfig.url,
              let apiKey = SupabaseConfig.publishableKey else {
            throw FeedbackError.notConfigured
        }

        let session: Session
        do {
            session = try await supabase.auth.session
        } catch {
            throw FeedbackError.notAuthenticated
        }

        guard !session.isExpired else {
            throw FeedbackError.notAuthenticated
        }

        let url = baseURL.appendingPathComponent("functions/v1/send-feedback")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 30

        let dateString: String? = {
            guard let date = displayDate else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        }()

        let metadata = FeedbackMetadata(
            displayDate: dateString,
            deviceModel: deviceModelIdentifier(),
            iosVersion: await UIDevice.current.systemVersion,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
        )

        let body = RequestBody(message: message, metadata: metadata)
        request.httpBody = try JSONEncoder().encode(body)

        try Task.checkCancellation()

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw FeedbackError.unexpectedResponse
        }

        if httpResponse.statusCode == 429 {
            throw FeedbackError.rateLimited
        }

        if httpResponse.statusCode >= 400 {
            if let errorBody = try? JSONDecoder().decode(ErrorBody.self, from: data) {
                throw FeedbackError.serverError(
                    code: errorBody.error.code,
                    message: errorBody.error.message
                )
            }
            throw FeedbackError.serverError(
                code: "HTTP_\(httpResponse.statusCode)",
                message: "Request failed"
            )
        }
    }

    private func deviceModelIdentifier() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingUTF8: $0) ?? "unknown"
            }
        }
    }
}
