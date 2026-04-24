import XCTest
@testable import TtaeCore

final class CorrectionRulesTests: XCTestCase {
    func test_correct_ddae떄To때() {
        XCTAssertEqual(CorrectionRules.correctedSyllable(for: "떄"), "때")
    }

    func test_correct_jjae쨰To째() {
        XCTAssertEqual(CorrectionRules.correctedSyllable(for: "쨰"), "째")
    }

    func test_correct_kkae꺠To깨() {
        XCTAssertEqual(CorrectionRules.correctedSyllable(for: "꺠"), "깨")
    }

    func test_correct_ppae뺴To빼() {
        XCTAssertEqual(CorrectionRules.correctedSyllable(for: "뺴"), "빼")
    }

    func test_correct_ssae쎼To쎄() {
        XCTAssertEqual(CorrectionRules.correctedSyllable(for: "쎼"), "쎄")
    }

    func test_correct_yae_ㅖCase_뗴To떼() {
        XCTAssertEqual(CorrectionRules.correctedSyllable(for: "뗴"), "떼")
    }

    func test_correct_yae_ㅖCase_쪠To쩨() {
        XCTAssertEqual(CorrectionRules.correctedSyllable(for: "쪠"), "쩨")
    }

    func test_noCorrect_validSyllable_때() {
        XCTAssertNil(CorrectionRules.correctedSyllable(for: "때"))
    }

    func test_noCorrect_validSyllable_가() {
        XCTAssertNil(CorrectionRules.correctedSyllable(for: "가"))
    }

    func test_noCorrect_singleConsonantInitial_걔() {
        // 걔 는 ㄱ+ㅒ 로 사전에 등재된 유효 단어이므로 교정 대상 아님
        XCTAssertNil(CorrectionRules.correctedSyllable(for: "걔"))
    }

    func test_noCorrect_singleConsonantInitial_계() {
        // 계 (ㄱ+ㅖ) 도 유효
        XCTAssertNil(CorrectionRules.correctedSyllable(for: "계"))
    }

    func test_noCorrect_nonHangul() {
        XCTAssertNil(CorrectionRules.correctedSyllable(for: "A"))
        XCTAssertNil(CorrectionRules.correctedSyllable(for: "1"))
        XCTAssertNil(CorrectionRules.correctedSyllable(for: " "))
    }

    func test_correct_preservesFinalConsonant() {
        // 떈 (ㄸ+ㅒ+ㄴ) → 땐 (ㄸ+ㅐ+ㄴ) - 받침 유지
        XCTAssertEqual(CorrectionRules.correctedSyllable(for: "떈"), "땐")
    }
}
