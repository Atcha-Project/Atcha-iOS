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
# 단일 테스트: -only-testing:HomeFeatureTests/HomeViewModelTests/viewDidLoad_success_transitionsLoadingToLoaded

# 의존 그래프 확인 (graph.dot 생성, gitignore됨)
tuist graph --format dot --no-open

# 레거시 빌드 — 디바이스 전용 (TMapSDK.framework가 arm64 디바이스 전용이라 시뮬레이터 빌드는 원래 불가)
xcodebuild -workspace Atcha.xcworkspace -scheme Atcha-Dev -configuration Debug \
  -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO build
```

도구는 mise로 고정(`mise.toml`, Tuist 4.202). `bundle exec`은 로컬에서 동작하지 않음(시스템 ruby 2.6 ↔ Gemfile.lock의 bundler 4.0 비호환) — fastlane은 CI 전용으로 취급.

### 알아야 할 함정

- **xcconfig 4개(Base/Dev/Stage/Live)는 gitignore돼 있고 없으면 `tuist generate`가 에러로 실패한다.** `Scripts/bootstrap.sh`가 빈 스탠드인을 만들어 해결한다(CI는 시크릿에서 실제 파일을 복원). AtchaV2는 xcconfig에 의존하지 않도록 설계돼 있으므로 새 모듈에 xcconfig 참조를 추가하지 말 것.
- 빌드 구성은 프로젝트 전체가 **Debug/Stage/Release 3개**. 새 타겟·외부 의존성 설정에 Stage가 누락되면 `-configuration Stage` 빌드가 조용히 깨진다(외부 SPM은 `Tuist/Package.swift`의 `PackageSettings.baseSettings`가 3구성을 선언).
- SPM 의존성 추가는 `Tuist/Package.swift`에서. `Tuist/Package.resolved`는 커밋 대상(Amplitude가 branch 추적이라 리비전 고정 역할).
- 레거시 소스 글롭에서 `Atcha-iOS/App/DIContainer/DIContainer.swift`는 의도적으로 제외(기존 pbxproj도 컴파일하지 않던 죽은 파일, AppDIContainer 중복 선언).

## 아키텍처 (AtchaV2 — uFeatures + 클린아키텍처)

```
AtchaV2(앱, 조합 루트) ─► HomeFeature ─► {HomeFeatureInterface, Domain, DesignSystem, CoreCoordinator, SnapKit}
        └─► AtchaData ─► {Domain, CoreNetwork}
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
- 모듈명 `Data`는 금지(Foundation.Data 섀도잉) — Data 레이어 모듈명은 `AtchaData`(디렉터리는 `Projects/Data`).
- UI는 UIKit 코드 기반(스토리보드 없음) + SnapKit + DesignSystem 토큰(`DSColor`/`DSFont`/`DSSpacing`).

### 미완 상태 (작업 시 참고)

- `AppEnvironment`의 API base URL은 플레이스홀더 — 실서버 주소 미정.
- `com.atcha.iOS.v2`용 GoogleService-Info.plist 미발급 — `AppDelegate`가 파일 존재를 가드한 뒤에만 `FirebaseApp.configure()` 호출. plist를 `Projects/App/Resources/`에 넣으면 자동 활성화.
- AtchaV2는 iOS 26 전용(AlarmKit 사용 예정). AlarmKit의 커스텀 알람 UI(Live Activity)는 추후 위젯 익스텐션 타겟이 별도로 필요.
