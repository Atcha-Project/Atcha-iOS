//
//  AtchaListType.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/18/25.
//

import Foundation

enum AtchaListType {
    case checkmark(isOn: Bool)
    case radioButton(isOn: Bool)
    case text(String)
    case arrow
    case button(title: String, action: () -> Void)
    case none
}
