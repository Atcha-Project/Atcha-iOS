import UIKit

/// 여러 행을 한 표면으로 묶는 그룹 카드 — 홈·검색의 출발/도착 필드처럼 연관 행을
/// 하나의 카드로 보여줄 때 쓴다. 행 사이엔 leading 인셋 헤어라인이 들어간다.
/// 행 구성은 init 고정 — 현재 호출부(홈·검색 모두 행 2개 정적)에 변경 API가 불필요하다.
public final class DSGroupedCard: UIView {
    private static let separatorThickness: CGFloat = 0.5

    public init(rows: [UIView]) {
        super.init(frame: .zero)
        backgroundColor = DSColor.Fill.surface
        layer.cornerRadius = DSRadius.lg
        // 행의 하이라이트 fill이 모서리 밖으로 새지 않게 자른다.
        clipsToBounds = true

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])

        for (index, row) in rows.enumerated() {
            if index > 0 {
                stack.addArrangedSubview(Self.makeSeparatorRow())
            }
            stack.addArrangedSubview(row)
        }
    }

    /// DSSeparator는 전폭 고정이라 재사용하지 않는다 — 카드 내부 구분선은
    /// leading만 콘텐츠 인셋을 따르는 별도 헤어라인이다.
    private static func makeSeparatorRow() -> UIView {
        let container = UIView()
        let line = UIView()
        line.backgroundColor = DSColor.Border.default
        line.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(line)
        NSLayoutConstraint.activate([
            line.topAnchor.constraint(equalTo: container.topAnchor),
            line.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            line.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: DSSpacing.md),
            line.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            line.heightAnchor.constraint(equalToConstant: Self.separatorThickness),
        ])
        return container
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}
