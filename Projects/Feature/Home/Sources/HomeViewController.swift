import DesignSystem
import SnapKit
import UIKit

final class HomeViewController: UIViewController {
    // VC strongly owns the VM; the VM's closures capture the VC weakly.
    private let viewModel: HomeViewModel

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DSFont.title()
        label.textColor = DSColor.textPrimary
        label.textAlignment = .center
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = DSFont.body()
        label.textColor = DSColor.textPrimary
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let refreshButton = DSButton(title: "새로고침")
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
        viewModel.viewDidLoad()
    }

    private func configureUI() {
        view.backgroundColor = DSColor.background
        navigationItem.title = "홈"

        [titleLabel, subtitleLabel, refreshButton, activityIndicator]
            .forEach(view.addSubview)

        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(DSSpacing.md)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(DSSpacing.sm)
            make.leading.trailing.equalToSuperview().inset(DSSpacing.md)
        }
        refreshButton.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(DSSpacing.lg)
            make.centerX.equalToSuperview()
        }
        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(titleLabel.snp.top).offset(-DSSpacing.lg)
        }

        refreshButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.refresh() },
            for: .touchUpInside
        )
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        render(viewModel.state)
    }

    private func render(_ state: HomeViewModel.State) {
        switch state {
        case .idle:
            break
        case .loading:
            activityIndicator.startAnimating()
            titleLabel.text = nil
            subtitleLabel.text = nil
        case let .loaded(viewData):
            activityIndicator.stopAnimating()
            titleLabel.text = viewData.titleText
            subtitleLabel.text = viewData.subtitleText
        case let .failed(message):
            activityIndicator.stopAnimating()
            titleLabel.text = "앗차!"
            subtitleLabel.text = message
        }
    }
}
