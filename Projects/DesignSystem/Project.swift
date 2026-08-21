import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.layer(
    name: "DesignSystem",
    bundleSuffix: "designsystem",
    isolation: .mainActor,
    resources: ["Resources/**"]
)
