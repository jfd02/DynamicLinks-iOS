import Foundation

@objc public protocol DynamicLinksDelegate: AnyObject {
    @objc func shortenURL(
        longURL: URL,
        completion: @escaping (DynamicLinkShortenResponse?, Error?) -> Void
    )

    @objc func exchangeShortCode(
        requestedLink: URL,
        completion: @escaping (ExchangeLinkResponse?, Error?) -> Void
    )
}
