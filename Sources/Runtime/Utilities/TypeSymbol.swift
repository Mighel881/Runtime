
import Foundation
import CRuntime

indirect enum TypeSymbol {
    struct Descriptor {
        let module: String
        let name: String
    }

    case concrete(Descriptor)
    case generic(Descriptor, arguments: [TypeSymbol])
    case tuple([TypeSymbol])
}

extension TypeSymbol {

    var flatten: [TypeSymbol] {
        switch self {
        case .concrete, .generic:
            return [self]
        case .tuple(let elements):
            return elements.flatMap { $0.flatten }
        }
    }

}

extension TypeSymbol {

    func type() -> Any.Type {
        return metatype(for: mangledName)
    }

    fileprivate var mangledName: String {
        switch self {
        case .concrete(let descriptor):
            return descriptor.mangledName
        case .generic(let descriptor, let arguments):
            let arguments = arguments.map { $0.mangledName }
            // TODO: this probably is still wrong
            return "\(descriptor.mangledName)y\(arguments.joined())G"
        case .tuple(let symbols):
            let symbols = symbols.map { $0.mangledName }
            return "T\(symbols.joined())"
        }
    }

}

extension TypeSymbol.Descriptor {

    fileprivate var mangledName: String {
        if module == "Swift" {
            let mangledName: String

            switch name {
            case "Array": mangledName = "a"
            case "AutoreleasingUnsafeMutablePointer": mangledName = "A"
            case "Bool": mangledName = "b"
            case "UnicodeScalar": mangledName = "c"
            case "Dictionary": mangledName = "D"
            case "Double": mangledName = "d"
            case "Float": mangledName = "f"
            case "Set": mangledName = "h"
            case "DefaultIndices": mangledName = "I"
            case "Int": mangledName = "i"
            case "Character": mangledName = "J"
            case "ClosedRange": mangledName = "N"
            case "Range": mangledName = "n"
            case "ObjectIdentifier": mangledName = "O"
            case "UnsafeMutablePointer": mangledName = "p"
            case "UnsafePointer": mangledName = "P"
            case "UnsafeBufferPointer": mangledName = "R"
            case "UnsafeMutableBufferPointer": mangledName = "r"
            case "String": mangledName = "S"
            case "Substring": mangledName = "s"
            case "UInt": mangledName = "u"
            case "UnsafeMutableRawPointer": mangledName = "v"
            case "UnsafeRawPointer": mangledName = "V"
            case "UnsafeRawBufferPointer": mangledName = "W"
            case "UnsafeMutableRawBufferPointer": mangledName = "w"

            case "Optional": mangledName = "q"

            case "BinaryFloatingPoint": mangledName = "B"
            case "Encodable": mangledName = "E"
            case "Decodable": mangledName = "e"
            case "FloatingPoint": mangledName = "F"
            case "RandomNumberGenerator": mangledName = "G"
            case "Hashable": mangledName = "H"
            case "Numeric": mangledName = "j"
            case "BidirectionalCollection": mangledName = "K"
            case "RandomAccessCollection": mangledName = "k"
            case "Comparable": mangledName = "L"
            case "Collection": mangledName = "l"
            case "MutableCollection": mangledName = "M"
            case "RangeReplaceableCollection": mangledName = "m"
            case "Equatable": mangledName = "Q"
            case "Sequence": mangledName = "T"
            case "IteratorProtocol": mangledName = "t"
            case "UnsignedInteger": mangledName = "U"
            case "RangeExpression": mangledName = "X"
            case "Strideable": mangledName = "x"
            case "RawRepresentable": mangledName = "Y"
            case "StringProtocol": mangledName = "y"
            case "SignedInteger": mangledName = "Z"
            case "BinaryInteger": mangledName = "z"

            default:
                mangledName = "\(name.count)\(name)"
            }

            return "S\(mangledName)"
        }
        return "\(module.count)\(module)\(name.count)\(name)V"
    }

}

private func metatype(for mangled: String) -> Any.Type {
    let pointer = mangled
        .cString(using: .utf8)!
        .withUnsafeBytes { pointer -> UnsafeRawPointer in
            let casted = pointer.baseAddress!.assumingMemoryBound(to: Int8.self)
            return swift_getTypeByMangledNameInContext(casted,
                                                       Int32(mangled.count),
                                                       nil,
                                                       nil)!
        }

    return unsafeBitCast(pointer, to: Any.Type.self)
}
