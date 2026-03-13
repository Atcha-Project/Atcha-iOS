//
//  WebViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/19/25.
//

import Foundation
import WebKit

final class WebViewController: BaseViewController<BaseViewModel> {
    private lazy var navigationBar: TitleNavigationBar = AtchaNavigationBar.title("개인정보 처리방침", shouldShowCloseButton: false, onBack:  { [weak self] in
        guard let self else { return }
        navigationController?.popViewController(animated: true)
    })
    
    private let webView = WKWebView()
    @Published private(set) var type: WebViewType
    
    enum WebViewType {
        case term
        case form
        
        var urlStr: String {
            switch self {
            case .form: return "https://forms.gle/56cbZmtZR3fUywgi9"
            case .term: return "https://mammoth-cheese-88e.notion.site/1008a99e3bbe80e88468c11f09c5a2dc?pvs=4"
            }
        }
        
        var title: String {
            switch self {
            case .form: return "피드백"
            case .term: return "개인정보 처리방침"
            }
        }
    }
    
    init(type: WebViewType) {
        self.type = type
        super.init(viewModel: .init())
    }
    
    @MainActor required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupAutoLayout()
        bind()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if type == .term {
            amp_track(.term)
        }
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
    
    private func bind() {
        $type
            .receive(on: RunLoop.main)
            .sink { [weak self] type in
                guard let self else { return }
                loadWebPage(type: type)
                navigationBar.updateTitle(type.title)
            }
            .store(in: &cancellables)
    }
    
    private func loadWebPage(type: WebViewType) {
        guard let url = URL(string: type.urlStr) else { return }
        let request = URLRequest(url: url)
        webView.load(request)
    }
}
