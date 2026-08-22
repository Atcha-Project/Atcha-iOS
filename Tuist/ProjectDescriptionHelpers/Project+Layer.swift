import ProjectDescription

public extension Project {
    /// Horizontal / Clean Architecture layer module: framework + unit tests.
    /// `example: true` adds a {name}Example app target (gallery/demo) —
    /// mirrors the feature Example pattern for layers that benefit from
    /// standalone visual review (e.g. DesignSystem).
    static func layer(
        name: String,
        bundleSuffix: String? = nil,
        isolation: AtchaIsolation = .nonisolated,
        dependencies: [TargetDependency] = [],
        testDependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil,
        example: Bool = false
    ) -> Project {
        let suffix = bundleSuffix ?? name.lowercased()

        let framework = Target.target(
            name: name,
            destinations: Atcha.destinations,
            product: .staticFramework,
            bundleId: "\(Atcha.v2BundleID).\(suffix)",
            deploymentTargets: Atcha.v2Deployment,
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: resources,
            dependencies: dependencies,
            settings: .atchaV2(isolation: isolation)
        )

        let tests = Target.target(
            name: "\(name)Tests",
            destinations: Atcha.destinations,
            product: .unitTests,
            bundleId: "\(Atcha.v2BundleID).\(suffix).tests",
            deploymentTargets: Atcha.v2Deployment,
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: name)] + testDependencies,
            settings: .atchaV2(isolation: isolation)
        )

        var targets = [framework, tests]

        if example {
            let sceneManifest: Plist.Value = [
                "UIApplicationSupportsMultipleScenes": false,
                "UISceneConfigurations": [
                    "UIWindowSceneSessionRoleApplication": [
                        [
                            "UISceneConfigurationName": "Default",
                            "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate",
                        ],
                    ],
                ],
            ]

            targets.append(
                Target.target(
                    name: "\(name)Example",
                    destinations: Atcha.destinations,
                    product: .app,
                    bundleId: "\(Atcha.v2BundleID).\(suffix).example",
                    deploymentTargets: Atcha.v2Deployment,
                    infoPlist: .extendingDefault(with: [
                        "UILaunchScreen": [:],
                        "UIApplicationSceneManifest": sceneManifest,
                    ]),
                    sources: ["Example/**"],
                    dependencies: [.target(name: name)],
                    settings: .atchaV2(isolation: .mainActor)
                )
            )
        }

        return Project(
            name: name,
            options: .options(
                defaultKnownRegions: Atcha.knownRegions,
                developmentRegion: Atcha.developmentRegion
            ),
            settings: .atchaV2(isolation: isolation),
            targets: targets
        )
    }
}
