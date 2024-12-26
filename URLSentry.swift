import Cocoa

struct TrackingParams: Decodable {
    let genericParams: [String]
    let domainRules: [String: DomainRule]
}

struct DomainRule: Decodable {
    let trackingParams: Set<String>
    let preserveParams: Set<String>
}

class ClipboardMonitor {
    private var lastChangeCount: Int
    private let pasteboard = NSPasteboard.general
    // Domain specific rules
    private var domainRules: [String: DomainRule] = [:]
    // Generic widely used tracking parameters. Only used for domains without specific rules
    private var genericTrackingParams: Set<String> = []

    init() {
        lastChangeCount = pasteboard.changeCount
        loadTrackingParams()
    }

    private func loadTrackingParams() {
        guard let url = Bundle.main.url(forResource: "trackingParams", withExtension: "json"),
            let data = try? Data(contentsOf: url) else {
                return
            }

        do {
            let trackingParams = try JSONDecoder().decode(TrackingParams.self, from: data)
            genericTrackingParams = Set(trackingParams.genericParams)
            domainRules = trackingParams.domainRules
        } catch {
            print("Failed to decode JSON: \(error)")
        }
    }

    func startMonitoring() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }

        RunLoop.current.run()
    }

    private func checkClipboard() {
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        guard let clipboardString = pasteboard.string(forType: .string),
            let url = URL(string: clipboardString),
            url.scheme?.hasPrefix("http") == true else { return }

        cleanAndUpdateURL(url)
    }

    private func getDomainRule(for url: URL) -> DomainRule? {
        let host = url.host?.lowercased() ?? ""
        return domainRules.first { domain, _ in
            host.contains(domain)
        }?.value
    }

    private func cleanAndUpdateURL(_ url: URL) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        guard let queryItems = components.queryItems else { return }

        let domainRule = getDomainRule(for: url)
        let cleanedItems: [URLQueryItem]

        if let rule = domainRule {
            // Apply domain-specific rules
            cleanedItems = queryItems.filter { item in
                !rule.trackingParams.contains(item.name.lowercased()) ||
                rule.preserveParams.contains(item.name.lowercased())
            }
        } else {
            // Only remove generic parameters for unknown domains
            cleanedItems = queryItems.filter { item in
                !genericTrackingParams.contains(item.name.lowercased())
            }
        }

        if cleanedItems.count != queryItems.count {
            components.queryItems = cleanedItems.isEmpty ? nil : cleanedItems

            if let cleanedURL = components.url?.absoluteString {
                // Update clipboard with cleaned URL
                pasteboard.clearContents()
                pasteboard.setString(cleanedURL, forType: .string)

                print("Cleaned URL: \(cleanedURL)")
            }
        }
    }
}

let monitor = ClipboardMonitor()
print("Starting clipboard monitor... (Control + C to quit)")
monitor.startMonitoring()
