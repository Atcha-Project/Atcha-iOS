# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 프로젝트 개요

**앗차(Atcha)** — 위치 기반으로 막차(버스/지하철) 시간을 확인하고 출발 알림을 주는 iOS 앱. 이 레포에는 두 세계가 공존한다:

- **Tuist 워크스페이스** (`Atcha.xcworkspace`, 생성물) — "메인 2.0" **AtchaV2** 개발이 이뤄지는 곳. 모든 신규 작업은 여기서.
- **레거시** (`Atcha-iOS.xcodeproj` + `Atcha-iOS/` 소스) — 기존 1.x 앱. Tuist에서 `Projects/Legacy`의 단일 타겟으로도 래핑돼 있지만, **CI/fastlane은 아직 기존 xcodeproj를 직접 빌드**하므로 기존 xcodeproj를 삭제·수정하지 말 것. 참고용.

## 필수 명령어

```bash
# 최초 1회 (클론 직후·xcconfig 없을 때): 스탠드인 xcconfig 생성 + tuist install + generate
sh Scripts/bootstrap.sh

# 매니페스트(Project.swift 등) 수정 후 재생성
tuist generate --no-open

# AtchaV2 빌드 (구성: Debug/Stage/Release 3개 — Stage 빼먹으면 CI가 깨짐)
xcodebuild -workspace Atcha.xcworkspace -scheme AtchaV2 -configuration Debug \
  -destination 'generic/platform=iOS Simulator' build

# 모듈 테스트 (Swift Testing 기반)
xcodebuild -workspace Atcha.xcworkspace -scheme HomeFeature \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
# 단일 테스트: -only-testing:HomeFeatureTests/HomeViewModelTests/viewDidLoad_locationSuccess_showsReverseGeocodedName

# 의존 그래프 확인 (graph.dot 생성, gitignore됨)
tuist graph --format dot --no-open

# 레거시 빌드 — 디바이스 전용 (TMapSDK.framework가 arm64 디바이스 전용이라 시뮬레이터 빌드는 원래 불가)
xcodebuild -workspace Atcha.xcworkspace -scheme Atcha-Dev -configuration Debug \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

도구는 mise로 고정(`mise.toml`, Tuist 4.209). **`/usr/local/bin/tuist`에 구버전(3.33.3)이 깔려 있고 PATH에서 mise shim보다 앞선다** — `tuist` 명령을 그냥 부르면 매니페스트 컴파일이 `cannot find type 'DeploymentTargets'`로 실패한다. `mise exec -- tuist ...`도 서브셸(`sh Scripts/bootstrap.sh` 등)에서는 구버전을 타므로, 스크립트를 돌릴 때는 PATH를 직접 앞세울 것:

```bash
export PATH="$(dirname "$(mise which tuist)"):$PATH"
```

`bundle exec`은 로컬에서 동작하지 않음(시스템 ruby 2.6 ↔ Gemfile.lock의 bundler 4.0 비호환) — fastlane은 CI 전용으로 취급.

### 알아야 할 함정

- **xcconfig 4개(Base/Dev/Stage/Live)는 gitignore돼 있고 없으면 `tuist generate`가 에러로 실패한다.** `Scripts/bootstrap.sh`가 빈 스탠드인을 만들어 해결한다(CI는 시크릿에서 실제 파일을 복원). AtchaV2는 xcconfig에 의존하지 않도록 설계돼 있으므로 새 모듈에 xcconfig 참조를 추가하지 말 것.
- 빌드 구성은 프로젝트 전체가 **Debug/Stage/Release 3개**. 새 타겟·외부 의존성 설정에 Stage가 누락되면 `-configuration Stage` 빌드가 조용히 깨진다(외부 SPM은 `Tuist/Package.swift`의 `PackageSettings.baseSettings`가 3구성을 선언).
- SPM 의존성 추가는 `Tuist/Package.swift`에서. `Tuist/Package.resolved`는 커밋 대상(Amplitude가 branch 추적이라 리비전 고정 역할).
- 레거시 소스 글롭에서 `Atcha-iOS/App/DIContainer/DIContainer.swift`는 의도적으로 제외(기존 pbxproj도 컴파일하지 않던 죽은 파일, AppDIContainer 중복 선언).

## 아키텍처 (AtchaV2 — uFeatures + 클린아키텍처)

```
AtchaV2(앱, 조합 루트: 어댑터·스플래시·AlarmSyncService) ─► HomeFeature ─► {HomeFeatureInterface, SearchFeatureInterface, SettingsFeatureInterface, Domain, DesignSystem, CoreCoordinator, SnapKit}
        ├─► SearchFeature ─► {SearchFeatureInterface, Domain, DesignSystem, CoreCoordinator, SnapKit}
        ├─► SettingsFeature ─► {SettingsFeatureInterface, Domain, DesignSystem, CoreCoordinator, SnapKit}
        ├─► AtchaData ─► {Domain, CoreNetwork, CoreStorage}
        ├─► CoreAuth ─► {CoreNetwork, CoreStorage}
        ├─► CoreAlarm (무의존 — AlarmKit 유일 import 지점, App만 import)
        ├─► CoreLiveActivity (무의존 — ActivityAttributes 계약, 앱·위젯 공유)
        └─► AtchaWidget (위젯 익스텐션, 앱에 임베드 — Live Activity UI, UIKit 규약의 유일한 SwiftUI 예외)
