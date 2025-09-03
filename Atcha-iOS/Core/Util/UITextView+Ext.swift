//
//  UITextView+Ext.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/5/25.
//

import UIKit
import ObjectiveC

private struct UITextViewDoneKey {
    static var handler = "UITextViewDoneHandlerKey"
}

extension UITextView {
    var onDoneTapped: (() -> Void)? {
        get { objc_getAssociatedObject(self, &UITextViewDoneKey.handler) as? (() -> Void) }
        set { objc_setAssociatedObject(self, &UITextViewDoneKey.handler, newValue, .OBJC_ASSOCIATION_COPY_NONATOMIC) }
    }

    func addDoneButtonOnKeyboard(title: String = "완료") {
        let doneToolbar = UIToolbar(
            frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 44)
        )
        doneToolbar.barStyle = .default

        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let done = UIBarButtonItem(title: title, style: .done, target: self, action: #selector(self.doneButtonAction))

        doneToolbar.items = [flexSpace, done]
        doneToolbar.sizeToFit()

        self.inputAccessoryView = doneToolbar
    }

    @objc private func doneButtonAction() {
        onDoneTapped?()
        self.resignFirstResponder()
    }
}
