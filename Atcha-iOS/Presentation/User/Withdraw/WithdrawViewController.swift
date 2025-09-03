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
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let withdrawListStackView: UIStackView = UIStackView()
    private var withdrawCheckmarkLists: [AtchaList] = []
    private lazy var withdrawButton: AtchaButton = AtchaButton(text: "탈퇴하기", size: .h52, style: .filled(.disabled)) { [weak self] in
        self?.showWithdrawPopup()
    }
    private lazy var withdrawTextBox: WithDrawTextBox = AtchaTextBox.withDrawTextBox { [weak self] text in
        self?.updateWithdrawButtonStateForEtc(text)
    }
    private var selectedOption: WithdrawOption?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupWithdrawLists()
        setupAutoLayout()
    }
    
    // MARK: - 탈퇴사유 UI
    private func setupUI() {
        
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.isScrollEnabled = false
        
        view.addSubViews(topNavigationBar, scrollView, withdrawButton)
        
        scrollView.addSubview(contentView)
        contentView.addSubViews(withdrawListStackView, withdrawTextBox)
        
        withdrawListStackView.axis = .vertical
        withdrawListStackView.spacing = 0
        withdrawListStackView.alignment = .fill
        withdrawListStackView.distribution = .equalSpacing
        
        withdrawTextBox.isHidden = true
        
    }
    
    // MARK: - 탈퇴사유 AutoLayout
    private func setupAutoLayout() {
        topNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.trailing.leading.equalToSuperview()
        }
        
        scrollView.snp.makeConstraints { make in
            make.top.equalTo(topNavigationBar.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(withdrawButton.snp.top).offset(-16)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.equalTo(scrollView.frameLayoutGuide)
        }
        
        withdrawListStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
        
        withdrawTextBox.snp.makeConstraints { make in
            make.top.equalTo(withdrawListStackView.snp.bottom)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(12)
        }
        
        withdrawButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(40)
        }
    }
    
    // MARK: - 탈퇴사유 리스트 UI
    private func setupWithdrawLists() {
        withdrawCheckmarkLists.removeAll()
        
        WithdrawOption.allCases.enumerated().forEach { index, withdraw in
            let listView = AtchaList(title: withdraw.title, listType: .radioButton(isOn: false))
            
            listView.setRadio(false)
            
            listView.onSelect = { [weak self] selected in
                guard let self else { return }
                
                self.withdrawCheckmarkLists.forEach { $0.setRadio(false) }
                selected.setRadio(true)
                let isEtc = (withdraw == .etc)
                self.withdrawTextBox.isHidden = !isEtc
                
                if isEtc {
                    scrollView.isScrollEnabled = true
                    self.withdrawTextBox.focusTextView()
                    self.withdrawButton.updateStyle(text: "탈퇴하기", style: .filled(.disabled))
                    self.withdrawButton.isEnabled = false
                    self.updateWithdrawButtonStateForEtc(self.withdrawTextBox.text ?? "")
                } else {
                    scrollView.isScrollEnabled = false
                    self.withdrawTextBox.resignTextView()
                    self.withdrawButton.updateStyle(text: "탈퇴하기", style: .filled(.white))
                    self.withdrawButton.isEnabled = true
                }
                self.selectedOption = withdraw
                
            }
            
            listView.snp.makeConstraints { $0.height.equalTo(52) }
            withdrawListStackView.addArrangedSubview(listView)
            withdrawCheckmarkLists.append(listView)
        }
    }
    
    private func updateWithdrawButtonStateForEtc(_ text: String) {
        guard selectedOption == .etc else { return }
        let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        withdrawButton.updateStyle(text: "탈퇴하기", style: hasText ? .filled(.white) : .filled(.disabled))
        withdrawButton.isEnabled = hasText
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
    
    private func showWithdrawPopup() {
        guard let option = selectedOption else {
            return
        }
        if option == .etc, (withdrawTextBox.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return
        }
        
        let popupVM = AtchaPopupViewModel(info: .withdraw)
        let popupVC = AtchaPopupViewController(viewModel: popupVM)
        
        popupVC.confirmButton.addAction(UIAction { [weak self, weak popupVC] _ in
            guard let self else { return }
            popupVC?.dismiss(animated: true)
            
            self.withdrawButton.isEnabled = false
            self.signOutTapped()
        }, for: .touchUpInside)
        
        popupVC.cancelButton.addAction(UIAction { [weak popupVC] _ in
            popupVC?.dismiss(animated: true)
        }, for: .touchUpInside)
        
        popupVC.modalPresentationStyle = .overFullScreen
        present(popupVC, animated: false)
    }
}
