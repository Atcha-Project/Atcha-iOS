import ProjectDescription

public extension Project {
    /// Micro-feature: emits {name}Feature, {name}FeatureInterface,
    /// {name}FeatureTests, {name}FeatureExample.
    ///
    /// Conventions baked into every feature:
    /// - Every ViewModel is `@MainActor` (module default isolation is MainActor too).
    /// - Presentation depends on Domain, never on AtchaData.
    /// - Assembly lives in the feature's DIContainer; Coordinators own flow only.
    /// - Example apps wire stub use cases (no Data/network dependency).
    ///   Stubs are intentionally duplicated between Tests and Example (no
    ///   Testing target) — revisit if a stub is needed in 3+ places.
    static func feature(
        name: String,
        dependencies: [TargetDependency] = [],
        interfaceDependencies: [TargetDependency] = [],
        testDependencies: [TargetDependency] = [],
        exampleDependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil
    ) -> Project {
        let featureName = "\(name)Feature"
        let bundleBase = "\(Atcha.v2BundleID).feature.\(name.lowercased())"

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

        let interface = Target.target(
            name: "\(featureName)Interface",
            destinations: Atcha.destinations,
            product: .staticFramework,
            bundleId: "\(bundleBase).interface",
            deploymentTargets: Atcha.v2Deployment,
            infoPlist: .default,
            sources: ["Interface/**"],
            dependencies: interfaceDependencies,
            settings: .atchaV2()
        )

        let sources = Target.target(
            name: featureName,
            destinations: Atcha.destinations,
            product: .staticFramework,
            bundleId: bundleBase,
            deploymentTargets: Atcha.v2Deployment,
            infoPlist: .default,
            sources: ["Sources/**"],
            resources: resources,
            dependencies: [.target(name: "\(featureName)Interface")] + dependencies,
            settings: .atchaV2()
        )

        let tests = Target.target(
            name: "\(featureName)Tests",
            destinations: Atcha.destinations,
            product: .unitTests,
            bundleId: "\(bundleBase).tests",
            deploymentTargets: Atcha.v2Deployment,
            infoPlist: .default,
            sources: ["Tests/**"],
            dependencies: [.target(name: featureName)] + testDependencies,
            settings: .atchaV2()
        )

        let example = Target.target(
            name: "\(featureName)Example",
            destinations: Atcha.destinations,
            product: .app,
            bundleId: "\(bundleBase).example",
            deploymentTargets: Atcha.v2Deployment,
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": [:],
                "UIApplicationSceneManifest": sceneManifest,
            ]),
            sources: ["Example/**"],
            dependencies: [.target(name: featureName)] + exampleDependencies,
            settings: .atchaV2()
        )

        return Project(
            name: featureName,
            options: .options(
                defaultKnownRegions: Atcha.knownRegions,
                developmentRegion: Atcha.developmentRegion
            ),
            settings: .atchaV2(),
            targets: [interface, sources, tests, example]
        )
    }
}
