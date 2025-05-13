import Foundation

@objc
public enum DynamicLinksSDKError: Int, Error {
    case notConfigured
    case invalidDynamicLink
    case delegateUnavailable
    case unknownDelegateResponse
    case noURLInPasteboard
    case alreadyCheckedPasteboard

    var nsError: NSError {
        switch self {
        case .notConfigured:
            return NSError(domain: "com.DynamicLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "DynamicLinks not configured"])
        case .invalidDynamicLink:
            return NSError(domain: "com.DynamicLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "Invalid dynamic link"])
        case .delegateUnavailable:
            return NSError(domain: "com.DynamicLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "Delegate unavailable"])
        case .unknownDelegateResponse:
            return NSError(
                domain: "com.DynamicLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "Unknown response from delegate"])
        case .noURLInPasteboard:
            return NSError(
                domain: "com.DynamicLinks", code: rawValue, userInfo: [NSLocalizedDescriptionKey: "No valid URL found in pasteboard"])
        case .alreadyCheckedPasteboard:
            return NSError(
                domain: "com.DynamicLinks", code: rawValue,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Already checked pasteboard for Dynamic Link once, further checks will fail immediately as handling now goes through handleDynamicLink"
                ])
        }
    }
}
