import Foundation

enum AppConfig {
    private static let appStoreIDEnvKey = "APP_STORE_ID"

    static var appStoreID: String? {
        let value = ProcessInfo.processInfo.environment[appStoreIDEnvKey]?.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, !value.isEmpty else {
            return nil
        }
        return value
    }

    static var appStoreReviewURL: URL? {
        guard let appStoreID else { return nil }
        return URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }
}