```

의존 규칙(위반 금지, `tuist graph`로 검증 가능):
- **Presentation → Domain ← Data**: Feature 모듈은 `AtchaData`를 절대 import하지 않는다. Domain은 무의존.
- 구체 Data/Network 타입을 보는 곳은 앱의 `AppDIContainer`(조합 루트)뿐. 여기서 NetworkClient → RepositoryImpl → UseCase → 피처 DIContainer 순으로 주입한다.
- Firebase 등 외부 라이브러리는 **앱 타겟에서만** 링크(내부 모듈 전부 static framework, 중복 심볼 방지). 앱 타겟에 `-ObjC` 필요.

모듈 정의는 `Tuist/ProjectDescriptionHelpers/`의 DSL로만 한다:
- `Project.feature(name:)` — 피처당 `{N}Feature`/`{N}FeatureInterface`/`{N}FeatureTests`/`{N}FeatureExample` 4타겟. 새 피처는 `Projects/Feature/Home`을 그대로 본뜬다.
- `Project.layer(name:)` — 수평 모듈(framework+tests). isolation 파라미터: UI 모듈은 `.mainActor`, Domain/Data/Network은 `.nonisolated`.
- `Settings.atchaV2()` — Swift 6 + 3구성 + 구성별 컴파일 플래그(Debug=DEV, Stage=STAGE, Release=LIVE). 환경 분기는 앱의 `AppEnvironment` enum이 이 플래그로 수행(런타임 xcconfig 의존 없음).

### 피처 내부 컨벤션 (Home이 표준 템플릿)

- 클린아키텍처 수직 슬라이스 필수 구성: Domain에 Entity + **추상화 UseCase(프로토콜)** + Repository 인터페이스 / Data에 Request·Response DTO + `toEntity()` + RepositoryImpl / Presentation에 ViewData(Entity를 뷰에 직접 노출 금지) + ViewModel + VC.
- **모든 ViewModel은 `@MainActor`.** 비동기 작업은 `Task` 보관 + `deinit`에서 cancel + `[weak self]` + `Task.isCancelled` 가드.
- **조립은 피처 DIContainer, 화면 흐름은 Coordinator.** Coordinator는 `CoreCoordinator.Coordinator`를 채택하고 `finishDelegate`(weak)로 부모가 자식을 제거한다(누수 방지). navigationController는 앱 루트(AppCoordinator)만 강한 소유, 나머지는 weak.
- 다른 모듈에 노출하는 진입점은 Interface 타겟의 프로토콜(`HomeCoordinatorBuildable` 패턴)로만.
- 테스트는 **Swift Testing**(`@Test`/`#expect`). Example 앱은 스텁 UseCase로 피처 단독 실행(Data 무의존). 스텁이 Tests/Example에 중복되는 것은 의도된 트레이드오프.
- catch-all `Shared`/`Common` 모듈을 만들지 않는다. 로깅·캐싱 등이 필요해지면 목적별 단일 모듈(`Logger`, `Storage`)을 새로 판다.
- 영속·캐시는 `CoreStorage`의 타입으로만 한다. `KeyValueStore`(Data 단위 추상) 위에 `DocumentStore`(단일 문서) / `CollectionStore`(상한 있는 목록) / `ExpiringCache`(TTL+지터) 셋을 올린다. **전부 actor다** — 목록·문서 갱신은 read-modify-write라 값 타입으로 두면 동시 쓰기가 서로를 덮어쓴다(실제로 최근 검색 1건이 조용히 사라지는 버그였다). 격리는 **인스턴스 단위**라 조합 루트에서 1회 생성해 공유해야 한다. 저장 매체는 값 크기로 가른다 — 단일 값 4KB 초과면 `FileKeyValueStore`(UserDefaults는 첫 접근에 plist 전체를 올린다), 서버에서 다시 받을 수 있는 값은 `.cache` 네임스페이스로 백업 제외.
- 응답 캐시는 Data 레이어 **데코레이터**로 붙인다(`CachingPlaceRepository`) — 피처·Domain은 한 줄도 모른다. 대상 선정 기준은 "틀렸을 때의 피해"다: 역지오코딩 7일 · 장소 검색 1시간 · **서비스 지역 판정은 캐시 금지**(틀리면 되는 지역을 막는다). 좌표는 키로 쓰기 전에 반올림한다(GPS가 떨려서 원시 좌표는 적중률이 0). 만료에는 ±10% 지터 — 막차 시간대에 수천 기기의 만료가 한 점에 몰리면 안 된다. **실패는 캐시하지 않는다.**
- 모듈명 `Data`는 금지(Foundation.Data 섀도잉) — Data 레이어 모듈명은 `AtchaData`(디렉터리는 `Projects/Data`).
- UI는 UIKit 코드 기반(스토리보드 없음) + SnapKit + DesignSystem 토큰(`DSColor`/`DSFont`/`DSSpacing`).
- **UseCase는 기본이 아니다.** 단일 Repository 메서드를 한 줄 위임하는 UseCase는 만들지 않는다 — 같은 프로토콜에 이름만 하나 더 입히는 계층이다. 새로 만들 조건은 ① 포트 2개 이상을 조합하거나 ② 비즈니스 규칙(순서·판정·폴백)을 담을 때. 해당 없으면 ViewModel이 Domain Repository/Service 프로토콜을 직접 주입받는다(경계는 유지된다 — 피처가 보는 건 여전히 Domain 프로토콜뿐). 2026-09-24 전면 재검토로 21 → 11개. 개발자가 5명을 넘거나 한 Repository 메서드를 4화면 초과가 쓰면 재검토.
- **화면 상태 채널은 정확히 2개**: `onStateChange`(상태) + `onToast`(사건). `private(set) var state`는 `didSet`에서 `!= oldValue`일 때만 방출한다 — 같은 값 재방출은 배너 틱마다 셀을 리로드시킨다. State 밖에 상태를 따로 들지 않고, 두 번째 상태 콜백을 만들지 않는다(키 입력 diff는 계약이 아니라 VC의 일).

