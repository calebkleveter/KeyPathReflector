public struct KeyPathLayout {
    public let bufferHeader: BufferHeader
    public let components: [Component]

    private let bytes: [UInt8]

    private init(bytes: [UInt8]) {
        assert(bytes.count >= 8, "KeyPath memory layout is too small")
        var byteIndex = bytes.startIndex

        self.bytes = bytes
        self.bufferHeader = .init(bytes: (bytes[0], bytes[1], bytes[2], bytes[3]))

        var components: [Component] = []
        while !(components.last?.eorp ?? false) {
            byteIndex += 4
            assert(byteIndex + 3 < bytes.count, "KeyPath component #\((byteIndex - 3) / 4) memory layout is too small")

            let payload = (
                bytes[byteIndex],
                bytes[byteIndex + 1],
                bytes[byteIndex + 2],
                bytes[byteIndex + 3]
            )

            components.append(.init(bytes: payload))
        }
        self.components = components
    }

    public init(_ keyPath: AnyKeyPath, size: Int = MemoryLayout<AnyKeyPath>.size) {
        var mutable = keyPath
        let bytes = withUnsafePointer(to: &mutable) {
            $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                Array(UnsafeBufferPointer(start: $0, count: size))
            }
        }

        self.init(bytes: bytes)
    }

    func generateKeyPath(size: Int = MemoryLayout<AnyKeyPath>.size) -> AnyKeyPath {
        fatalError("Not Implemented")
    }
}

extension KeyPathLayout {
    public struct BufferHeader {
        public let size: UInt32
        public let hasReferencePrefix: Bool
        public let hasDestructor: Bool

        public var isTrivial: Bool { !self.hasDestructor }

        internal init(bytes: (UInt8, UInt8, UInt8, UInt8)) {
            self.size = [bytes.0, bytes.1, bytes.2].integer()

            let tailBits = bytes.3.bits()
            self.hasReferencePrefix = tailBits.6.on
            self.hasDestructor = !tailBits.7.on
        }
    }

    public struct Component {
        public let payload: Payload
        public let kind: Kind

        /// Is end of reference prefix.
        public let eorp: Bool

        internal init(bytes: (UInt8, UInt8, UInt8, UInt8)) {
            let tailBits = bytes.3.bits()
            let rawKind = [tailBits.0, tailBits.1, tailBits.2, tailBits.3, tailBits.4, tailBits.5, tailBits.6].integer(as: UInt8.self)
            guard let kind = Kind(rawValue: rawKind) else {
                preconditionFailure("Got invalid key path component kind with raw value '\(rawKind)'")
            }

            self.kind = kind
            self.eorp = !tailBits.7.on
            self.payload = Payload(for: kind, with: (bytes.0, bytes.1, bytes.2))
        }
    }
}

extension KeyPathLayout.Component {
    public enum Kind: UInt8, Hashable, CaseIterable {
        /// Struct/tuple/self stored property
        case stored = 0

        /// Computed
        case computed = 1

        /// Class stored property
        case classStored = 2

        /// Optional chaining/forcing/wrapping
        case optional = 3
    }

    public enum Payload {
        case stored(Stored)
        case computed(Computed)
        case classStored(Stored)
        case optional(Optional)

        init(for kind: Kind, with payload: (UInt8, UInt8, UInt8)) {
            switch kind {
            case .stored: self = .stored(.init(payload))
            case .computed: self = .computed(.init(payload))
            case .classStored: self = .stored(.init(payload))
            case .optional: self = .optional(.init(payload))
            }
        }
    }
}

extension KeyPathLayout.Component.Payload {
    public enum Stored {
        case large
        case offset(UInt32)

        internal init(_ bytes: (UInt8, UInt8, UInt8)) {
            let offset = [bytes.0, bytes.1, bytes.2].integer(as: UInt32.self)
            if offset == 0xFF_FFFF {
                self = .large
            } else {
                self = .offset(offset)
            }
        }
    }

    public enum Optional {
        case chaining
        case wrapping
        case forceUnwrapping

        internal init(_ bytes: (UInt8, UInt8, UInt8)) {
            let id = [bytes.0, bytes.1, bytes.2].integer(as: UInt32.self)
            switch id {
            case 0: self = .chaining
            case 1: self = .wrapping
            case 2: self = .forceUnwrapping
            default: preconditionFailure("Invalid optional key path component payload value '\(id)'")
            }
        }
    }

    public struct Computed {
        let hasCaptures: Bool
        let idKind: UInt8
        let settable: Bool
        let mutating: Bool

        internal init(_ bytes: (UInt8, UInt8, UInt8)) {
            print(bytes.0.bits(), bytes.1.bits(), bytes.2.bits())

            self.hasCaptures = false
            self.idKind = 0
            self.settable = false
            self.mutating = false
        }
    }
}
