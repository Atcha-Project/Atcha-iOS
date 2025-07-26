//
//  AtchaTextBox.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/27/25.
//

import Foundation

enum AtchaTextBox {
    // 탈퇴 사유 작성 TextBox
    static func withDrawTextBox(
        onTextChange: ((String) -> Void)? = nil
    ) -> WithDrawTextBox {
        let textField = WithDrawTextBox(onTextChange: onTextChange)
        return textField
    }
    
    // MARK: - 사용 예시
    //
    //  registerTextField = AtchaTextField.registerTextField(
    //      onTextChange: { text in
    //          print("입력값: \(text)")
    //      },
    //      onTextReset: {
    //          print("리셋 버튼 클릭됨")
    //      }
    //  )
}
