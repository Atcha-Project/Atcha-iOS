import ProjectDescription
import ProjectDescriptionHelpers

// Module is named AtchaData, not Data — a module literally named "Data"
// shadows Foundation.Data in qualified lookups.
let project = Project.layer(
    name: "AtchaData",
    bundleSuffix: "data",
    dependencies: [
        .project(target: "Domain", path: "../Domain"),
        .project(target: "CoreNetwork", path: "../Core/Network"),
        .project(target: "CoreStorage", path: "../Core/Storage"),
    ]
)
