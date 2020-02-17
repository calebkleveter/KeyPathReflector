struct Bit: Hashable {
    static let zero = Bit(on: false)
    static let one = Bit(on: true)

    let on: Bool

    init(on: Bool) {
        self.on = on
    }
}

extension Bit: ExpressibleByIntegerLiteral {
    init(integerLiteral value: Int) {
        switch value {
        case 0: self.on = false
        case 1: self.on = true
        default: preconditionFailure("Invalid bit value \(value). Must be 0 or 1.")
        }
    }
}

extension Bit: LosslessStringConvertible {
    var description: String {
        return self.on ? "1" : "0"
    }

    init?(_ description: String) {
        switch description {
        case "0": self = .zero
        case "1": self = .one
        default: return nil
        }
    }
}

extension Bit: Comparable {
    static func < (lhs: Bit, rhs: Bit) -> Bool {
        return !lhs.on && rhs.on
    }
}



extension Array where Element == Bit {
    func integer<I>(as type: I.Type = I.self) -> I where I: FixedWidthInteger {
        let bigEndian = self.withUnsafeBufferPointer { pointer in
            pointer.baseAddress!.withMemoryRebound(to: I.self, capacity: 1) { $0 }
        }.pointee

        return I.init(bigEndian: bigEndian)
    }
}

extension Array where Element == UInt8 {
    func integer<I>(as type: I.Type = I.self) -> I where I: FixedWidthInteger {
        let bigEndian = self.withUnsafeBufferPointer { pointer in
            pointer.baseAddress!.withMemoryRebound(to: I.self, capacity: 1) { $0 }
        }.pointee

        return I.init(bigEndian: bigEndian)
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
