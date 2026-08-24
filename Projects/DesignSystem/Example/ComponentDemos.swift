import DesignSystem
import UIKit

final class ButtonsDemoViewController: GalleryScreenViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionTitle("Styles · large")
        contentStack.addArrangedSubview(DSButton(title: "알람 등록하기", style: .primary))
        contentStack.addArrangedSubview(DSButton(title: "다시 검색", style: .secondary))
        contentStack.addArrangedSubview(DSButton(title: "더보기", style: .line))
        contentStack.addArrangedSubview(DSButton(title: "설정으로 이동", style: .text))

        addSectionTitle("Sizes")
        contentStack.addArrangedSubview(DSButton(title: "medium", style: .primary, size: .medium))
        contentStack.addArrangedSubview(DSButton(title: "small", style: .primary, size: .small))

        addSectionTitle("Icon · disabled")
        contentStack.addArrangedSubview(
            DSButton(title: "알람 등록", style: .primary, icon: DSIcon.bell24)
        )
        let disabled = DSButton(title: "비활성", style: .primary)
        disabled.isEnabled = false
        contentStack.addArrangedSubview(disabled)

        addSectionTitle("DSChip")
        let chip = DSChip()
        chip.setText("→ 신림동")
        let disabledChip = DSChip()
        disabledChip.setText("→ 구로디지털단지역")
        disabledChip.isEnabled = false
        [chip, disabledChip].forEach { contentStack.addArrangedSubview(leadingRow($0)) }

        addSectionTitle("DSPressEffect")
        let pressButton = DSButton(title: "눌러 보세요 (스케일 다운)", style: .primary)
        DSPressEffect.apply(to: pressButton)
        contentStack.addArrangedSubview(pressButton)
        let pressChip = DSChip()
        pressChip.setText("→ 칩도 눌러 보세요")
        DSPressEffect.apply(to: pressChip)
        contentStack.addArrangedSubview(leadingRow(pressChip))
    }

    /// 칩은 자기 크기 컴포넌트 — 스택 전폭으로 늘리지 않고 leading에 붙인다(홈과 같은 배치).
    private func leadingRow(_ view: UIView) -> UIStackView {
        let row = UIStackView(arrangedSubviews: [view, UIView()])
        row.axis = .horizontal
        return row
    }
}

final class FieldsDemoViewController: GalleryScreenViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionTitle("DSTextField")
        contentStack.addArrangedSubview(DSTextField(placeholder: "도착지를 검색해 주세요"))
        let dotted = DSTextField(placeholder: "출발지", showsAccentDot: true)
        dotted.setText("강남역")
        contentStack.addArrangedSubview(dotted)

        addSectionTitle("DSNavigationBar")
        let titleBar = DSNavigationBar(style: .title("경로 상세"))
        contentStack.addArrangedSubview(titleBar)
        let searchBar = DSNavigationBar(style: .search(placeholder: "장소 검색"))
        contentStack.addArrangedSubview(searchBar)

        addSectionTitle("DSGroupedCard")
        let grouped = DSGroupedCard(
            rows: [
                DSTextField(placeholder: "출발지 입력"),
                DSTextField(placeholder: "도착지 입력", showsAccentDot: true),
            ]
        )
        contentStack.addArrangedSubview(grouped)
    }
}

final class ListDemoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private var recents = ["강남역", "홍대입구역", "판교역", "성수역"]
    private let tableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DSColor.Background.base

        let header = DSSectionHeader(title: "최근 검색", actionTitle: "전체 삭제")
        header.onAction = { [weak self] in
            self?.recents.removeAll()
            self?.tableView.reloadData()
        }

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DSListCell.self, forCellReuseIdentifier: DSListCell.reuseIdentifier)

        let separator = DSSeparator()
        let stack = UIStackView(arrangedSubviews: [header, separator, tableView])
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        recents.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: DSListCell.reuseIdentifier, for: indexPath
        )
        if let cell = cell as? DSListCell {
            cell.configure(
                with: .init(
                    leadingIcon: DSIcon.place24,
                    title: recents[indexPath.row],
                    subtitle: "서울특별시 어딘가 \(indexPath.row + 1)번길",
                    accessory: .delete
                )
            )
            cell.onDeleteTap = { [weak self] in
                guard let self, let row = self.recents.firstIndex(
                    of: self.recents[indexPath.row]
                ) else { return }
                self.recents.remove(at: row)
                self.tableView.reloadData()
            }
        }
        return cell
    }

    func tableView(
        _ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "삭제") {
            [weak self] _, _, done in
            self?.recents.remove(at: indexPath.row)
            self?.tableView.deleteRows(at: [indexPath], with: .automatic)
            done(true)
        }
        return UISwipeActionsConfiguration(actions: [delete])
    }
}

