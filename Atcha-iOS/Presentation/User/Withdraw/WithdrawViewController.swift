//
//  WithdrawViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 8/5/25.
//

import UIKit
import SnapKit

class WithdrawViewController: BaseViewController<WithdrawViewModel> {
    
    private lazy var topNavigationBar: TitleNavigationBar = AtchaNavigationBar.title("계정 탈퇴", shouldShowCloseButton: false, onBack:  { [weak self] in
        guard let self else { return }
        navigationController?.popViewController(animated: true)
    })
    private let withdrawListStackView: UIStackView = UIStackView()
    private var withdrawCheckmarkLists: [AtchaList] = []
    private lazy var withdrawButton: AtchaButton = AtchaButton(text: "탈퇴하기", size: .h52, style: .filled(.disabled)) { [weak self] in
        self?.signOutTapped()
    }
    private let withdrawTextBox: WithDrawTextBox = AtchaTextBox.withDrawTextBox { _ in }
    private var selectedOption: WithdrawOption?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupWithdrawLists()
        setupAutoLayout()
    }
    
    // MARK: - 탈퇴사유 UI
    private func setupUI() {
        
        withdrawListStackView.axis = .vertical
        withdrawListStackView.spacing = 0
        withdrawListStackView.alignment = .fill
        withdrawListStackView.distribution = .equalSpacing
        
        withdrawTextBox.isHidden = true
        view.addSubViews(topNavigationBar, withdrawListStackView, withdrawButton, withdrawTextBox)
    }
    
    // MARK: - 탈퇴사유 AutoLayout
    private func setupAutoLayout() {
        topNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.trailing.leading.equalToSuperview()
        }
        
        withdrawListStackView.snp.makeConstraints { make in
            make.top.equalTo(topNavigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
        }
        
        withdrawTextBox.snp.makeConstraints { make in
            make.top.equalTo(withdrawListStackView.snp.bottom)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        
        withdrawButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(40)
        }
    }
    
    // MARK: - 탈퇴사유 리스트 UI
    private func setupWithdrawLists() {
        WithdrawOption.allCases.enumerated().forEach { index, withdraw in
            let listView = AtchaList(title: withdraw.title, listType: .checkmark(isOn: false))
            listView.tag = index
            
            listView.onSelect = { [weak self] selectedList in
                guard let self else { return }
                
                self.withdrawCheckmarkLists.forEach { $0.setCheckmark(false) }
                
                selectedList.setCheckmark(true)
                self.selectedOption = withdraw
                
                self.withdrawButton.updateStyle(text: "탈퇴하기", style: .filled(.white))
                
                if withdraw == .etc {
                    self.withdrawTextBox.isHidden = false
                } else {
                    self.withdrawTextBox.isHidden = true
                }
            }
            
            listView.snp.makeConstraints { make in
                make.height.equalTo(52)
            }
            
            withdrawListStackView.addArrangedSubview(listView)
            withdrawCheckmarkLists.append(listView)
        }
    }
    
    private func signOutTapped() {
        guard let option = selectedOption else { return }
        
        var reason: String?
        
        if option == .etc {
            reason = withdrawTextBox.text?.isEmpty == false ? withdrawTextBox.text : nil
        } else {
            reason = option.title
        }
        
        let request = WithdrawRequest(reason: reason)
        
        viewModel.signOutTapped(request)
    }
}
