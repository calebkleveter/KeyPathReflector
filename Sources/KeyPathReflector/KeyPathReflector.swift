import Runtime

public final class KeyPathReflector<T> {
    private typealias Cache = (keyPaths: [String: PartialKeyPath<T>?], strings: [PartialKeyPath<T>: String?])

    private let properties: [PropertyInfo]
    private var cache: Cache

    public init(_ type: T.Type = T.self) throws {
        self.properties = try typeInfo(of: type).properties
        self.cache = ([:], [:])
    }

    public func string(for keyPath: PartialKeyPath<T>) -> String? {
        if let value = self.cache.strings[keyPath] { return value }

        guard let offset = MemoryLayout<T>.offset(of: keyPath) else {
            self.cache.strings[keyPath] = nil
            return nil
        }

        guard let name = self.properties.first(where: { $0.offset == offset })?.name else {
            self.cache.strings[keyPath] = nil
            return nil
        }

        self.cache.strings[keyPath] = name
        return name
    }

    public func cachedKeyPath(for string: String) -> PartialKeyPath<T>? {
        return self.cache.strings.first(where: { $0.value == string })?.key
    }
}
