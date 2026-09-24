import DesignSystem
import SnapKit
import UIKit

final class HomeAddressViewController: SettingsScreen {
    // VC strongly owns the VM; the VM's closures capture the VC weakly.
    private let viewModel: HomeAddressViewModel
    private let searchField = DSTextField(placeholder: "지번, 도로명, 건물명으로 검색")
    private let currentLocationButton = DSButton(
        title: "현재 위치로 설정", style: .secondary, size: .medium, icon: DSIcon.myLocation24
    )
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyState = DSEmptyState(content: .init(title: ""))
    private let activityIndicator = UIActivityIndicatorView(style: .medium)
    private var places: [HomeAddressViewModel.PlaceViewData] = []

    init(viewModel: HomeAddressViewModel) {
        self.viewModel = viewModel
        super.init(title: "우리집 설정")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        bind()
    }

    private func configureUI() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DSListCell.self, forCellReuseIdentifier: DSListCell.reuseIdentifier)
        emptyState.isHidden = true
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = DSColor.Text.primary

        [searchField, currentLocationButton, tableView, emptyState, activityIndicator]
            .forEach(contentView.addSubview)
        searchField.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(DSSpacing.sm)
            make.leading.trailing.equalToSuperview().inset(DSSpacing.md)
        }
        currentLocationButton.snp.makeConstraints { make in
            make.top.equalTo(searchField.snp.bottom).offset(DSSpacing.sm12)
            make.leading.trailing.equalToSuperview().inset(DSSpacing.md)
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(currentLocationButton.snp.bottom).offset(DSSpacing.sm)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyState.snp.makeConstraints { make in
            make.top.equalTo(tableView).offset(DSSpacing.xl)
            make.leading.trailing.equalToSuperview().inset(DSSpacing.md)
        }
        activityIndicator.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(tableView).offset(DSSpacing.xl)
        }

        searchField.onTextChange = { [weak self] text in
            self?.viewModel.keywordDidChange(text)
        }
        currentLocationButton.addAction(
            UIAction { [weak self] _ in self?.viewModel.useCurrentLocationTapped() },
            for: .touchUpInside
        )
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        viewModel.onSavingChange = { [weak self] isSaving in
            self?.currentLocationButton.isEnabled = !isSaving
            self?.tableView.isUserInteractionEnabled = !isSaving
            if isSaving {
                self?.activityIndicator.startAnimating()
            } else {
                self?.activityIndicator.stopAnimating()
            }
        }
        viewModel.onToast = { [weak self] message in
            self?.showToast(message)
        }
        render(viewModel.state)
    }

    private func render(_ state: HomeAddressViewModel.State) {
        activityIndicator.stopAnimating()
        emptyState.isHidden = true
        switch state {
        case .idle:
            places = []
        case .loading:
            places = []
            activityIndicator.startAnimating()
        case let .places(items):
            places = items
        case .empty:
            places = []
            emptyState.configure(with: .init(title: "검색 결과가 없어요"))
            emptyState.isHidden = false
        case let .failed(message):
            places = []
            emptyState.configure(with: .init(title: message))
            emptyState.isHidden = false
        }
        tableView.reloadData()
    }
}

extension HomeAddressViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        places.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DSListCell.reuseIdentifier, for: indexPath)
        let place = places[indexPath.row]
        (cell as? DSListCell)?.configure(with: .init(
            leadingIcon: DSIcon.place24, title: place.name, subtitle: place.address
        ))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        view.endEditing(true)
        viewModel.didSelectPlace(at: indexPath.row)
    }
}
