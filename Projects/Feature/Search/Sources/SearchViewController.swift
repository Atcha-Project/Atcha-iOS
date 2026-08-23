import DesignSystem
import SnapKit
import UIKit

final class SearchViewController: UIViewController {
    // VC strongly owns the VM; the VM's closures capture the VC weakly.
    private let viewModel: SearchViewModel

    private enum Row {
        case place(PlaceViewData, showsDelete: Bool)
        case routeCard(RouteViewData)
        case more(isExpanded: Bool)
        case alternative(index: Int, viewData: RouteViewData)
    }

    private let navigationBar = DSNavigationBar(style: .backOnly)
    private let departureField = DSTextField(placeholder: "출발지 입력")
    private let arrivalField = DSTextField(placeholder: "도착지 입력", showsAccentDot: true)
    private let fieldsStack = UIStackView()
    private let separator = DSSeparator(axis: .horizontal)
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyState = DSEmptyState(content: .init(title: ""))
    private let activityIndicator = UIActivityIndicatorView(style: .medium)

    private var rows: [Row] = []
    private var showsRecentHeader = false
    private var focusedField: SearchViewModel.Field?

    init(viewModel: SearchViewModel) {
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

    // DSNavigationBar가 시스템 내비바를 대체한다.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // 숨긴 내비바는 스와이프 백 제스처를 죽인다 — delegate를 잡아 되살린다(Phase 17).
    // 코디네이터 정리는 pop 경로 공통의 didShow(SearchCoordinator)가 수행한다.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func configureUI() {
        view.backgroundColor = DSColor.Background.base

        fieldsStack.axis = .vertical
        fieldsStack.spacing = DSSpacing.sm
        [departureField, arrivalField].forEach(fieldsStack.addArrangedSubview)

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.estimatedRowHeight = 200
        tableView.sectionHeaderTopPadding = 0
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DSListCell.self, forCellReuseIdentifier: DSListCell.reuseIdentifier)
        tableView.register(
            SearchRouteCardCell.self,
            forCellReuseIdentifier: SearchRouteCardCell.reuseIdentifier
        )

        emptyState.isHidden = true