### 미완 상태 (작업 시 참고)

- **인증은 게스트 계정 기반(2026-09-24 전환)** — 앱 시작 시 토큰이 없으면 `AppCoordinator.signInAsGuest()`가 `POST /auth/guest` `{deviceId, fcmToken?}`로 JWT를 받아 세션에 채택하고 곧장 홈으로 간다(`DefaultSignInAsGuestUseCase`, plain client 전용 — 토큰이 없는 것이 정상이라 `publicPathSuffixes`에 등록). **로그인 화면 단계가 없다.** `deviceId`는 게스트 계정의 유일한 신원이므로 `KeychainDeviceIdentifierAdapter`가 IDFV를 **키체인에 고정**한다 — IDFV는 앱 전체 삭제 후 재설치 시 값이 바뀌어 기존 계정에 영영 못 돌아가기 때문(키체인 항목은 앱 삭제 후 잔존). 토큰 만료도 로그인 화면이 아니라 조용한 재인증으로 끝난다: `GET /auth/reissue` 실패 → `AppCoordinator.handleSessionExpiry` → 같은 deviceId로 `/auth/guest` 재호출 → 서버가 같은 계정을 돌려준다.
- **소셜 로그인은 V2에서 완전히 제거됐다(2026-09-24)** — `Projects/Feature/Auth` 모듈 전체, `SignInUseCase`, `SocialLoginAdapter`, `KakaoConfig`, 카카오 SDK 의존성(`KakaoSDK*`, `Tuist/Package.swift`의 kakao-ios-sdk), Apple Sign In entitlement, 카카오 URL 스킴·`LSApplicationQueriesSchemes`·`TUIST_KAKAO_APP_KEY`가 모두 사라졌다. 관련 서버 API(`/auth/check`·`/auth/login`·`/auth/sign-up`)와 Domain 계약(`SocialCredential`, `SocialLoginService`, `SignUpForm`)도 함께 제거. `Projects/Core/Auth`는 **세션·토큰 관리라 그대로 유지**된다(게스트 인증이 쓴다). 회원탈퇴(`DELETE /members/me`)·유저 정보(`GET /members/me`, 홈주소/알림빈도 PATCH — `UserRepository`)는 `SettingsFeature`(홈 상단 톱니바퀴 진입: 우리집 설정·약관·피드백·버전·로그아웃·계정 탈퇴)로 연결돼 있다. 알림 빈도는 레거시처럼 미노출. 로그아웃(`POST /auth/logout`, CoreAuth `AuthSessionManager.signOut()`)·탈퇴·강제 만료는 전부 `AppCoordinator.handleSessionExpiry`에 합류하고 거기서 `AlarmSessionTeardown`이 로컬 알람·LA·스냅샷·동기화 상태를 비운다. **다만 게스트 모델에서 로그아웃/탈퇴 직후 같은 deviceId로 재인증되므로 UX가 재검토 대상이다(미해결).** 홈주소 변경은 `GET /locations/is-service-region` 통과 후 PATCH. 앱 버전은 `GET /app/version`(무토큰, 1.5초 예산·실패 시 통과)으로 권장 업데이트 팝업만. `DevDemoFallbacks`와 "DEV 건너뛰기"는 제거됨 — DEV에 남은 것은 막차 변경 주입용 `DevChangeSimulator`(refresh 가로채기 전용, 에러 은폐 없음)뿐이라 서버 실패가 DEV에서도 그대로 표면화된다.
- `AppEnvironment.apiBaseURL`은 **세 환경 모두 `https://atcha.kro.kr/api` 단일값**(2026-09-24 확정). 이전 호스트 둘은 모두 죽었다 — `atcha.online`은 NXDOMAIN, `atcha.p-e.kr`은 443 연결 불가. **`/api` 접두어는 base URL에서만 붙인다** — 각 `Endpoint.path`는 접두어를 모르므로(`/auth/guest`, `/routes/user-routes` …) 서버가 접두어 체계를 바꾸면 이 프로퍼티 한 줄만 고친다. 환경별 호스트가 다시 생기면 `switch`로 되돌리면 된다.
- **네트워크 진단**: `URLSessionNetworkClient`가 DEBUG에서 `com.atcha.network` 서브시스템에 `메서드 · URL · 상태코드/에러 · 소요시간`을 남긴다(헤더·본문은 토큰이 실리므로 절대 로깅 금지). `NetworkError.debugDescription`이 URLError 코드를 노출해 타임아웃(-1001)·연결 불가(-1004)·TLS 실패(-1200)를 가른다 — 이전에는 전부 `.transport`로 뭉개져 원인 구분이 불가능했다. 부트스트랩 실패는 `BootstrapFailureMessage`를 거쳐 스플래시의 `showRetry`로 표면화된다(게스트 전환으로 부트스트랩이 비동기가 되면서 비로소 쓰이는 경로).
- `Projects/App/Resources/GoogleService-Info.plist`는 **레거시 번들 ID(`com.atcha.iOS`)용 파일**이라 존재 가드만 통과할 뿐 V2(`com.atcha.iOS.v2`)로의 사일런트 푸시가 성립하지 않는다 — V2용 재발급·교체 필요. FCM 토큰은 로그인/가입 파라미터로만 서버에 가고, 갱신 전달은 `SyncPushTokenUseCase`까지 배선됐지만 서버 API 미확정이라 `UnconfirmedPushTokenRepository`(no-op)가 주입돼 있다. 그래서 갱신 채널은 현재 폴링(앱 시작·포그라운드 복귀)과 홈 pull-to-refresh(수동)뿐.
- **서버의 "등록된 알람 없음"은 `404` + `responseCode: URT_001`**(2026-09-25 실측: `"id(1010) 유저가 등록한 경로를 찾을 수 없습니다."`). `AlarmRepositoryImpl.refresh()`가 이것만 `AlarmRefreshOutcome.notRegistered`로 매핑하고, 나머지 에러 코드는 그대로 throw한다. **이 셋을 절대 뭉개지 말 것** — `.registered`(병합·재스케줄) / `.notRegistered`(**로컬 기록까지 정리**) / `throw`(**세션을 지킨다** — 네트워크 실패가 세션 소멸이 되면 지하철에서 앱을 여는 것만으로 알람이 사라진다). 판정은 `AlarmSessionReconciler.reconcile(current:server:now:)` 한 곳이고, 거기서 `server: nil`이 "못 물어봤다", `.notRegistered`가 "없다고 답했다"다.
- **장소 검색(`GET /locations`)의 `lat`/`lon`은 필수이고, `(0,0)`은 결과를 0건으로 만든다**(2026-09-25 실측). 좌표는 결과 집합이 아니라 **거리 표기·정렬**에만 쓰인다 — 부산 좌표로 '강남역'을 검색해도 같은 20건이 나오고 `radius`만 316km로 바뀐다. 그래서 위치를 모를 때는 `Coordinate.serviceRegionCenter`(서울시청)로 폴백한다(결과 손실 없음). 파라미터 생략은 `REQ_005`. **레거시의 "미지정 시 0.0" 규약을 되살리지 말 것** — 위치를 얻기 전의 모든 검색이 통째로 빈다.
- **경로 조회(`GET /routes/last-routes`)의 정상 상태 에러 코드**(2026-09-25 실측): `TRS_011` = 출발지·도착지가 너무 가까움(→ `.noRoute`), `TRS_012` = 서비스 지역 밖(→ `.outOfServiceRegion`). `SearchLastRoutesUseCase.normalizedResult`가 매핑하며, 매핑 전에는 둘 다 throw되어 화면에 "검색에 실패했어요"만 떴다. 막차 종료 전용 코드는 아직 미관측.
- **응답 캐시는 실패뿐 아니라 빈 결과도 캐시하지 않는다**(`CachingPlaceRepository`). 빈 배열도 성공 응답이라 그냥 담으면 원인이 사라져도 TTL 내내 화면이 회복되지 않는다.
- 위치가 안 잡히는 증상은 원인이 여럿이라(권한 미결정 대기 / 거부 / 전역 OFF / 스트림 조기 종료) 밖에서는 전부 "출발지가 비어 있다"로 보인다. `CoreLocationServiceAdapter`가 DEBUG에서 `com.atcha.iOS.v2` 서브시스템 `Location` 카테고리에 업데이트별 플래그를 남긴다(좌표는 민감 정보라 미기록).
- AtchaV2는 iOS 26 전용. AlarmKit(CoreAlarm)·Live Activity(CoreLiveActivity + AtchaWidget 익스텐션)는 Phase 9~12에서 구축 완료.
- **막차 경로(`/routes/last-routes`) 응답 캐시는 의도적으로 미도입**이다. 장소·역지오코딩과 달리 틀렸을 때의 피해가 "막차를 놓친다"라서, 도입하려면 두 가지가 함께 와야 한다: ① 화면에 **"HH:mm 기준" 스탬프 필수**(스탬프 없이 표시 금지), ② **알람 등록 근거로는 캐시 사용 금지** — 지금 `RegisterAlarmUseCase`는 사용자가 고른 `LastRoute`를 그대로 받으므로, 이 규칙을 강제하려면 등록 시점 재조회가 필요해 시그니처가 바뀐다. TTL은 쓰지 않는다(막차의 유효 시간은 벽시계가 아니라 `departureTime` 자체다 — `RouteCardViewData.asPastTrain`이 이미 그 전환을 한다).
- Phase 12 이후의 갭 분석·후속 로드맵: `docs/planning/atcha-v2-post12-roadmap.md` / Phase 13·14(알람 이후 + 재실행 정합성) 구현 프롬프트: `docs/prompts/atcha-v2-session-lifecycle-prompt.md`.
- Phase 검수는 사람 검수 대신 **자동 검수 규약**(`docs/prompts/atcha-v2-auto-verification.md`)을 따른다 — 에이전트가 computer use로 시뮬레이터 검수를 직접 수행·증적 보고하고, 실기기 잔여 항목만 사용자에게 이관.
