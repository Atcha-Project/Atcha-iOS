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

    // Hosts recovered from the legacy trust-evaluator registrations
    // (user-approved 2026-08-22). Stage shares the dev host until a dedicated
    // one exists.
    var apiBaseURL: URL {
        switch self {
        case .dev: URL(string: "https://atcha.p-e.kr")!
        case .stage: URL(string: "https://atcha.p-e.kr")!
        case .live: URL(string: "https://atcha.online")!
        }
    }
}
