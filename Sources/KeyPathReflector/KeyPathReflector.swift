import Runtime

public final class KeyPathReflector<T> {
    private typealias Cache = (keyPaths: [String: PartialKeyPath<T>?], properties: [PartialKeyPath<T>: PropertyInfo?])

    private let properties: [PropertyInfo]
    private var cache: Cache

    public init(_ type: T.Type = T.self) throws {
        self.properties = try typeInfo(of: type).properties
        self.cache = ([:], [:])
    }

    public func property(for keyPath: PartialKeyPath<T>) -> PropertyInfo? {
        if case let .some(cached) = self.cache.properties[keyPath] { return cached }

        guard let offset = MemoryLayout<T>.offset(of: keyPath) else {
            self.cache.properties[keyPath] = .some(.none)
            return nil
        }

        guard let property = self.properties.first(where: { $0.offset == offset }) else {
            self.cache.properties[keyPath] = .some(.none)
            return nil
        }

        self.cache.properties[keyPath] = .some(.some(property))
        return property
    }

    public func cachedKeyPath(for string: String) -> PartialKeyPath<T>? {
        return self.cache.properties.first(where: { $0.value?.name == string })?.key
    }
}
