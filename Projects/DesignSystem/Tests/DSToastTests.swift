@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSToastTests {
    @Test
    func showAttachesToastToHostView() {
        let host = UIView()
        let toast = DSToast(message: "저장되었어요")
        toast.show(in: host)
        #expect(toast.superview === host)
        toast.dismiss(animated: false)
    }

    @Test
    func actionToastRendersActionTitleAndFiresHandler() {
        var fired = false
        let toast = DSToast(
            message: "알람 권한이 꺼져 있어요",
            action: .init(title: "설정 이동") { fired = true }
        )
        #expect(renderedTexts(in: toast).contains("설정 이동"))

        toast.handleActionTap()
        #expect(fired)
    }

    @Test
    func staticShowReplacesPreviousToast() {
        let host = UIView()
        let first = DSToast.show("첫 번째", in: host)
        let second = DSToast.show("두 번째", in: host)

        #expect(first.superview == nil)
        #expect(second.superview === host)
        second.dismiss(animated: false)
    }

    @Test
    func unanimatedDismissRemovesFromHierarchy() {
        let host = UIView()
        let toast = DSToast(message: "완료")
        toast.show(in: host)
        toast.dismiss(animated: false)
        #expect(toast.superview == nil)
    }
}
