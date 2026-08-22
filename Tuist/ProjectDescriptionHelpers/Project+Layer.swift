import ProjectDescription

public extension Project {
    /// Horizontal / Clean Architecture layer module: framework + unit tests.
    static func layer(
        name: String,
        bundleSuffix: String? = nil,
        isolation: AtchaIsolation = .nonisolated,
        dependencies: [TargetDependency] = [],
        testDependencies: [TargetDependency] = [],
        resources: ResourceFileElements? = nil
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

        return Project(
            name: name,
            options: .options(
                defaultKnownRegions: Atcha.knownRegions,
                developmentRegion: Atcha.developmentRegion
            ),
            settings: .atchaV2(isolation: isolation),
            targets: [framework, tests]
        )
    }
}
