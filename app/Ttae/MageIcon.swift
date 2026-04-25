import SwiftUI

/// Asset Catalog 의 Mage Icons (stroke 스타일) 을 일관된 사이즈/렌더링 모드로 표시하는 헬퍼.
struct MageIcon: View {
    let name: String
    var size: CGFloat = 16

    init(_ name: String, size: CGFloat = 16) {
        self.name = name
        self.size = size
    }

    var body: some View {
        Image(name)
            .renderingMode(.template)
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
    }
}