final class CardsDemoViewController: GalleryScreenViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionTitle("DSBanner")
        contentStack.addArrangedSubview(DSBanner(text: "막차 출발까지 42분", style: .normal))
        contentStack.addArrangedSubview(DSBanner(text: "막차 출발까지 5분!", style: .urgent))

        addSectionTitle("DSRouteCard")
        let card = DSRouteCard()
        card.configure(
            with: .init(
                badgeText: "가장 늦은 차",
                departureTimeText: "23:52 출발",
                legs: [
                    .subway(.line2, text: "2"),
                    .subway(.line9, text: "9"),
                    .bus(.mainline, text: "6411"),
                ],
                summaryText: "강남역 → 당산역 → 구로디지털단지",
                destinationText: "도착 00:41 · 환승 2회"
            )
        )
        contentStack.addArrangedSubview(card)

        addSectionTitle("DSTransportBadge")
        let badges = UIStackView(
            arrangedSubviews: [
                DSTransportBadge(kind: .subway(.line1, text: "1")),
                DSTransportBadge(kind: .subway(.line4, text: "4")),
                DSTransportBadge(kind: .subway(.shinbundang, text: "신분당")),
                DSTransportBadge(kind: .bus(.town, text: "마을07")),
                DSTransportBadge(kind: .bus(.widearea, text: "9401")),
                DSTransportBadge(kind: .walk),
            ]
        )
        badges.axis = .horizontal
        badges.spacing = DSSpacing.xs
        badges.alignment = .center
        badges.addArrangedSubview(UIView())
        contentStack.addArrangedSubview(badges)
    }
}

final class FeedbackDemoViewController: GalleryScreenViewController {
    override func viewDidLoad() {
        super.viewDidLoad()

        addSectionTitle("DSToast")
        let plainToast = DSButton(title: "토스트 띄우기", style: .secondary, size: .medium)
        plainToast.addAction(
            UIAction { [weak self] _ in
                guard let view = self?.view else { return }
                DSToast.show("최근 검색이 삭제되었어요", in: view)
            },
            for: .touchUpInside
        )
        contentStack.addArrangedSubview(plainToast)

        let actionToast = DSButton(title: "액션 토스트 띄우기", style: .secondary, size: .medium)
        actionToast.addAction(
            UIAction { [weak self] _ in
                guard let view = self?.view else { return }
                DSToast.show(
                    "알람 권한이 꺼져 있어요",
                    in: view,
                    action: .init(title: "설정 이동") { print("settings tapped") },
                    duration: 5
                )
            },
            for: .touchUpInside
        )
        contentStack.addArrangedSubview(actionToast)

        addSectionTitle("DSEmptyState")
        let ended = DSEmptyState(
            content: .init(
                icon: DSIcon.illustCharacterGray,
                title: "오늘 막차가 끊겼어요",
                message: "다음 첫차는 05:31에 출발해요.\n내일 다시 검색해 주세요.",
                actionTitle: "다시 검색"
            )
        )
        ended.onAction = { print("retry tapped") }
        contentStack.addArrangedSubview(ended)

        let noRoute = DSEmptyState(
            content: .init(
                title: "대중교통 경로를 찾지 못했어요",
                message: "도착지를 바꿔서 다시 검색해 보세요."
            )
        )
        contentStack.addArrangedSubview(noRoute)
    }
}
