import ProjectDescription
import ProjectDescriptionHelpers

let project = Project.feature(
    name: "Home",
    dependencies: [
        .project(target: "Domain", path: "../../Domain"),
        .project(target: "DesignSystem", path: "../../DesignSystem"),
        .project(target: "CoreCoordinator", path: "../../Core/Coordinator"),
        // 검색 플로우 진입점 — 본체(SearchFeature)가 아니라 Interface만 본다.
        .project(target: "SearchFeatureInterface", path: "../Search"),
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
        // Example의 스텁 SearchCoordinatorBuildable 구현용.
        .project(target: "SearchFeatureInterface", path: "../Search"),
    ]
)
