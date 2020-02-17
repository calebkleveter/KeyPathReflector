public struct KeyPathLayout {
    private init(bytes: [UInt8]) {

    }

    public init(_ keyPath: AnyKeyPath) {
        var mutable = keyPath
        let size = MemoryLayout<AnyKeyPath>.size
        let bytes = withUnsafePointer(to: &mutable) {
            $0.withMemoryRebound(to: UInt8.self, capacity: size) {
                Array(UnsafeBufferPointer(start: $0, count: size))
            }
        }

        self.init(bytes: bytes)
    }
}

extension KeyPathLayout {
    public struct Offset {
        public static let pointer: Offset = .init(0)
        public static let bufferHeader: Offset = .init(UInt8(1 * MemoryLayout<Int>.size))

        public let value: UInt8

        private init(_ value: UInt8) {
            self.value = value
        }
    }

    struct BufferHeader {
        // Bits 0...23
        public let size: UInt8

        // Bits 24...29 are reserved.

        // Bit 30
        public let hasReferencePrefix: Bool

        // 31
        public let hasDestructor: Bool

        public var isTrivial: Bool { !self.hasDestructor }

        internal init(bytes: (UInt8, UInt8, UInt8, UInt8)) {
            self.size = bytes.0

            let tailBits = bytes.3.bits()
            self.hasReferencePrefix = tailBits.6.on
            self.hasDestructor = tailBits.7.on
        }
    }

    struct Component {
        let payload: UInt8
        let kind: Kind

        /// Is end of reference prefix.
        let eorp: Bool
    }
}

extension KeyPathLayout.Component {
    public enum Kind: Int, Hashable, CaseIterable {
        /// Struct/tuple/self stored property
        case stored = 0

        /// Computed
        case computed = 1

        /// Class stored property
        case classStored = 2

        /// Optional chaining/forcing/wrapping
        case optional = 3
    }
}

struct Bit: CustomStringConvertible, ExpressibleByIntegerLiteral {
    static let zero = Bit(on: false)
    static let one = Bit(on: true)

    static var bitWidth: Int = 1
    static var max: Bit = .one
    static var min: Bit = .zero

    let on: Bool

    var description: String {
        return self.on ? "1" : "0"
    }

    init(on: Bool) {
        self.on = on
    }

    init(integerLiteral value: Int) {
        switch value {
        case 0: self.on = false
        case 1: self.on = true
        default: preconditionFailure("Invalid bit value \(value). Must be 0 or 1.")
        }
    }
}

extension UInt8 {
    func bits() -> (Bit, Bit, Bit, Bit, Bit, Bit, Bit, Bit) {
        var bits: (Bit, Bit, Bit, Bit, Bit, Bit, Bit, Bit) = (0, 0, 0, 0, 0, 0, 0, 0)
        var byte = self

        (0...8).forEach { index in
            if byte & 0x01 != 0 {
                withUnsafeMutableBytes(of: &bits) { pointer in
                    pointer.storeBytes(of: Bit.one, toByteOffset: MemoryLayout<Bit>.stride &* index, as: Bit.self)
                }
            }

            byte >>= 1
        }

        return bits
    }
}