        [navigationBar, fieldsStack, separator, tableView, emptyState, activityIndicator]
            .forEach(view.addSubview)

        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        fieldsStack.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom).offset(DSSpacing.xs)
            make.leading.trailing.equalToSuperview().inset(DSSpacing.md)
        }
        separator.snp.makeConstraints { make in
            make.top.equalTo(fieldsStack.snp.bottom).offset(DSSpacing.sm12)
            make.leading.trailing.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        emptyState.snp.makeConstraints { make in
            make.center.equalTo(tableView)
            make.leading.trailing.equalToSuperview().inset(DSSpacing.lg)
        }
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(tableView)
        }

        navigationBar.onBack = { [weak self] in self?.viewModel.didTapBack() }
        departureField.onTextChange = { [weak self] text in
            self?.viewModel.keywordDidChange(text, in: .departure)
        }
        arrivalField.onTextChange = { [weak self] text in
            self?.viewModel.keywordDidChange(text, in: .arrival)
        }
        departureField.onSubmit = { [weak self] in self?.view.endEditing(true) }
        arrivalField.onSubmit = { [weak self] in self?.view.endEditing(true) }

        // DSTextField는 포커스 시작 콜백이 없다 — 탭 제스처로 활성 슬롯을 표시.
        let departureTap = UITapGestureRecognizer(target: self, action: #selector(departureFieldTapped))
        departureTap.cancelsTouchesInView = false
        departureField.addGestureRecognizer(departureTap)
        let arrivalTap = UITapGestureRecognizer(target: self, action: #selector(arrivalFieldTapped))
        arrivalTap.cancelsTouchesInView = false
        arrivalField.addGestureRecognizer(arrivalTap)
    }

    @objc private func departureFieldTapped() {
        viewModel.fieldDidBeginEditing(.departure)
    }

    @objc private func arrivalFieldTapped() {
        viewModel.fieldDidBeginEditing(.arrival)
    }

    private func bind() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        viewModel.onFieldsChange = { [weak self] fields in
            self?.renderFields(fields)
        }
        emptyState.onAction = { [weak self] in
            self?.viewModel.didTapEmptyAction()
        }
        render(viewModel.state)
        renderFields(viewModel.fields)
    }

    private func render(_ state: SearchViewModel.State) {
        activityIndicator.stopAnimating()
        emptyState.isHidden = true
        showsRecentHeader = false

        switch state {
        case .idle:
            rows = []
        case let .recent(places):
            showsRecentHeader = true
            rows = places.map { .place($0, showsDelete: true) }
            // 빈 상태 2종(Phase 17) — 백지 대신 다음 행동을 말한다. 액션 버튼 없음
            // (타이핑이 곧 회복 경로). 빈 목록엔 "최근 검색" 헤더도 없다(rows.isEmpty 가드).
            if places.isEmpty {
                showEmptyState(
                    title: "최근 검색이 없어요",
                    message: "도착지를 검색해 막차 시간을 확인해 보세요"
                )
            }
        case let .places(places):
            rows = places.map { .place($0, showsDelete: false) }
            if places.isEmpty {
                showEmptyState(
                    title: "검색 결과가 없어요",
                    message: "다른 키워드로 검색해 보세요"
                )
            }
        case .loadingPlaces:
            // 키워드 검색 로딩(Phase 17) — loadingRoutes와 달리 키보드를 유지한다
            // (타이핑 계속이 정상 흐름).
            rows = []
            activityIndicator.startAnimating()
        case .loadingRoutes:
            rows = []
            view.endEditing(true)
            activityIndicator.startAnimating()
        case let .routes(viewData):
            rows = routeRows(from: viewData)
        case .serviceEnded:
            rows = []
            showEmptyState(
                title: "오늘 막차가 끊겼어요",
                message: "내일 다시 검색해 보세요",
                actionTitle: "다시 검색하기"
            )
        case .noRoute:
            rows = []
            showEmptyState(
                title: "대중교통 경로를 찾지 못했어요",
                message: "출발지나 도착지를 바꿔 보세요",
                actionTitle: "다시 검색하기"
            )
        case let .failed(message):
            rows = []
            showEmptyState(title: "앗차!", message: message, actionTitle: "다시 시도")
        }
        tableView.reloadData()
    }

    private func renderFields(_ fields: SearchViewModel.FieldsViewData) {
        // setText는 커서를 끝으로 옮기므로 실제로 달라졌을 때만 반영한다.
        if departureField.text != fields.departureText {
            departureField.setText(fields.departureText)
        }
        if arrivalField.text != fields.arrivalText {
            arrivalField.setText(fields.arrivalText)
        }
        if focusedField != fields.activeField {
            focusedField = fields.activeField
            let target = (fields.activeField == .departure) ? departureField : arrivalField
            target.becomeFirstResponder()
        }
    }

    private func routeRows(from viewData: RouteResultsViewData) -> [Row] {
        var rows: [Row] = [.routeCard(viewData.featured)]
        guard !viewData.alternatives.isEmpty else { return rows }
        rows.append(.more(isExpanded: viewData.isExpanded))
        if viewData.isExpanded {
            rows.append(contentsOf: viewData.alternatives.enumerated().map {
                .alternative(index: $0.offset + 1, viewData: $0.element)
            })
        }
        return rows
    }

    private func showEmptyState(title: String, message: String, actionTitle: String? = nil) {
        emptyState.configure(
            with: .init(
                icon: DSIcon.illustCharacterGray,
                title: title,
                message: message,
                actionTitle: actionTitle
            )
        )
        emptyState.isHidden = false
    }
}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch rows[indexPath.row] {
        case let .place(viewData, showsDelete):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: DSListCell.reuseIdentifier, for: indexPath
            )
            if let cell = cell as? DSListCell {
                cell.configure(
                    with: .init(
                        leadingIcon: DSIcon.place24,
                        title: viewData.name,
                        subtitle: viewData.address,
                        accessory: showsDelete ? .delete : .none
                    )
                )
                if showsDelete {
                    // prepareForReuse가 콜백을 비우므로 configure마다 재배선.
                    cell.onDeleteTap = { [weak self] in
                        self?.viewModel.didDeleteRecent(at: indexPath.row)
                    }
                }
            }
            return cell
        case let .routeCard(viewData):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: SearchRouteCardCell.reuseIdentifier, for: indexPath
            )
            (cell as? SearchRouteCardCell)?.configure(
                with: .init(
                    badgeText: viewData.badgeText,
                    departureTimeText: viewData.departureTimeText,
                    legs: viewData.legs,
                    summaryText: viewData.summaryText,
                    destinationText: viewData.destinationText
                )
            )
            return cell
        case let .more(isExpanded):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: DSListCell.reuseIdentifier, for: indexPath
            )
            (cell as? DSListCell)?.configure(
                with: .init(title: isExpanded ? "접기" : "더보기", accessory: .chevron)
            )
            return cell
        case let .alternative(_, viewData):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: DSListCell.reuseIdentifier, for: indexPath
            )
            (cell as? DSListCell)?.configure(
                with: .init(
                    title: viewData.departureTimeText,
                    subtitle: viewData.destinationText,
                    accessory: .chevron
                )
            )
            return cell
        }
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if case .routeCard = rows[indexPath.row] {
            return UITableView.automaticDimension
        }
        return DSListCell.rowHeight
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch rows[indexPath.row] {
        case .place:
            view.endEditing(true)
            viewModel.didSelectListItem(at: indexPath.row)
        case .routeCard:
            viewModel.didSelectRoute(at: 0)
        case .more:
            viewModel.didTapMore()
        case let .alternative(index, _):
            viewModel.didSelectRoute(at: index)
        }
    }

    // 최근 검색 스와이프 삭제(Phase 17, 기획서 요구) — 기존 X 버튼과 같은 경로를 탄다.
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        guard case .place(_, showsDelete: true) = rows[indexPath.row] else { return nil }
        let delete = UIContextualAction(style: .destructive, title: "삭제") {
            [weak self] _, _, completion in
            self?.viewModel.didDeleteRecent(at: indexPath.row)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard showsRecentHeader, !rows.isEmpty else { return nil }
        return DSSectionHeader(title: "최근 검색")
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard showsRecentHeader, !rows.isEmpty else { return 0 }
        return UITableView.automaticDimension
    }
}

extension SearchViewController: UIGestureRecognizerDelegate {
    // 루트에서는 시작 금지 — 검색 화면이 스택 위에 있을 때만 스와이프 백을 허용한다.
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        (navigationController?.viewControllers.count ?? 0) > 1
    }
}

// DSRouteCard는 UIView라 리스트에 태우려면 셀 래퍼가 필요하다 —
// 셀이면 didSelectRowAt이 탭 처리까지 해결한다.
private final class SearchRouteCardCell: UITableViewCell {
    static let reuseIdentifier = "SearchRouteCardCell"

    private let card = DSRouteCard()

    // UITableView dequeue requires this initializer — the one sanctioned
    // deviation from the designated-init convention.
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(DSSpacing.md)
            make.top.bottom.equalToSuperview().inset(DSSpacing.sm)
        }
    }

    func configure(with content: DSRouteCard.Content) {
        card.configure(with: content)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
