import Foundation

public enum Hangul {
    public static let syllableStart: UInt32 = 0xAC00
    public static let syllableEnd: UInt32 = 0xD7A3

    public static let initialCount = 19
    public static let medialCount = 21
    public static let finalCount = 28

    public struct Syllable: Equatable, Hashable {
        public let initial: Int
        public let medial: Int
        public let final: Int

        public init(initial: Int, medial: Int, final: Int) {
            self.initial = initial
            self.medial = medial
            self.final = final
        }

        public var character: Character? {
            Hangul.compose(initial: initial, medial: medial, final: final)
        }
    }

    public enum Initial: Int {
        case giyeok      = 0   // ㄱ
        case ssangGiyeok = 1   // ㄲ
        case nieun       = 2   // ㄴ
        case digeut      = 3   // ㄷ
        case ssangDigeut = 4   // ㄸ
        case rieul       = 5   // ㄹ
        case mieum       = 6   // ㅁ
        case bieup       = 7   // ㅂ
        case ssangBieup  = 8   // ㅃ
        case siot        = 9   // ㅅ
        case ssangSiot   = 10  // ㅆ
        case ieung       = 11  // ㅇ
        case jieut       = 12  // ㅈ
        case ssangJieut  = 13  // ㅉ
        case chieut      = 14  // ㅊ
        case kieuk       = 15  // ㅋ
        case tieut       = 16  // ㅌ
        case pieup       = 17  // ㅍ
        case hieut       = 18  // ㅎ

        public var isDouble: Bool {
            switch self {
            case .ssangGiyeok, .ssangDigeut, .ssangBieup, .ssangSiot, .ssangJieut:
                return true
            default:
                return false
            }
        }
    }

    public enum Medial: Int {
        case a   = 0   // ㅏ
        case ae  = 1   // ㅐ
        case ya  = 2   // ㅑ
        case yae = 3   // ㅒ
        case eo  = 4   // ㅓ
        case e   = 5   // ㅔ
        case yeo = 6   // ㅕ
        case ye  = 7   // ㅖ
        case o   = 8   // ㅗ
        case wa  = 9   // ㅘ
        case wae = 10  // ㅙ
        case oe  = 11  // ㅚ
        case yo  = 12  // ㅛ
        case u   = 13  // ㅜ
        case weo = 14  // ㅝ
        case we  = 15  // ㅞ
        case wi  = 16  // ㅟ
        case yu  = 17  // ㅠ
        case eu  = 18  // ㅡ
        case ui  = 19  // ㅢ
        case i   = 20  // ㅣ
    }

    public static func decompose(_ character: Character) -> Syllable? {
        let scalars = character.unicodeScalars
        guard scalars.count == 1, let scalar = scalars.first else { return nil }
        let code = scalar.value
        guard code >= syllableStart, code <= syllableEnd else { return nil }

        let offset = code - syllableStart
        let medialTimesFinal = UInt32(medialCount * finalCount)
        let initial = Int(offset / medialTimesFinal)
        let medial = Int((offset % medialTimesFinal) / UInt32(finalCount))
        let final = Int(offset % UInt32(finalCount))

        return Syllable(initial: initial, medial: medial, final: final)
    }

    public static func compose(initial: Int, medial: Int, final: Int) -> Character? {
        guard (0..<initialCount).contains(initial),
              (0..<medialCount).contains(medial),
              (0..<finalCount).contains(final) else {
            return nil
        }
        let code = syllableStart
            + UInt32(initial) * UInt32(medialCount * finalCount)
            + UInt32(medial) * UInt32(finalCount)
            + UInt32(final)
        guard let scalar = UnicodeScalar(code) else { return nil }
        return Character(scalar)
    }

    public static func isSyllable(_ character: Character) -> Bool {
        decompose(character) != nil
    }
}
