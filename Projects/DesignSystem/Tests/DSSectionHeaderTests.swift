@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSSectionHeaderTests {
    @Test
    func intrinsicHeightIs40() {
        let header = DSSectionHeader(title: "최근 검색")
        #expect(header.intrinsicContentSize.height == 40)
    }

    @Test
    func rendersTitle() {
        let header = DSSectionHeader(title: "최근 검색")
        #expect(renderedTexts(in: header).contains("최근 검색"))
    }

    @Test
    func actionButtonHiddenWithoutActionTitle() {
        let header = DSSectionHeader(title: "최근 검색")
        let button = header.subviews.compactMap { $0 as? UIButton }.first
        #expect(button?.isHidden == true)
    }

    @Test
    func actionTapFiresCallback() {
        let header = DSSectionHeader(title: "최근 검색", actionTitle: "전체 삭제")
        var fired = false
        header.onAction = { fired = true }
        header.handleActionTap()
        #expect(fired)

        let button = header.subviews.compactMap { $0 as? UIButton }.first
        #expect(button?.isHidden == false)
    }
}
