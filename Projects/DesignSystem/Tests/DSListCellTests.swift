@testable import DesignSystem
import Testing
import UIKit

@MainActor
struct DSListCellTests {
    @Test
    func rowHeightIs56() {
        #expect(DSListCell.rowHeight == 56)
    }

    @Test
    func configureRendersTitleSubtitleAndIcon() {
        let cell = DSListCell(style: .default, reuseIdentifier: nil)
        cell.configure(
            with: .init(
                leadingIcon: DSIcon.place24,
                title: "강남역",
                subtitle: "서울 강남구",
                accessory: .none
            )
        )
        let texts = renderedTexts(in: cell.contentView)
        #expect(texts.contains("강남역"))
        #expect(texts.contains("서울 강남구"))
    }

    @Test
    func valueAccessoryRendersText() {
        let cell = DSListCell(style: .default, reuseIdentifier: nil)
        cell.configure(with: .init(title: "버전", accessory: .value("2.0.0")))
        #expect(renderedTexts(in: cell.contentView).contains("2.0.0"))
    }

    @Test
    func deleteAccessoryFiresCallback() {
        let cell = DSListCell(style: .default, reuseIdentifier: nil)
        cell.configure(with: .init(title: "홍대입구역", accessory: .delete))

        var deleted = false
        cell.onDeleteTap = { deleted = true }
        cell.handleDeleteTap()
        #expect(deleted)
    }

    @Test
    func prepareForReuseClearsDeleteCallback() {
        let cell = DSListCell(style: .default, reuseIdentifier: nil)
        cell.configure(with: .init(title: "판교역", accessory: .delete))
        cell.onDeleteTap = {}
        cell.prepareForReuse()
        #expect(cell.onDeleteTap == nil)
    }
}
