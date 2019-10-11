import XCTest
@testable import KeyPathReflector

final class KeyPathReflectorTests: XCTestCase {
    func testUniverseWorks() {
        XCTAssert(true)
    }

    func testNameReflections() throws {
        let reflector = try KeyPathReflector(Foo.self)

        XCTAssertEqual(reflector.property(for: \Foo.answer)?.name, "answer")
        XCTAssertEqual(reflector.property(for: \Foo.bar)?.name, "bar")
        XCTAssertEqual(reflector.property(for: \Foo.baz)?.name, "baz")
    }

    func testCachedKeyPaths() throws {
        let reflector = try KeyPathReflector(Foo.self)

        _ = reflector.property(for: \Foo.answer)
        _ = reflector.property(for: \Foo.bar)
        _ = reflector.property(for: \Foo.baz)

        XCTAssertEqual(reflector.cachedKeyPath(for: "answer"), \Foo.answer)
        XCTAssertEqual(reflector.cachedKeyPath(for: "bar"), \Foo.bar)
        XCTAssertEqual(reflector.cachedKeyPath(for: "baz"), \Foo.baz)
    }
}

struct Foo {
    static var instance: Foo = Foo(bar: "Hello", answer: 42, baz: false)

    var bar: String
    var answer: Int
    let baz: Bool
}
