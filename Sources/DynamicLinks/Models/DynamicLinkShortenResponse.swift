//

import Foundation

@objcMembers
public final class DynamicLinkShortenResponse: NSObject, Decodable, @unchecked Sendable {
    public let shortLink: String
    public let warnings: [Warning]
    
    @objcMembers
    public final class Warning: NSObject, Decodable {
        public let warningCode: String
        public let warningMessage: String
        
        enum CodingKeys: String, CodingKey {
            case warningCode = "warningCode"
            case warningMessage = "warningMessage"
        }
    }

}
