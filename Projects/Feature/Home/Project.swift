import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    name: "Home",
    dependencies: [
        .project(target: "Domain", path: "../../Domain"),
        .project(target: "DesignSystem", path: "../../DesignSystem"),
        .project(target: "CoreCoordinator", path: "../../Core/Coordinator"),
        .external(name: "SnapKit"),
    ],
    interfaceDependencies: [
        .project(target: "Domain", path: "../../Domain"),
        .project(target: "CoreCoordinator", path: "../../Core/Coordinator"),
    ],
    testDependencies: [
        .project(target: "Domain", path: "../../Domain"),
    ],
    exampleDependencies: [
        .project(target: "Domain", path: "../../Domain"),
        .project(target: "CoreCoordinator", path: "../../Core/Coordinator"),
    ]
)
