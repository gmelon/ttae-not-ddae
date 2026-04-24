import XCTest
@testable import TtaeCore

final class HangulTests: XCTestCase {
    func test_decompose_basicSyllable_가() {
        let syllable = Hangul.decompose("가")
        XCTAssertEqual(syllable, Hangul.Syllable(initial: 0, medial: 0, final: 0))
    }

    func test_decompose_withFinal_각() {
        let syllable = Hangul.decompose("각")
        XCTAssertEqual(syllable, Hangul.Syllable(initial: 0, medial: 0, final: 1))
    }

    func test_decompose_ddae_떄() {
        let syllable = Hangul.decompose("떄")
        XCTAssertEqual(syllable?.initial, Hangul.Initial.ssangDigeut.rawValue)
        XCTAssertEqual(syllable?.medial, Hangul.Medial.yae.rawValue)
        XCTAssertEqual(syllable?.final, 0)
    }

    func test_decompose_jjae_쨰() {
        let syllable = Hangul.decompose("쨰")
        XCTAssertEqual(syllable?.initial, Hangul.Initial.ssangJieut.rawValue)
        XCTAssertEqual(syllable?.medial, Hangul.Medial.yae.rawValue)
    }

    func test_decompose_nonHangulReturnsNil() {
        XCTAssertNil(Hangul.decompose("A"))
        XCTAssertNil(Hangul.decompose("1"))
        XCTAssertNil(Hangul.decompose(" "))
        XCTAssertNil(Hangul.decompose("ㄱ"))
    }

    func test_compose_ddae_때() {
        let character = Hangul.compose(
            initial: Hangul.Initial.ssangDigeut.rawValue,
            medial: Hangul.Medial.ae.rawValue,
            final: 0
        )
        XCTAssertEqual(character, "때")
    }

    func test_compose_outOfRange_returnsNil() {
        XCTAssertNil(Hangul.compose(initial: 19, medial: 0, final: 0))
        XCTAssertNil(Hangul.compose(initial: 0, medial: 21, final: 0))
        XCTAssertNil(Hangul.compose(initial: 0, medial: 0, final: 28))
    }

    func test_roundtrip_각() {
        let original: Character = "각"
        guard let syllable = Hangul.decompose(original) else {
            XCTFail("decompose returned nil")
            return
        }
        let recomposed = Hangul.compose(
            initial: syllable.initial,
            medial: syllable.medial,
            final: syllable.final
        )
        XCTAssertEqual(recomposed, original)
    }

    func test_initialIsDouble() {
        XCTAssertTrue(Hangul.Initial.ssangGiyeok.isDouble)
        XCTAssertTrue(Hangul.Initial.ssangDigeut.isDouble)
        XCTAssertTrue(Hangul.Initial.ssangBieup.isDouble)
        XCTAssertTrue(Hangul.Initial.ssangSiot.isDouble)
        XCTAssertTrue(Hangul.Initial.ssangJieut.isDouble)
        XCTAssertFalse(Hangul.Initial.giyeok.isDouble)
        XCTAssertFalse(Hangul.Initial.nieun.isDouble)
    }

    func test_isSyllable() {
        XCTAssertTrue(Hangul.isSyllable("가"))
        XCTAssertTrue(Hangul.isSyllable("힣"))
        XCTAssertFalse(Hangul.isSyllable("A"))
        XCTAssertFalse(Hangul.isSyllable("ㄱ"))
    }
}
