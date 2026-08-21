import Foundation

/// Build-configuration-driven environment. Compilation conditions come from
/// build settings (Debug=DEV, Stage=STAGE, Release=LIVE) — no dependency on
/// the gitignored xcconfigs at runtime.
enum AppEnvironment {
    case dev
    case stage
    case live

    static var current: AppEnvironment {
        #if LIVE
        .live
        #elseif STAGE
        .stage
        #else
        .dev
        #endif
    }

    // Placeholder URLs — replace with the real per-environment hosts.
    var apiBaseURL: URL {
        switch self {
        case .dev: URL(string: "https://dev-api.atcha.example")!
        case .stage: URL(string: "https://stage-api.atcha.example")!
        case .live: URL(string: "https://api.atcha.example")!
        }
    }
}
