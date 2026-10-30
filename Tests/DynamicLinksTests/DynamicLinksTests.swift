import Foundation
import Testing
@testable import OSDynamicLinks

private func queryItems(_ components: DynamicLinkComponents) throws -> [String: String] {
    let url = try #require(components.url)
    let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
    return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
}

private func components(link: String) throws -> DynamicLinkComponents {
    try #require(DynamicLinkComponents(link: URL(string: link)!, domainURIPrefix: "https://je.fit"))
}

@Test func linkWithItsOwnQueryStaysOneParameter() throws {
    let link = "https://www.jefit.com/signup/?referrer=42&referrer-username=sam"
    let query = try queryItems(components(link: link))
    #expect(query["link"] == link)
    #expect(query["referrer-username"] == nil)
}

@Test func shortPathLengthIsSentAsPath() throws {
    let components = try components(link: "https://www.jefit.com/signup/")
    components.options.pathLength = .short
    let query = try queryItems(components)
    #expect(query["path"] == "SHORT")
    #expect(query["pathLength"] == nil)
}

@Test func pathDefaultsToUnguessable() throws {
    let query = try queryItems(components(link: "https://www.jefit.com/signup/"))
    #expect(query["path"] == "UNGUESSABLE")
}

@Test func fallbackLinkKeepsItsQuery() throws {
    let components = try components(link: "https://www.jefit.com/year-report/")
    let fallback = "https://www.jefit.com/year-report/?year=2025&user=42"
    components.otherPlatformParameters = DynamicLinkOtherPlatformParameters(fallbackURL: URL(string: fallback))
    let query = try queryItems(components)
    #expect(query["ofl"] == fallback)
}
