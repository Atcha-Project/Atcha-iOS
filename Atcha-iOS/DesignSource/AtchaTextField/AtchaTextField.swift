//
//  AtchaTextField.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/19/25.
//

import Foundation

enum AtchaTextField {
    // 집 주소 등록 시 사용하는 TextField
    static func registerTextField(
        onTextChange: ((String) -> Void)? = nil,
        onTextReset: (() -> Void)? = nil,
        onTextSubmit: ((String) -> Void)? = nil
    ) -> RegisterTextField {
        let textField = RegisterTextField(onTextChange: onTextChange)
        textField.onTextReset = onTextReset
        textField.onTextSubmit = onTextSubmit
        return textField
    }
    
    // 초록 점이 포함된 검색 TextField
    static func searchTextField(
        onTextChange: ((String) -> Void)? = nil,
        onTextReset: (() -> Void)? = nil ) -> SearchTextField {
            let textField = SearchTextField(onTextChange: onTextChange)
            textField.onTextReset = onTextReset
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
