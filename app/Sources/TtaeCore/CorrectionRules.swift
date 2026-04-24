import Foundation

/// Tier 1 룰 기반 즉시 교정.
/// 한국어 사전에 존재할 수 없는 "쌍자음 + ㅒ/ㅖ" 조합을
/// "쌍자음 + ㅐ/ㅔ" 로 교정한다.
public enum CorrectionRules {
    private static let medialFixes: [Int: Int] = [
        Hangul.Medial.yae.rawValue: Hangul.Medial.ae.rawValue, // ㅒ → ㅐ
        Hangul.Medial.ye.rawValue:  Hangul.Medial.e.rawValue,  // ㅖ → ㅔ
    ]

    public static func correctedSyllable(for character: Character) -> Character? {
        guard let syllable = Hangul.decompose(character) else { return nil }
        guard let initial = Hangul.Initial(rawValue: syllable.initial), initial.isDouble else {
            return nil
        }
        guard let fixedMedial = medialFixes[syllable.medial] else { return nil }
        return Hangul.compose(
            initial: syllable.initial,
            medial: fixedMedial,
            final: syllable.final
        )
    }
}
