import Domain

/// Presentation model — views never see the Entity directly.
struct HomeViewData: Equatable {
    let titleText: String
    let subtitleText: String

    init(entity: HomeSummary) {
        self.titleText = entity.title
        self.subtitleText = entity.subtitle
    }
}
