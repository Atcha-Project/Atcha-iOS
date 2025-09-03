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
    private let contentStackView = UIStackView()
    
    private let withdrawListStackView: UIStackView = UIStackView()
    private var withdrawCheckmarkLists: [AtchaList] = []
    
    private lazy var withdrawButton: AtchaButton = AtchaButton(
        text: "탈퇴하기",
        size: .h52,
        style: .filled(.disabled)
    ) { [weak self] in
        self?.showWithdrawPopup()
    }
    
    private lazy var withdrawTextBox: WithDrawTextBox = AtchaTextBox.withDrawTextBox { [weak self] text in
        self?.updateWithdrawButtonStateForEtc(text)
    }
    
    /// 키보드 높이(+20)에 맞춰 가변 높이를 가지는 스페이서
    private let bottomSpacer = UIView()
    
    private var selectedOption: WithdrawOption?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupWithdrawLists()
        setupAutoLayout()
    }
    
    // MARK: - UI
    private func setupUI() {
        scrollView.isScrollEnabled = false
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        
        view.addSubViews(topNavigationBar, scrollView, withdrawButton)
        
        scrollView.addSubview(contentView)
        contentView.addSubview(contentStackView)
        
        contentStackView.axis = .vertical
        contentStackView.spacing = 12
        contentStackView.alignment = .fill
        contentStackView.distribution = .fill
        
        // 스택 구성: 목록 -> 텍스트박스 -> 키보드 대응 스페이서
        contentStackView.addArrangedSubview(withdrawListStackView)
        contentStackView.addArrangedSubview(withdrawTextBox)
        contentStackView.addArrangedSubview(bottomSpacer)
        
        withdrawListStackView.axis = .vertical
        withdrawListStackView.spacing = 0
        withdrawListStackView.alignment = .fill
        withdrawListStackView.distribution = .fill
        
        withdrawTextBox.isHidden = true
    }
    
    // MARK: - AutoLayout
    private func setupAutoLayout() {
        topNavigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.equalToSuperview()
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
        
        contentStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 16, bottom: 12, right: 16))
        }
        
        withdrawButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(40) // 고정 버튼
        }
        
        // 키보드 높이에 따라 바닥 스페이서가 늘어나도록 (iOS 15+)
        if #available(iOS 15.0, *) {
            bottomSpacer.translatesAutoresizingMaskIntoConstraints = false
            let guide = view.keyboardLayoutGuide
            NSLayoutConstraint.activate([
                bottomSpacer.heightAnchor.constraint(equalTo: guide.heightAnchor, constant: 20)
            ])
        } else {
            bottomSpacer.snp.makeConstraints { $0.height.equalTo(20) }
        }
    }
    
    // MARK: - 탈퇴사유 리스트
    private func setupWithdrawLists() {
        withdrawCheckmarkLists.removeAll()
        
        WithdrawOption.allCases.forEach { withdraw in
            let listView = AtchaList(title: withdraw.title, listType: .radioButton(isOn: false))
            listView.setRadio(false)
            
            listView.onSelect = { [weak self] selected in
                guard let self else { return }
                
                self.withdrawCheckmarkLists.forEach { $0.setRadio(false) }
                selected.setRadio(true)
                
                let isEtc = (withdraw == .etc)
                self.withdrawTextBox.isHidden = !isEtc
                
                if isEtc {
                    self.scrollView.isScrollEnabled = true
                    self.scrollView.alwaysBounceVertical = true
                    
                    self.withdrawTextBox.focusTextView()
                    self.withdrawButton.updateStyle(text: "탈퇴하기", style: .filled(.disabled))
                    self.withdrawButton.isEnabled = false
                    self.updateWithdrawButtonStateForEtc(self.withdrawTextBox.text ?? "")
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.scrollTextBoxIntoView(extra: 20)
                    }
                } else {
                    self.withdrawTextBox.resignTextView()
                    self.scrollView.setContentOffset(.zero, animated: true) // 선택: 상단으로 복귀
                    self.scrollView.isScrollEnabled = false
                    self.scrollView.alwaysBounceVertical = false
                    
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
    
    // MARK: - 텍스트박스 가시화 스크롤
    private func scrollTextBoxIntoView(extra: CGFloat = 20) {
        let rectInContent = contentView.convert(withdrawTextBox.bounds, from: withdrawTextBox)
        let target = rectInContent.insetBy(dx: 0, dy: -extra)
        scrollView.scrollRectToVisible(target, animated: true)
    }
    
    // MARK: - 버튼 상태 업데이트
    private func updateWithdrawButtonStateForEtc(_ text: String) {
        guard selectedOption == .etc else { return }
        let hasText = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        withdrawButton.updateStyle(text: "탈퇴하기", style: hasText ? .filled(.white) : .filled(.disabled))
        withdrawButton.isEnabled = hasText
    }
    
    // MARK: - 서버 요청
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
    
    // MARK: - 팝업
    private func showWithdrawPopup() {
        guard let option = selectedOption else { return }
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

