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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 16.0, *) {
            view.keyboardLayoutGuide.followsUndockedKeyboard = true
        }
    }
    
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
        scrollView.alwaysBounceVertical = false
        
        view.addSubViews(topNavigationBar, scrollView, withdrawButton)
        
        scrollView.addSubview(contentView)
        contentView.addSubViews(withdrawListStackView, withdrawTextBox)
        
        withdrawListStackView.axis = .vertical
        withdrawListStackView.spacing = 0
        withdrawListStackView.alignment = .fill
        withdrawListStackView.distribution = .fill
        
        withdrawTextBox.isHidden = true
        textboxDone()
        
        withdrawTextBox.onTap = { [weak self] in
                guard let self = self else { return }
                if !self.withdrawTextBox.isEditing {
                    self.withdrawTextBox.focusTextView()
                }
                // 키보드가 뜨는 타이밍 고려 → 다음 런루프에 적용
                DispatchQueue.main.async {
                    self.applyEtcInsetsAndScroll()
                }
            }
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
            make.bottom.equalTo(withdrawButton.snp.top)
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
                    applyEtcInsetsAndScroll()
                    
                    self.withdrawTextBox.focusTextView()
                    self.withdrawButton.updateStyle(text: "탈퇴하기", style: .filled(.disabled))
                    self.withdrawButton.isEnabled = false
                    self.updateWithdrawButtonStateForEtc(self.withdrawTextBox.text ?? "")
                } else {
                    scrollView.isScrollEnabled = true
                    scrollView.alwaysBounceVertical = false
                    self.withdrawTextBox.resignTextView()
                    self.withdrawButton.updateStyle(text: "탈퇴하기", style: .filled(.white))
                    self.withdrawButton.isEnabled = true
                    
                    scrollView.contentInset.bottom = 0
                    scrollView.verticalScrollIndicatorInsets.bottom = 0
                    
                    view.layoutIfNeeded()
                    
                    let topY = -scrollView.adjustedContentInset.top
                    scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: topY), animated: true)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self.scrollView.isScrollEnabled = false
                    }
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
    
    private func textboxDone() {
        withdrawTextBox.onDone = { [weak self] in
            guard let self = self else { return }

            self.scrollView.isScrollEnabled = true
            self.scrollView.alwaysBounceVertical = false
            self.withdrawTextBox.resignTextView()

            if self.selectedOption == .etc {
                self.updateWithdrawButtonStateForEtc(self.withdrawTextBox.text ?? "")
            } else {
                self.withdrawButton.updateStyle(text: "탈퇴하기", style: .filled(.white))
                self.withdrawButton.isEnabled = true
            }

            // 인셋 원복 + 스크롤 정리
            self.scrollView.contentInset.bottom = 0
            self.scrollView.verticalScrollIndicatorInsets.bottom = 0
            self.view.layoutIfNeeded()

            let topY = -self.scrollView.adjustedContentInset.top
            self.scrollView.setContentOffset(CGPoint(x: self.scrollView.contentOffset.x, y: topY), animated: true)

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.scrollView.isScrollEnabled = false
            }
        }
    }
    
    private func applyEtcInsetsAndScroll() {
        guard selectedOption == .etc else { return }

        // 스크롤 가능/레이아웃 반영
        scrollView.isScrollEnabled = true
        scrollView.alwaysBounceVertical = true
        view.layoutIfNeeded()

        // 키보드가 '하단에서 실제로 가리는 높이' 계산 (undocked 대응)
        let kFrame = view.keyboardLayoutGuide.layoutFrame
        let bottomOcclusion = max(0, view.bounds.maxY - kFrame.minY)

        // 인셋 적용
        scrollView.contentInset.bottom = bottomOcclusion + 240
        scrollView.verticalScrollIndicatorInsets.bottom = bottomOcclusion

        // 최하단으로 + 텍스트박스 가시 영역 보장
        DispatchQueue.main.async {
            let minY = -self.scrollView.adjustedContentInset.top
            let maxY = max(
                minY,
                self.scrollView.contentSize.height - self.scrollView.bounds.height + self.scrollView.adjustedContentInset.bottom
            )
            self.scrollView.setContentOffset(CGPoint(x: self.scrollView.contentOffset.x, y: maxY), animated: true)

            let rect = self.withdrawTextBox.convert(self.withdrawTextBox.bounds, to: self.scrollView)
            self.scrollView.scrollRectToVisible(rect.insetBy(dx: 0, dy: -16), animated: true)
        }
    }
}
