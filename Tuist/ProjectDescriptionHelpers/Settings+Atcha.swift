import ProjectDescription

/// Default actor isolation for a module. UI-facing modules (App, Features,
/// DesignSystem, CoreCoordinator) use .mainActor; Domain/AtchaData/CoreNetwork
/// stay .nonisolated so async domain/network code needs no annotations.
public enum AtchaIsolation: String {
    case mainActor = "MainActor"
    case nonisolated = "nonisolated"
}

public extension Settings {
    /// Swift 6 settings + the canonical Debug/Stage/Release configuration
    /// triple. Per-configuration compilation conditions drive AppEnvironment:
    /// Debug=DEV, Stage=STAGE, Release=LIVE.
    static func atchaV2(
        base extra: SettingsDictionary = [:],
        isolation: AtchaIsolation = .mainActor
    ) -> Settings {
        let base: SettingsDictionary = [
            "SWIFT_VERSION": "6.0",
            "SWIFT_APPROACHABLE_CONCURRENCY": "YES",
            "SWIFT_DEFAULT_ACTOR_ISOLATION": .string(isolation.rawValue),
            "CODE_SIGN_STYLE": "Automatic",
            "DEVELOPMENT_TEAM": .string(Atcha.teamID),
            "TARGETED_DEVICE_FAMILY": "1",
        ].merging(extra) { _, custom in custom }

        return .settings(
            base: base,
            configurations: [
                .debug(
                    name: "Debug",
                    settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) DEV"]
                ),
                .release(
                    name: "Stage",
                    settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) STAGE"]
                ),
                .release(
                    name: "Release",
                    settings: ["SWIFT_ACTIVE_COMPILATION_CONDITIONS": "$(inherited) LIVE"]
                ),
            ],
            defaultSettings: .recommended
        )
    }
}
