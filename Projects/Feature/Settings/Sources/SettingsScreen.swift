import DesignSystem
import SnapKit
import UIKit

/// 설정 플로우 화면 공통 골격 — DSNavigationBar(시스템 내비바 대체) + 토스트 호스트 +
/// 숨긴 내비바가 죽이는 스와이프 백 복구(Search와 같은 규약).
class SettingsScreen: UIViewController, UIGestureRecognizerDelegate {
    let navigationBar: DSNavigationBar
    let contentView = UIView()

    init(title: String) {
        navigationBar = DSNavigationBar(style: .title(title))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DSColor.Background.base
        navigationBar.onBack = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        [navigationBar, contentView].forEach(view.addSubview)
        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        contentView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    func showToast(_ message: String) {
        DSToast.show(message, in: view)
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }
}
