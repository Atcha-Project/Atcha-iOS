//
//  WebViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/19/25.
//

import Foundation
import WebKit

final class WebViewController: BaseViewController<BaseViewModel> {
    private lazy var navigationBar: TitleNavigationBar = AtchaNavigationBar.title("개인정보 처리방침", onClose: { [weak self] in
        guard let self else { return }
        navigationController?.popViewController(animated: true)
    })
    private let webView = WKWebView()
    private let urlString = "https://mammoth-cheese-88e.notion.site/1008a99e3bbe80e88468c11f09c5a2dc?pvs=4"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAutoLayout()
        loadWebPage()
    }
    
    private func setupUI() {
        view.addSubViews(navigationBar, webView)
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    private func setupAutoLayout() {
        navigationBar.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            $0.leading.trailing.equalToSuperview()
        }
        webView.snp.makeConstraints {
            $0.top.equalTo(navigationBar.snp.bottom)
            $0.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func loadWebPage() {
        guard let url = URL(string: urlString) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
