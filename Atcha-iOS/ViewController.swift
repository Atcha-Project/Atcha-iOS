//
//  ViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/15/25.
//

import UIKit
import SnapKit  // 오토레이아웃 사용 시 필요

class ViewController: UIViewController {

    private var registerTextField: RegisterTextField!
    private var searchTextField: SearchTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        setupRegisterTextField()
        setupSearchTextField()
    }

    private func setupRegisterTextField() {
        registerTextField = AtchaTextField.registerTextField(
            onTextChange: { text in
                print("📌 Register 입력값:", text)
            },
            onTextReset: {
                print("♻️ Register 리셋됨")
            }
        )

        view.addSubview(registerTextField)

        registerTextField.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(40)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(40)
        }
    }

    private func setupSearchTextField() {
        searchTextField = AtchaTextField.searchTextField(
            onTextChange: { text in
                print("📌 Search 입력값:", text)
            },
            onTextReset: {
                print("♻️ Search 리셋됨")
            }
        )

        view.addSubview(searchTextField)

        searchTextField.snp.makeConstraints {
            $0.top.equalTo(registerTextField.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(48)
        }
    }
}
