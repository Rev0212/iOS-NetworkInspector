import Foundation
import Testing
@testable import NetworkInspector

/// Sessions that own their configuration never consult `URLProtocol.registerClass`, so the only
/// proof the inspector can see them is the protocol landing in a freshly built configuration.
@Test func injectsProtocolIntoConfigurationsCustomSessionsAreBuiltFrom() async throws {
    URLSessionConfiguration.installInspectorSwizzle()

    // `default` is what Ktor's Darwin engine builds its NSURLSession from.
    let defaultClasses = URLSessionConfiguration.default.protocolClasses ?? []
    #expect(defaultClasses.contains { $0 == InspectorURLProtocol.self })

    let ephemeralClasses = URLSessionConfiguration.ephemeral.protocolClasses ?? []
    #expect(ephemeralClasses.contains { $0 == InspectorURLProtocol.self })
}

@Test func installIsIdempotent() async throws {
    URLSessionConfiguration.installInspectorSwizzle()
    URLSessionConfiguration.installInspectorSwizzle()

    let classes = URLSessionConfiguration.default.protocolClasses ?? []
    let occurrences = classes.filter { $0 == InspectorURLProtocol.self }.count
    #expect(occurrences == 1)
}
