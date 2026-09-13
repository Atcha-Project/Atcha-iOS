import DesignSystem
import Domain
import SnapKit
import UIKit

/// 레거시 로그인 바텀시트 비주얼 이식(dim 0.9 + 컨테이너 198 + 핸들 + 슬라이드업).
/// 강제 로그인이라 dim 탭·팬 다운 dismiss 제스처는 계승하지 않는다 — 핸들은 장식.
final class LoginViewController: UIViewController {
    private let viewModel: LoginViewModel

    private let dimView = UIView()
    private let containerView = UIView()
    private let sheetHandle = UIView()
    private let kakaoButton = SocialLoginButton(
        title: "카카오톡으로 3초만에 시작",
        icon: AuthFeatureAsset.kakao.image,
        textColor: .black,
        background: AuthPalette.kakaoYellow,
        iconTint: AuthPalette.kakaoSymbol
    )
    private let appleButton = SocialLoginButton(
        title: "Apple로 시작",
        icon: AuthFeatureAsset.apple.image,
        textColor: .white,
        background: .black,
        iconTint: .white
    )
    private let sheetHeight: CGFloat = 198

    init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLayout()
        bindViewModel()
        containerView.transform = CGAffineTransform(translationX: 0, y: sheetHeight)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.dimView.alpha = 1
            self.containerView.transform = .identity
        }
    }

    /// 성공 종료 연출(레거시 dismissSheet) — 시트 하강 + dim 페이드 후 실제 dismiss.
    /// 코디네이터가 부른다.
    func animateDismiss(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseIn) {
            self.dimView.alpha = 0
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.sheetHeight)
        } completion: { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }

    private func setupLayout() {
        view.backgroundColor = .clear

        dimView.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        dimView.alpha = 0
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        containerView.backgroundColor = DSColor.Background.elevated
        containerView.layer.cornerRadius = 20
        containerView.clipsToBounds = true
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(sheetHeight)
        }

        sheetHandle.backgroundColor = DSColor.Fill.highlight
        sheetHandle.layer.cornerRadius = 2
        containerView.addSubview(sheetHandle)
        sheetHandle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DSSpacing.sm12)
            make.centerX.equalToSuperview()
            make.width.equalTo(40)
            make.height.equalTo(4)
        }

        let buttonStack = UIStackView(arrangedSubviews: [kakaoButton, appleButton])
        buttonStack.axis = .vertical
        buttonStack.spacing = DSSpacing.sm12
        containerView.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview().inset(DSSpacing.lg)
            make.bottom.equalToSuperview().inset(40)
        }

        kakaoButton.addTarget(self, action: #selector(didTapKakao), for: .touchUpInside)
        appleButton.addTarget(self, action: #selector(didTapApple), for: .touchUpInside)
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        viewModel.onEvent = { [weak self] event in
            self?.handle(event)
        }
        render(viewModel.state)
    }

    private func render(_ state: LoginViewModel.State) {
        let isLoading = state != .idle
        kakaoButton.isEnabled = !isLoading
        appleButton.isEnabled = !isLoading
    }

    private func handle(_ event: LoginViewModel.Event) {
        switch event {
        case let .showFailureToast(message):
            DSToast.show(message, in: view)
        }
    }

    @objc private func didTapKakao() {
        viewModel.kakaoTapped()
    }

    @objc private func didTapApple() {
        viewModel.appleTapped()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
