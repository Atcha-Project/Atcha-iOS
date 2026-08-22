import DesignSystem
import UIKit

final class GalleryRootViewController: UITableViewController {
    private let demos: [(title: String, make: () -> UIViewController)] = [
        ("Colors", { ColorsDemoViewController() }),
        ("Typography", { TypographyDemoViewController() }),
        ("Buttons", { ButtonsDemoViewController() }),
        ("TextField · NavigationBar", { FieldsDemoViewController() }),
        ("ListCell · SectionHeader · Separator", { ListDemoViewController() }),
        ("RouteCard · TransportBadge · Banner", { CardsDemoViewController() }),
        ("Toast · EmptyState", { FeedbackDemoViewController() }),
    ]

    init() {
        super.init(style: .insetGrouped)
        title = "DesignSystem"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DSColor.Background.base
        tableView.register(DSListCell.self, forCellReuseIdentifier: DSListCell.reuseIdentifier)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        demos.count
    }

    override func tableView(
        _ tableView: UITableView, cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: DSListCell.reuseIdentifier, for: indexPath
        )
        (cell as? DSListCell)?.configure(
            with: .init(title: demos[indexPath.row].title, accessory: .chevron)
        )
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let demo = demos[indexPath.row]
        let viewController = demo.make()
        viewController.title = demo.title
        navigationController?.pushViewController(viewController, animated: true)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}

// Scrollable vertical stack shared by the demo screens.
class GalleryScreenViewController: UIViewController {
    let contentStack = UIStackView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = DSColor.Background.base

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentStack.axis = .vertical
        contentStack.spacing = DSSpacing.md
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            contentStack.topAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.topAnchor, constant: DSSpacing.md
            ),
            contentStack.leadingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: DSSpacing.md
            ),
            contentStack.trailingAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -DSSpacing.md
            ),
            contentStack.bottomAnchor.constraint(
                equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -DSSpacing.xl
            ),
            contentStack.widthAnchor.constraint(
                equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -DSSpacing.md * 2
            ),
        ])
    }

    func addSectionTitle(_ text: String) {
        let label = UILabel()
        label.font = DSTypography.label2.font
        label.textColor = DSColor.Text.secondary
        label.text = text
        contentStack.addArrangedSubview(label)
    }
}
