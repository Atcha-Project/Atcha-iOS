import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.layer(
    name: "CoreAuth",
    bundleSuffix: "core.auth",
    isolation: .nonisolated,
    dependencies: [
        .project(target: "CoreNetwork", path: "../Network"),
        .project(target: "CoreStorage", path: "../Storage"),
    ]
)
