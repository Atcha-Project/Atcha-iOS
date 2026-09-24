import DesignSystem
import SnapKit
import UIKit

final class SettingsViewController: SettingsScreen {
    // VC strongly owns the VM; the VM's closures capture the VC weakly.
    private let viewModel: SettingsViewModel
    private let tableView = UITableView(frame: .zero, style: .grouped)
    private var sections: [SettingsViewModel.Section] = []

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
        super.init(title: "설정")
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
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 0
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DSListCell.self, forCellReuseIdentifier: DSListCell.reuseIdentifier)
        contentView.addSubview(tableView)
        tableView.snp.makeConstraints { make in make.edges.equalToSuperview() }
    }

    private func bind() {
        viewModel.onSectionsChange = { [weak self] sections in
            self?.sections = sections
            self?.tableView.reloadData()
        }
        viewModel.onToast = { [weak self] message in
            self?.showToast(message)
        }
        sections = viewModel.sections
    }

    private func content(for row: SettingsViewModel.Row) -> DSListCell.Content {
        switch row {
        case let .homeAddress(subtitle):
            DSListCell.Content(leadingIcon: DSIcon.place24, title: "우리집 설정", subtitle: subtitle, accessory: .chevron)
        case .privacyPolicy:
            DSListCell.Content(title: "개인정보 처리방침", accessory: .chevron)
        case .feedback:
            DSListCell.Content(title: "피드백 보내기", accessory: .chevron)
        case let .version(text, hasUpdate):
            DSListCell.Content(title: "현재 버전 \(text)", accessory: hasUpdate ? .value("업데이트") : .none)
        case .logout:
            DSListCell.Content(title: "로그아웃")
        case .withdraw:
            DSListCell.Content(title: "계정 탈퇴")
        }
    }
}

extension SettingsViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DSListCell.reuseIdentifier, for: indexPath)
        (cell as? DSListCell)?.configure(with: content(for: sections[indexPath.section].rows[indexPath.row]))
        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        sections[section].title.map { DSSectionHeader(title: $0) }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        sections[section].title == nil ? DSSpacing.lg : UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        UIView()
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        DSSpacing.sm
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let row = sections[indexPath.section].rows[indexPath.row]
        if row == .logout {
            confirm(title: "로그아웃하시겠어요?", confirmTitle: "로그아웃") { [weak self] in
                self?.viewModel.logoutConfirmed()
            }
            return
        }
        viewModel.didSelect(row)
    }
}
