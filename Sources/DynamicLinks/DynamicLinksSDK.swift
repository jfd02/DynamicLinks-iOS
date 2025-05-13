//

import UIKit

@objc
public final class DynamicLinksSDK: NSObject, @unchecked Sendable {

    @objc public static let SDKVersion: String = "1.0.0"
    
    nonisolated(unsafe) private static var lock = DispatchQueue(label: "com.DynamicLinks.lock")
    nonisolated(unsafe) private static var _shared: DynamicLinksSDK?

    @objc public static var shared: DynamicLinksSDK {
        return lock.sync {
            guard let instance = _shared else {
                assertionFailure("Must call DynamicLinks.configure first")
                return DynamicLinksSDK()
            }
            return instance
        }
    }

    @discardableResult
    @objc public static func configure(allowedHosts: [String]) -> DynamicLinksSDK {
        return lock.sync {
            precondition(_shared == nil, "configure(...) called multiple times")
            let instance = DynamicLinksSDK()
            instance.allowedHosts = allowedHosts
            _shared = instance
            return instance
        }
    }

    @objc public weak var delegate: DynamicLinksDelegate?

    private var allowedHosts: [String] = []

    private override init() { super.init() }
}


extension DynamicLinksSDK {
    public func handlePasteboardDynamicLink() async throws -> DynamicLink {
        let hasCheckedPasteboardKey = "hasCheckedPasteboardForDynamicLink"

        if UserDefaults.standard.bool(forKey: hasCheckedPasteboardKey) {
            throw DynamicLinksSDKError.alreadyCheckedPasteboard
        }

        UserDefaults.standard.set(true, forKey: hasCheckedPasteboardKey)

        let pasteboard = UIPasteboard.general
        if pasteboard.hasURLs {
            if let copiedURLString = pasteboard.string,
                let url = URL(string: copiedURLString)
            {
                let dynamicLink = try await handleDynamicLink(url)
                if pasteboard.string == copiedURLString {
                    pasteboard.string = nil
                }
                return dynamicLink
            }
        }
        throw DynamicLinksSDKError.noURLInPasteboard
    }

    public func handleDynamicLink(_ incomingURL: URL) async throws -> DynamicLink {
        guard isValidDynamicLink(url: incomingURL) else {
            throw DynamicLinksSDKError.invalidDynamicLink
        }

        guard let delegate else {
            throw DynamicLinksSDKError.delegateUnavailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            delegate.exchangeShortCode(requestedLink: incomingURL) { response, error in
                guard
                    let longLink = response?.longLink,
                    let dynamicLink = DynamicLink(longLink: longLink)
                else {
                    continuation.resume(throwing: error ?? DynamicLinksSDKError.unknownDelegateResponse)
                    return
                }
                continuation.resume(returning: dynamicLink)
            }
        }
    }

    @objc
    public func handlePasteboardDynamicLink(completion: @Sendable @escaping (DynamicLink?, NSError?) -> Void) {
        Task {
            do {
                let dynamicLink = try await handlePasteboardDynamicLink()
                completion(dynamicLink, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }

    @objc
    public func handleDynamicLink(_ incomingURL: URL, completion: @Sendable @escaping (DynamicLink?, NSError?) -> Void) {
        Task {
            do {
                let dynamicLink = try await handleDynamicLink(incomingURL)
                completion(dynamicLink, nil)
            } catch {
                completion(nil, error as NSError)
            }
        }
    }
}

extension DynamicLinksSDK {
    public func shorten(
        dynamicLink: DynamicLinkComponents,
        completion: @escaping (DynamicLinkShortenResponse?, Error?) -> Void
    ) {
        guard let delegate = DynamicLinksSDK.shared.delegate else {
            assertionFailure(
                "No DynamicLinkShortenerDelegate configured. "
                    + "You must set DynamicLinkConfig.shared.setShortenerDelegate(...) before shortening URLs."
            )
            completion(
                nil,
                DynamicLinksSDKError.delegateUnavailable
            )
            return
        }

        guard let longURL = dynamicLink.url else {
            completion(
                nil,
                DynamicLinksSDKError.invalidDynamicLink
            )
            return
        }

        delegate.shortenURL(longURL: longURL) { dynamicLinkShortenResponse, error in
            completion(dynamicLinkShortenResponse, error)
        }
    }

    public func shorten(
        dynamicLink: DynamicLinkComponents
    ) async throws -> DynamicLinkShortenResponse {
        guard let delegate = DynamicLinksSDK.shared.delegate else {
            assertionFailure(
                "No DynamicLinkShortenerDelegate configured. "
                    + "You must set DynamicLinkConfig.shared.setShortenerDelegate(...) before shortening URLs."
            )
            throw DynamicLinksSDKError.delegateUnavailable
        }

        guard let longURL = dynamicLink.url else {
            throw DynamicLinksSDKError.invalidDynamicLink
        }

        return try await withCheckedThrowingContinuation { continuation in
            delegate.shortenURL(longURL: longURL) { dynamicLinkShortenResponse, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else if let dynamicLinkShortenResponse = dynamicLinkShortenResponse {
                    continuation.resume(returning: (dynamicLinkShortenResponse))
                } else {
                    continuation.resume(
                        throwing: DynamicLinksSDKError.unknownDelegateResponse
                    )
                }
            }
        }
    }
}

extension DynamicLinksSDK {
    public func isValidDynamicLink(url: URL) -> Bool {
        guard let host = url.host else {
            return false
        }
        let canParse = canParseDynamicLink(url)
        let matchesShortLinkFormat = url.path.range(of: "/[^/]+", options: .regularExpression) != nil
        return canParse && matchesShortLinkFormat
    }

    private func canParseDynamicLink(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return isAllowedCustomDomain(url)
    }

    private func isAllowedCustomDomain(_ url: URL) -> Bool {
        guard let host = url.host else { return false }
        return allowedHosts.contains(host)
    }
}
