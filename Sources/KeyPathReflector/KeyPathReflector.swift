import Runtime

/// Reflects property information for key paths of stored properties for a given type.
public final class KeyPathReflector<T> {
    private typealias Cache = (keyPaths: [String: PartialKeyPath<T>?], properties: [PartialKeyPath<T>: PropertyInfo?])

    private let properties: [PropertyInfo]
    private var cache: Cache

    /// Creates a new instance of `KeyPathReflector` for a given type.
    ///
    /// - Parameter type: The type to reflect properties for.
    ///   This parameter defaults to `T.self` if the type is known.
    ///
    /// - Throws: `RuntimeError.couldNotGetTypeInfo` if the kind of type is not supported by the reflector.
    public init(_ type: T.Type = T.self) throws {
        self.properties = try typeInfo(of: type).properties
        self.cache = ([:], [:])
    }

    /// Gets the property information for a key path if the key path referances a stored property.
    ///
    /// When this method is called for a given key-path for the first time, the result is cached, reducing
    /// the complexity of subsequent calls to _O(1)_.
    ///
    /// - Parameter keyPath: The key path to get the static property information for.
    ///
    /// - Complexity: _O(n)_, where _n_ is the number of stored properties reflected for the given type.
    ///
    /// - Returns: The property information for the key path.
    ///   `nil` is returned if there is no memory off-set of the property referanced (this happens in cases such as a computed property),
    ///   or no reflected property is found for the given memory off-set.
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

    /// Gets the cached `PartialKeyPath` where the property info for the key path has a given name.
    ///
    /// - Parameter string: The name of the property to get the key path for.
    ///
    /// - Complexity: _O(n)_, where _n_ is the number of cached key paths.
    ///
    /// - Returns: The `PartialKeyPath` that matches the property info with the name of the string passed in.
    public func cachedKeyPath(for string: String) -> PartialKeyPath<T>? {
        return self.cache.properties.first(where: { $0.value?.name == string })?.key
    }

    /// Gets the cached `PartialKeyPath` as a `KeyPath` where the property info for the key path has a given name.
    ///
    /// - Parameter string: The name of the property to get the key path for.
    ///
    /// - Complexity: _O(n)_, where _n_ is the number of cached key paths.
    ///
    /// - Returns: The `KeyPath` that matches the property info with the name of the string passed in.
    public func cachedKeyPath<Value>(for string: String) -> KeyPath<T, Value>? {
        return self.cache.properties.first(where: { $0.value?.name == string })?.key as? KeyPath<T, Value>
    }
}
