@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSTextFieldTests {
    @Test
    func intrinsicHeightIs52() {
        let field = DSTextField(placeholder: "도착지")
        #expect(field.intrinsicContentSize.height == 52)
    }

    @Test
    func setTextTogglesClearButtonVisibility() {
        let field = DSTextField(placeholder: "도착지")
        let clearButton = field.subviews
            .flatMap(\.subviews)
            .compactMap { $0 as? UIButton }
            .first

        field.setText("강남역")
        #expect(field.text == "강남역")
        #expect(clearButton?.isHidden == false)

        field.setText("")
        #expect(clearButton?.isHidden == true)
    }

    @Test
    func clearTapEmptiesTextAndFiresCallbacks() {
        let field = DSTextField(placeholder: "도착지")
        field.setText("강남역")

        var cleared = false
        var changedTo: String?
        field.onClear = { cleared = true }
        field.onTextChange = { changedTo = $0 }

        field.handleClearTap()

        #expect(field.text.isEmpty)
        #expect(cleared)
        #expect(changedTo == "")
    }

    @Test
    func focusTogglesAccentBorder() {
        let field = DSTextField(placeholder: "도착지")
        let proxy = UITextField()

        field.textFieldDidBeginEditing(proxy)
        #expect(field.layer.borderWidth == 1.5)

        field.textFieldDidEndEditing(proxy)
        #expect(field.layer.borderWidth == 0)
    }
}
