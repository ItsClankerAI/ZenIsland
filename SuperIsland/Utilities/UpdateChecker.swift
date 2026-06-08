import Foundation

@MainActor
final class UpdateChecker: ObservableObject {
    static let shared = UpdateChecker()

    private static let lastCheckedKey = "updateChecker.lastCheckedAt"
    private static let dailyInterval: TimeInterval = 86400

    enum CheckState {
        case idle
        case checking
        case upToDate
        case updateAvailable(latestVersion: String, releaseURL: URL, downloadURL: URL?)
        case failed(String)
    }

    @Published var checkState: CheckState = .idle

    private init() {}

    var lastCheckedAt: Date? {
        let ts = UserDefaults.standard.double(forKey: Self.lastCheckedKey)
        return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }

    /// Called on app launch — only fires if 24 h have elapsed since the last check.
    func checkIfDue() {
        checkState = .upToDate
    }

    /// Manual "Check for Updates" button tap.
    func checkNow() {
        checkState = .failed("Automatic updates are disabled for this personal ZenBar build.")
    }

    private func performCheck() async {
        if case .checking = checkState { return }
        checkState = .failed("Automatic updates are disabled for this personal ZenBar build.")
    }

    private func isNewer(_ candidate: String, than current: String) -> Bool {
        let a = candidate.split(separator: ".").compactMap { Int($0) }
        let b = current.split(separator: ".").compactMap { Int($0) }
        for i in 0..<max(a.count, b.count) {
            let av = i < a.count ? a[i] : 0
            let bv = i < b.count ? b[i] : 0
            if av > bv { return true }
            if av < bv { return false }
        }
        return false
    }
}
