import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.layer(
    name: "CoreConcurrency",
    bundleSuffix: "core.concurrency",
    isolation: .mainActor
)
