import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.layer(
    name: "CoreCoordinator",
    bundleSuffix: "core.coordinator",
    isolation: .mainActor
)
