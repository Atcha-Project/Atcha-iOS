import ProjectDescription

public extension Target {
    /// WidgetKit extension embedded in the host app (`.app/PlugIns/`).
    /// SwiftUI + WidgetKit — the repo's single sanctioned exception to the
    /// UIKit-only UI convention. Settings go through `Settings.atchaV2()` so
    /// the Debug/Stage/Release configuration triple stays intact.
    static func widgetExtension(
        name: String,
        bundleId: String,
        sources: SourceFilesList,
        entitlements: Entitlements? = nil,
        dependencies: [TargetDependency] = []
    ) -> Target {
        .target(
            name: name,
            destinations: Atcha.destinations,
            product: .appExtension,
            bundleId: bundleId,
            deploymentTargets: Atcha.v2Deployment,
            infoPlist: .extendingDefault(with: [
                "NSExtension": [
                    "NSExtensionPointIdentifier": "com.apple.widgetkit-extension",
                ],
            ]),
            sources: sources,
            entitlements: entitlements,
            dependencies: dependencies,
            settings: .atchaV2(
                // Embedded extensions must not install to /Applications on
                // archive; the host app carries the .appex.
                base: ["SKIP_INSTALL": "YES"],
                isolation: .mainActor
            )
        )
    }
}
