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

    /// DEV·STAGE·LIVE가 같은 호스트를 쓴다(2026-09-24 확정). 이전 호스트 둘은 모두
    /// 죽었다 — atcha.online은 DNS 등록이 사라졌고(NXDOMAIN), atcha.p-e.kr은 DNS는
    /// 남았으나 443 연결이 되지 않는다. 환경별 호스트가 다시 생기면 switch로 되돌린다.
    ///
    /// `/api` 접두어는 여기 한 곳에서 붙인다 — URLSessionNetworkClient가
    /// baseURL.appendingPathComponent(endpoint.path)로 조립하므로 각 Endpoint의
    /// path는 접두어를 몰라도 된다(서버가 접두어 체계를 또 바꾸면 이 줄만 고친다).
    var apiBaseURL: URL {
        URL(string: "https://atcha.kro.kr/api")!
    }

    // TODO: [서버 확인] V2가 레거시 스토어 앱(id6747877903)을 잇는지 확정 — 별도 앱이면 교체.
    var appStoreURL: URL {
        URL(string: "itms-apps://itunes.apple.com/app/id6747877903")!
    }
}
