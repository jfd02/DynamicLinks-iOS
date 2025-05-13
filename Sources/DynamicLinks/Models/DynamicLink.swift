import Foundation

@objc
public final class DynamicLink: NSObject, @unchecked Sendable {
    // The extracted deep link
    @objc public let url: URL?
    // Extracted UTM parameters
    @objc public let utmParameters: [String: String]
    // Extracted from `imv`
    @objc public let minimumAppVersion: String?

    @objc public init?(longLink: URL) {
        guard let components = URLComponents(url: longLink, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems
        else {
            print("❌ Invalid long link URL")
            return nil
        }

        let deepLink = queryItems.first(where: { $0.name == "link" })?.value.flatMap(URL.init)

        let imv = queryItems.first(where: { $0.name == "imv" })?.value

        var utmParams = [String: String]()
        for item in queryItems where item.name.starts(with: "utm_") {
            if let value = item.value {
                utmParams[item.name] = value
            }
        }

        self.url = deepLink
        self.utmParameters = utmParams
        self.minimumAppVersion = imv
    }
}
