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
    // one exists. 서버 경로는 전부 `/api/...`(2026-09 게스트 흐름 확정) — 엔드포인트
    // path는 접두사 없이 쓰고 base가 `/api`를 싣는다(레거시 allowlist `/api/locations/rgeo`와 정합).
    var apiBaseURL: URL {
        switch self {
        case .dev: URL(string: "https://atcha.p-e.kr/api")!
        case .stage: URL(string: "https://atcha.p-e.kr/api")!
        case .live: URL(string: "https://atcha.online/api")!
        }
    }

    // TODO: [서버 확인] V2가 레거시 스토어 앱(id6747877903)을 잇는지 확정 — 별도 앱이면 교체.
    var appStoreURL: URL {
        URL(string: "itms-apps://itunes.apple.com/app/id6747877903")!
    }
}
