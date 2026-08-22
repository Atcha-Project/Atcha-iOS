@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSEmptyStateTests {
    @Test
    func configureRendersTitleAndMessage() {
        let empty = DSEmptyState(
            content: .init(
                icon: DSIcon.illustCharacterGray,
                title: "오늘 막차가 끊겼어요",
                message: "내일 다시 검색해 주세요"
            )
        )
        let texts = renderedTexts(in: empty)
        #expect(texts.contains("오늘 막차가 끊겼어요"))
        #expect(texts.contains("내일 다시 검색해 주세요"))
    }

    @Test
    func actionButtonHiddenWithoutActionTitle() {
        let empty = DSEmptyState(content: .init(title: "경로 없음"))
        let buttons = allSubviews(of: empty).compactMap { $0 as? DSButton }
        #expect(buttons.isEmpty)
    }

    @Test
    func actionButtonAppearsAndFiresCallback() {
        let empty = DSEmptyState(
            content: .init(title: "오늘 막차가 끊겼어요", actionTitle: "다시 검색")
        )
        var fired = false
        empty.onAction = { fired = true }

        let buttons = allSubviews(of: empty).compactMap { $0 as? DSButton }
        #expect(buttons.count == 1)

        empty.handleActionTap()
        #expect(fired)
    }

    @Test
    func reconfigureSwapsActionTitle() {
        let empty = DSEmptyState(content: .init(title: "a", actionTitle: "다시 검색"))
        empty.configure(with: .init(title: "b", actionTitle: "설정 이동"))

        let buttons = allSubviews(of: empty).compactMap { $0 as? DSButton }
        #expect(buttons.count == 1)
        #expect(buttons.first?.configuration?.title == "설정 이동")
    }

    private func allSubviews(of view: UIView) -> [UIView] {
        view.subviews + view.subviews.flatMap(allSubviews(of:))
    }
}
