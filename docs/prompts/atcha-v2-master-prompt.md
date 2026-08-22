# AtchaV2 마스터 구현 프롬프트 — 막차 검색 + 알람

> **사용법**: 이 문서 전체를 Claude Code에 컨텍스트로 전달하고 `"Phase N을 진행해"`라고 지시한다.
> 실행 에이전트는 반드시 [진행 프로토콜](#진행-프로토콜)을 따르며, 한 번에 한 Phase만 수행한다.
> 작성일: 2026-08-22. 이 문서와 레포 `CLAUDE.md`가 충돌하면 **CLAUDE.md가 우선**한다.

---

## Goal (최상위)

**앗차 2.0의 핵심 가치를 완성한다: 오차를 감안하더라도, 가장 간편하고 쉽게 막차 시간을 알려주고 놓치지 않게 깨워주는 앱.**

사용자 플로우 전체:

```
스플래시(자동 익명 인증, 로그인 UI 없음)
  → 홈 (출발지=현재 위치 기본값 / 도착지 입력)
  → 검색 화면 (장소 검색 + 최근 검색 → 서버 기준 "가장 늦은 차" 1개 + 더보기로 대안 경로)
  → 경로 선택 → 홈 복귀 (선택 경로 카드 표출)
  → 알람 등록 (AlarmKit, 단일 알람 — 새 경로 등록 시 교체)
  → 홈 상단 배너 "막차 출발까지 N분" (1분 타이머 + 포그라운드 복귀 시 재조회)
  → 서버가 알람 시각 재계산 시 FCM 사일런트 푸시(또는 폴링 폴백)로 알람 자동 갱신
```

확정된 제품 결정사항 (변경하려면 사용자에게 먼저 물을 것):

| 항목 | 결정 |
|---|---|
| 서버 | 레거시 1.x와 **같은 서버** — 스펙 확정·구현됨. 장소 검색도 자체 서버 |
| 인증 | 자동 **익명 인증** (로그인 화면 없음, 스플래시에서 토큰 부트스트랩) |
| 출발지 | **현재 위치 기본값** + 위치 권한 플로우 (denied 시 검색 유도) |
| 알람 | AlarmKit **기본 UI**, **단일 알람만** (새 경로 등록 시 기존 알람 교체). Live Activity 위젯 익스텐션은 스코프 제외 |
| 알람 시각 | **서버가 계산·갱신**. 통지: FCM 사일런트 푸시 + 폴링 폴백 |
| 홈 배너 | "막차 출발까지 N분" — 1분 단위 타이머 갱신 + 포그라운드 복귀 시 서버 재조회 |
| 결과 표출 | 기본 "가장 늦은 차" 1개 강조 → "더보기"로 대안 경로 목록 확장 |
| 검색 편의 | **최근 검색만** 로컬 저장 (즐겨찾기 없음, 서버 저장 아님) |
| 막차 없음 UX | 서버 상태를 3가지로 정규화: 막차 있음 / 오늘 막차 종료(다음 운행 안내) / 경로 없음(안내 문구) |
| 설명글 2종 | "막차 시간과 가까워질수록 정확해져요" / "알람 시간은 막차 환경에 따라 변경될 수 있어요" — 홈에 상시 노출 |
| 디자인 | 기존 V2 DesignSystem을 고도화해서 사용 (레거시 `DesignSource/`는 시각 스펙 참고만) |

---

## 공통 규칙 (모든 Phase에 상속)

### 시작 절차

모든 Phase 시작 전에 반드시:

1. 레포 루트 `CLAUDE.md`를 읽는다 (아키텍처 규약·함정 목록의 원본).
2. 표준 템플릿을 읽는다: `Projects/Feature/Home/`(피처 구조), `Tuist/ProjectDescriptionHelpers/`(모듈 DSL).
3. 해당 Phase의 "레거시 참고 파일"을 읽는다 (아래 표).

### 공통 acceptance (모든 Phase 마지막에 전부 실행)

```bash
# 매니페스트(Project.swift/Workspace.swift) 수정한 경우에만
tuist generate --no-open

# 항상: Debug와 Stage 모두 빌드 (Stage 누락이 이 레포 1순위 함정)
xcodebuild -workspace Atcha.xcworkspace -scheme AtchaV2 -configuration Debug \
  -destination 'generic/platform=iOS Simulator' build
xcodebuild -workspace Atcha.xcworkspace -scheme AtchaV2 -configuration Stage \
  -destination 'generic/platform=iOS Simulator' build

# 해당 Phase에서 만들거나 수정한 모듈의 테스트
xcodebuild -workspace Atcha.xcworkspace -scheme <모듈명> \
  -destination 'platform=iOS Simulator,name=iPhone 17' test
```

### 공통 constraints

- **레거시 보호**: `Atcha-iOS.xcodeproj`와 `Atcha-iOS/` 소스는 읽기 전용. 절대 수정·삭제 금지 (CI/fastlane이 직접 빌드 중).
- **xcconfig 참조 금지**: 새 모듈·타겟에 xcconfig 의존을 추가하지 않는다. 환경 분기는 `AppEnvironment` 컴파일 플래그(DEV/STAGE/LIVE)로만.
- **의존 규칙**: Feature는 `AtchaData`를 절대 import하지 않는다. Domain은 무의존. 구체 Data/Network 타입은 `AppDIContainer`(조합 루트)만 본다. `tuist graph --format dot --no-open`으로 검증 가능.
- **외부 라이브러리는 앱 타겟에서만 링크** (내부 모듈 전부 static framework — 중복 심볼 방지). 내부 모듈에서 `import Firebase*` 금지.
- **`Tuist/Package.swift`·`Tuist/Package.resolved` 무변경**: 필요한 SPM(Firebase 3종, SnapKit)은 이미 선언·링크돼 있다. 새 의존성이 필요해 보이면 멈추고 사용자에게 물을 것.
- **Swift 6 + isolation**: 모든 ViewModel `@MainActor`, 비동기는 `Task` 보관 + `deinit`에서 cancel + `[weak self]` + `Task.isCancelled` 가드. Domain/AtchaData/CoreNetwork 및 신규 Core 모듈은 `.nonisolated` — `@MainActor` 어노테이션 유입 금지.
- **테스트는 Swift Testing** (`@Test`/`#expect`). XCTest 금지.
- **모듈 규율**: catch-all `Shared`/`Common` 금지 (목적별 단일 모듈). 모듈명 `Data` 금지 (Foundation.Data 섀도잉 — Data 레이어는 `AtchaData`).
- **UI**: UIKit 코드 기반(스토리보드 없음) + SnapKit + DS 토큰(`DSColor`/`DSFont`/`DSSpacing`) 경유. 색·폰트·간격 하드코딩 금지.
- **신규 프로젝트는 `Workspace.swift` 등록 필수** (누락 시 스킴이 생성되지 않는다).
- 레거시 코드는 **의미만 이식**한다: Alamofire·RxSwift 등 레거시 의존이 섞인 코드 복붙 금지 (V2는 URLSession + Swift Concurrency).

### 목표 모듈 지도 (전 Phase 완료 시점)

```
AtchaV2 (앱, 조합 루트: 어댑터/FCM/스플래시)
 ├─► HomeFeature ──► {HomeFeatureInterface, SearchFeatureInterface, Domain, DesignSystem, CoreCoordinator, SnapKit}
 ├─► SearchFeature ─► {SearchFeatureInterface, Domain, DesignSystem, CoreCoordinator, SnapKit}
 ├─► AtchaData ────► {Domain, CoreNetwork, CoreStorage}
 ├─► CoreAuth ─────► {CoreNetwork, CoreStorage}    ← import하는 곳은 App뿐
 ├─► CoreAlarm (무의존, AlarmKit 유일 import 지점)   ← import하는 곳은 App뿐
 └─► CoreStorage / CoreNetwork / CoreCoordinator / DesignSystem / Domain(무의존)
```

신규 모듈 4개: `SearchFeature`(`Project.feature()`), `CoreStorage`·`CoreAuth`·`CoreAlarm`(`Project.layer()`, 전부 `.nonisolated`).

디바이스 능력(위치·알람)은 **Domain 포트 + App 어댑터** 패턴: Domain에 순수 프로토콜(`LocationService`, `AlarmScheduler`)만 두고, CoreLocation/AlarmKit을 아는 어댑터는 `Projects/App/Sources/Adapters/`에 둔다. Feature는 UseCase 프로토콜만 본다.

### 서버 계약 뼈대 (직접 수록 — 필드 상세는 레거시 파일 참조)

모든 응답은 envelope로 감싸져 있다 (`Atcha-iOS/Core/Network/API/APIResponse.swift` 참고):

```swift
struct APIResponse<T: Decodable>: Decodable {
    let responseCode: ...   // 정확한 타입·성공값은 레거시 파일에서 확인
    let result: T?
}
```

| 용도 | 엔드포인트 | 비고 |
|---|---|---|
| 막차 경로 검색 | `GET /routes/last-routes?startLat&startLon&endLat&endLon` (레거시 실측) | 결과 목록의 첫 항목이 "가장 늦은 차", 나머지가 더보기 대안 |
| 경로 상세 | `GET /routes/last-routes/{routeId}` | |
| 알람(사용자 경로) 등록/삭제/조회 | `POST` / `DELETE` / `GET /routes/user-routes` | 단일 알람 정책: 등록 전 기존 것 삭제 또는 서버 교체 규약 확인 |
| 알람 시각 갱신 조회 | `GET /routes/user-routes/refresh` | 폴링 폴백과 푸시 수신 후 재조회 공용 |
| 장소 키워드 검색 | `GET /locations` (keyword·좌표 쿼리) | |
| 역지오코딩 | `GET /locations/rgeo` (좌표 쿼리) | 현재 위치 → 출발지 라벨 |
| 토큰 리프레시 | `GET /auth/reissue` | 리프레시 토큰을 `Authorization: Bearer`로 전달 (레거시 실측) |

쿼리 파라미터 이름·DTO 필드는 레거시 Repository/DTO 파일에서 확인해 이식한다. **이식 금지 목록**: SSE 스트림(`/routes/**/stream`), 서버 최근검색(`/locations/histories`, `/locations/history`), 실시간 도착(`/routes/user-routes/subway-arrival`, `bus-arrival`, `/transits/*`), 소셜 로그인(`/auth/login`, `/auth/sign-up`) — 전부 이번 스코프 밖.

### 레거시 참고 파일 표 (읽기 전용)

| 용도 | 경로 |
|---|---|
| 인증 의미 원본 (Bearer·공개경로·401 처리) | `Atcha-iOS/Core/Network/Token/TokenInterceptor.swift`, `TokenStorage.swift` |
| envelope·에러 규약 | `Atcha-iOS/Core/Network/API/APIResponse.swift`, `APIError.swift` |
| 막차 검색 API·DTO | `Atcha-iOS/Data/Repository/CourseRepositoryImpl.swift`, `Atcha-iOS/Data/Model/CourseSearchDTO/CourseSearchResponse.swift` |
| 알람 API·DTO | `Atcha-iOS/Data/Repository/AlarmRepositoryImpl.swift` |
| 장소 검색 API·DTO | `Atcha-iOS/Data/Repository/Location/` |
| 시각 스펙 참고 (컴포넌트) | `Atcha-iOS/DesignSource/` (AtchaTextField/AtchaList/AtchaToast 등) |
| V2 표준 템플릿 | `Projects/Feature/Home/`, `Tuist/ProjectDescriptionHelpers/` |

---

## Phase 1 — 서버 계약 이식: Domain 확장 + AtchaData 실 엔드포인트

### Goal
막차·장소·알람의 Domain 계약(엔티티/포트/UseCase)과 실서버 Data 구현을 완성한다 — UI 없이, 기존 더미 흐름과 병행.

### Requirements
- **Domain 엔티티**: `Place`(이름·주소·좌표), `LastRoute`(경로 요약 + `TransportLeg` 목록 + 막차 출발 시각), `AlarmInfo`(lastRouteId, 알람 시각, 막차 출발 시각, updatedAt), 정규화 열거형:
  ```swift
  public enum LastRouteSearchResult: Sendable, Equatable {
      case available([LastRoute])   // 첫 항목 = 가장 늦은 차
      case serviceEnded             // 오늘 막차 종료
      case noRoute                  // 경로 없음 (도보권 등)
  }
  ```
- **Domain 포트**: `PlaceRepository`(키워드 검색·역지오코딩), `LastRouteRepository`, `AlarmRepository`(서버 등록/삭제/refresh 조회), `RecentSearchRepository`(로컬 — 구현은 Phase 2), `AlarmScheduler`·`LocationService`(디바이스 포트 — 구현은 Phase 6~7).
- **UseCase** (프로토콜 + Default 구현): `SearchPlacesUseCase`, `SearchLastRoutesUseCase`(**정규화 책임** — 응답 코드/빈 목록 → `serviceEnded`/`noRoute` 매핑), `RegisterAlarmUseCase`(서버 등록 성공 → `AlarmScheduler.replaceAlarm` 순서, 단일 알람 정책), `CancelAlarmUseCase`, `RefreshAlarmUseCase`, `GetCurrentLocationUseCase`, `RecentSearchesUseCase`.
- **AtchaData**: `RouteEndpoint`/`PlaceEndpoint`/`AlarmEndpoint`(기존 `HomeEndpoint.swift` 패턴), `APIResponse<T>` envelope 디코딩 헬퍼, DTO는 위 레거시 파일에서 이식(optional 남발 정리, V2 네이밍, `toEntity()` 패턴), RepositoryImpl 구현.
- **테스트**: 레거시 응답 형태의 **인라인 JSON 문자열 픽스처**로 DTO 디코딩·`toEntity()`·정규화 테스트. UseCase는 스텁 리포지토리로 정책(등록 순서·정규화) 테스트.

### Constraints
- 기존 더미(`HomeSummary`/`FetchHomeUseCase`/`HomeRepositoryImpl`/`HomeEndpoint`) **삭제·수정 금지** — Phase 6에서 일괄 제거한다. 지금 지우면 HomeFeature·App 빌드가 붕괴한다.
- 이식 금지 목록(공통 규칙) 준수. Alamofire 타입 유입 금지.
- 픽스처는 리소스 파일 대신 인라인 문자열 (테스트 타겟 리소스 설정 회피).

### Acceptance
공통 acceptance + `-scheme Domain test` + `-scheme AtchaData test`.

### 사람 검수
엔드포인트·DTO 매핑 표를 보고용으로 출력하고 확인받을 것. 특히 **"막차 종료/경로 없음"을 서버가 어떻게 표현하는지(responseCode 값)는 [미확정 입력](#미확정-입력-사용자-제공-대기)** — 실측값을 받으면 정규화 로직에 반영.

---

## Phase 2 — CoreStorage 모듈 + 최근 검색 로컬 저장

### Goal
목적별 저장 모듈(CoreStorage)을 신설하고 최근 검색 로컬 저장을 구현한다.

### Requirements
- `Projects/Core/Storage`에 `Project.layer(name: "CoreStorage", bundleSuffix: "core.storage", isolation: .nonisolated)` + **Workspace.swift 등록**.
- `KeyValueStore` 프로토콜 + `UserDefaultsKeyValueStore` + `KeychainStore`(레거시 `TokenStorage.swift`의 키체인+메모리 캐시 패턴 참고, 프로토콜 기반 재작성 — Phase 3의 토큰 저장에 재사용) + Codable 저장 헬퍼.
- AtchaData에 `RecentSearchRepositoryImpl`(CoreStorage 사용): 최대 개수 제한(예: 10개), 중복 검색 시 최신으로 갱신, 최신순 정렬, 삭제 지원. `Projects/Data/Project.swift`에 CoreStorage 의존 추가.

### Constraints
- 테스트는 **인메모리 `KeyValueStore` 스텁**으로 (실 UserDefaults 사용 금지 — 테스트 오염).
- 앱 타겟 의존성에 CoreStorage를 추가하지 않는다 (AtchaData 경유; App이 직접 필요해지는 건 Phase 3의 CoreAuth부터).

### Acceptance
공통 acceptance + `-scheme CoreStorage test` + `-scheme AtchaData test`.

---

## Phase 3 — CoreAuth: 익명 세션 + 인증 데코레이터 + 스플래시

### Goal
로그인 UI 없는 익명 인증 체계를 구축하고, 모든 API 호출에 토큰을 투명하게 부착한다.

### Requirements
- `Projects/Core/Auth`에 `Project.layer(name: "CoreAuth", bundleSuffix: "core.auth", isolation: .nonisolated, dependencies: [CoreNetwork, CoreStorage])` + Workspace 등록.
- `TokenStore`(KeychainStore 주입, 액세스/리프레시 토큰 보관).
- `AuthSessionManager` **actor**: 익명 세션 부트스트랩(최초 실행 시 발급), `GET /auth/reissue` 리프레시(리프레시 토큰을 Bearer 헤더로 — 레거시 실측), **single-flight**(동시 다발 401에도 리프레시는 1회 — 레거시 `TokenInterceptor.swift`의 대기열 의미를 actor로 재구현).
- `AuthenticatedNetworkClient: NetworkClient` **데코레이터**: 기존 `URLSessionNetworkClient`를 감싸 Bearer 부착 → 401 시 리프레시 1회 → 재시도 → 리프레시도 실패하면 **익명 세션 재발급 후 재시도**. 공개 경로(인증 헤더 제외) 목록은 주입 가능하게.
- `AppDIContainer`에서 NetworkClient를 데코레이터로 교체 (교체 지점은 이 한 곳).
- `AppCoordinator`에 스플래시 단계: 로고 화면 → 인증 부트스트랩 완료 후 홈 진입, 실패 시 재시도 UI.
- `AppEnvironment`의 `apiBaseURL` 플레이스홀더를 실제 값으로 교체 ([미확정 입력](#미확정-입력-사용자-제공-대기)).

### Constraints
- 레거시 `SessionController.expireAndRouteToLogin` 패턴 **이식 금지** — V2에는 로그인 화면이 없다.
- CoreAuth를 import하는 곳은 **App뿐** (`tuist graph`로 확인).
- **AtchaData·Feature 코드가 한 줄도 안 바뀌어야 정상** — 바뀐다면 데코레이터 설계가 틀린 것.
- 테스트: 스텁 NetworkClient로 401→리프레시→재시도, single-flight 동시성, 공개 경로 예외 검증.

### Acceptance
공통 acceptance + `-scheme CoreAuth test`.

### 사람 검수 (블로킹)
**실 base URL과 익명 인증 발급 엔드포인트 스펙은 코드 어디에도 없다** (레거시는 소셜 로그인뿐, xcconfig는 gitignore). 코드·테스트는 완성하되, **실서버 스모크 전에 반드시 사용자에게 두 값을 확인**받을 것.

---

## Phase 4 — DesignSystem 고도화 *(Phase 1~3과 병렬 가능)*

### Goal
검색·결과·알람 UI에 필요한 재사용 컴포넌트를 DesignSystem에 추가한다.

### Requirements
- 컴포넌트 신설: `DSTextField`(검색 입력), `DSListCell`(장소/경로 리스트 셀 — 최근검색·검색결과·대안경로 공용), `DSRouteCard`(선택 경로 요약 카드), `DSBanner`(상단 카운트다운 배너), `DSToast`, `DSEmptyState`(막차 종료/경로 없음/권한 거부 공용 — 아이콘+제목+본문+선택적 액션 버튼).
- 설명글용 캡션 스타일(작은 안내 텍스트) 추가.
- 필요한 색·간격이 토큰에 없으면 **토큰부터 추가**하고 컴포넌트가 토큰을 쓰게 한다.
- 레거시 `Atcha-iOS/DesignSource/`는 **시각 스펙 참고용으로만** (코드 복붙 금지 — 레거시 컨벤션·의존이 다름).

### Constraints
- `.mainActor` isolation 유지 (DesignSystem 기존 설정).
- 에셋은 `DesignSystem.xcassets` + 기존 `asset(_:fallback:)` 폴백 패턴 준수 (static framework의 번들 처리).
- 기존 `DSButton` API 호환 유지 (파괴적 변경 금지).

### Acceptance
공통 acceptance + `-scheme DesignSystem test`.

### 사람 검수
레이어 모듈엔 Example 타겟이 없으므로 시각 검수는 Phase 5·6의 Example 앱에서 수행한다.

---

## Phase 5 — SearchFeature 신규

### Goal
장소 검색 → 막차 결과("가장 늦은 차" + 더보기) → 경로 선택 반환까지의 검색 플로우를 독립 실행 가능한 피처로 만든다.

### Requirements
- `Projects/Feature/Search`에 `Project.feature(name: "Search", ...)` 신설 (의존 구성은 `Projects/Feature/Home/Project.swift`를 그대로 본뜸) + Workspace 등록.
- Interface 타겟에 노출:
  ```swift
  @MainActor
  public protocol SearchCoordinatorBuildable {
      func makeSearchCoordinator(
          navigationController: UINavigationController,
          onRouteSelected: @escaping (LastRoute) -> Void
      ) -> any Coordinator
  }
  ```
- 화면 구성:
  - 출발지·도착지 입력 슬롯 (`DSTextField`), 키워드 검색은 **디바운스 + 이전 Task cancel**.
  - 최근 검색 리스트 (선택 시 즉시 적용, 스와이프/버튼 삭제).
  - 두 지점 확정 시 막차 결과: 최상단 "가장 늦은 차" 강조(`DSRouteCard`) + "더보기" 탭 시 대안 경로 목록 확장(`DSListCell`).
  - `serviceEnded`/`noRoute` 상태는 `DSEmptyState`로: 막차 종료 → "오늘 막차가 끊겼어요" + 다음 운행 안내(서버 제공 시)/재검색 유도, 경로 없음 → "대중교통 경로를 찾지 못했어요" + 재검색 유도.
- 경로 선택 → `onRouteSelected(entity)` 호출 + `finish()` (finishDelegate로 부모가 제거).
- ViewModel 테스트(스텁 UseCase: 성공/막차 종료/경로 없음/검색 실패), Example 앱은 스텁으로 전체 플로우 시연.

### Constraints
- **AtchaData import 금지** — UseCase 프로토콜만.
- Interface 타겟에는 프로토콜 + 최소 타입만 (구현 유출 금지).
- Entity를 뷰에 직접 노출 금지 — ViewData로 감쌀 것.
- navigationController는 weak (앱 루트만 강한 소유).
- 스텁이 Tests/Example에 중복되는 것은 의도된 트레이드오프 (기존 규약).

### Acceptance
공통 acceptance + `-scheme SearchFeature test` + `SearchFeatureExample` Debug 빌드.

### 사람 검수
`SearchFeatureExample`을 시뮬레이터에서 실행해 검색 UX(디바운스, 더보기 확장, 3가지 빈 상태) 시연.

---

## Phase 6 — HomeFeature 개편 (더미 제거 + 위치 권한 + 검색 연결)

### Goal
플레이스홀더 홈을 실제 홈으로 교체한다 — 현재 위치 출발지, 검색 진입, 선택 경로 표출, 알람 등록 버튼(로컬 스케줄은 아직 no-op).

### Requirements
- **홈 화면**: 출발지(현재 위치 기본값 — `GetCurrentLocationUseCase` + 역지오코딩 라벨)/도착지 필드 → 탭 시 `SearchCoordinatorBuildable`로 검색 플로우 시작 → `onRouteSelected` 수신 시 경로 카드(`DSRouteCard`) 표출.
- **위치 권한 플로우**: 홈 최초 진입 시 WhenInUse 요청. denied → 출발지 빈 상태 + "출발지를 검색해 주세요" 유도 + 설정 이동 안내. `Projects/App/Project.swift` infoPlist에 `NSLocationWhenInUseUsageDescription` 추가.
- App에 `CoreLocationServiceAdapter`(CLLocationManager → Domain `LocationService`) 구현·주입 (`Projects/App/Sources/Adapters/`).
- **알람 등록 버튼**: `RegisterAlarmUseCase` 호출 — 서버 등록은 실동작, `AlarmScheduler`는 App의 `NoopAlarmScheduler` 임시 어댑터 (Phase 7에서 교체).
- **설명글 2종** 상시 노출 (캡션 스타일): "막차 시간과 가까워질수록 정확해져요" / "알람 시간은 막차 환경에 따라 변경될 수 있어요".
- **상단 배너**: 알람 등록 상태면 `DSBanner`에 "막차 출발까지 N분" — 1분 단위 타이머 갱신 (실서버 갱신 연동은 Phase 7~8).
- **더미 일괄 청소**: `HomeSummary`·`FetchHomeUseCase`·`HomeRepository(+Impl)`·`HomeEndpoint`·`HomeSummaryRequestDTO/ResponseDTO`·관련 테스트 제거. `HomeDIContainer`·`AppDIContainer` 재구성. `Projects/Feature/Home/Project.swift`에 `SearchFeatureInterface` 의존 추가 + `tuist generate`.

### Constraints
- 더미 제거는 **이 Phase에서 일괄** (부분 제거 시 App 빌드 붕괴).
- HomeFeature가 SearchFeature **본체를 import하면 안 됨** — Interface만 (`tuist graph`로 확인).
- 타이머는 ViewModel이 Task로 보관 + `deinit` cancel.
- Example 앱은 스텁 LocationService·UseCase로 실행 가능해야 함.

### Acceptance
공통 acceptance + `-scheme HomeFeature test` + `HomeFeatureExample` Debug 빌드 + `tuist graph`로 의존 규칙 확인.

### 사람 검수 (중요)
시뮬레이터에서 **스플래시 → 홈 → 검색 → 경로 선택 → 홈 복귀 → (Noop) 알람 등록 → 배너 표시** 전체 플로우 시연 후 확인받을 것.

---

## Phase 7 — CoreAlarm: AlarmKit 스케줄링 E2E

### Goal
AlarmKit 래퍼 모듈을 만들고 알람 등록을 실제 디바이스 알람까지 연결한다 (단일 알람 교체 정책).

### Requirements
- `Projects/Core/Alarm`에 `Project.layer(name: "CoreAlarm", bundleSuffix: "core.alarm", isolation: .nonisolated)` (무의존 — Domain을 import하지 않는다) + Workspace 등록. **AlarmKit import는 이 모듈이 유일.**
- 중립 타입 API:
  ```swift
  public struct AlarmSpec: Sendable { public let id: String; public let fireDate: Date; public let title: String }
  public protocol AlarmKitScheduling: Sendable {
      func requestAuthorization() async -> Bool
      func replaceAlarm(_ spec: AlarmSpec) async throws   // 전부 취소 후 등록 (단일 알람 정책)
      func cancelAll() async
      func scheduledAlarm() async -> AlarmSpec?
  }
  ```
- App의 `NoopAlarmScheduler`를 CoreAlarm 기반 어댑터(CoreAlarm ↔ Domain `AlarmScheduler` 매핑)로 교체.
- 등록 플로우 완성: 버튼 탭 → **AlarmKit 권한 요청(이 시점이 최초)** → 서버 등록 → 로컬 스케줄 → 배너 표시. 권한 denied → 토스트 + 설정 이동 안내, 서버 등록 보류.
- 알람 해제 플로우: `CancelAlarmUseCase` → 서버 삭제 + 로컬 취소 + 배너 숨김.
- 포그라운드 복귀 시 `RefreshAlarmUseCase` 재조회 → 시각 변경 시 재스케줄 + 배너 갱신 (SceneDelegate → 알림 경유).

### Constraints
- AlarmKit 심볼이 Domain·Feature로 새어나가면 안 됨 (어댑터는 App에만).
- 단위 테스트는 AlarmKit 직접 호출 없이 — 교체·순서 정책은 Domain UseCase를 스텁 스케줄러로 테스트.
- **entitlements**: 현재 `NSAlarmKitUsageDescription`만 있고 entitlements 파일이 없다. AlarmKit 권한 요청이 실패하면 `Projects/App/Project.swift`에 Tuist `entitlements:` DSL로 추가 (수동 파일 생성 대신 매니페스트로).
- iOS 26 전용 API — 가용성 어노테이션 불필요 (배포 타겟이 이미 26.0).

### Acceptance
공통 acceptance + `-scheme CoreAlarm test` + `-scheme Domain test`(정책 테스트).

### 사람 검수 (블로킹)
**권한 다이얼로그와 실제 알람 발화는 자동 검증 불가** — iOS 26 시뮬레이터/실기기에서 사용자가 직접 확인해야 다음 Phase 진행.

---

## Phase 8 — 갱신 채널: FCM 사일런트 푸시(가드) + 폴링 폴백 + 하드닝

### Goal
서버발 알람 시각 갱신을 FCM(가능할 때)·폴링(항상)으로 반영하고, 전체 시나리오를 마감한다.

### Requirements
- **AppDelegate**: 기존 `GoogleService-Info.plist` 존재 가드 패턴 유지. 구성 성공 시에만 `MessagingDelegate` 설정 + `registerForRemoteNotifications()` 호출 (**알림 권한 프롬프트 없음** — 사일런트 푸시는 사용자 알림 권한 불필요).
- `didReceiveRemoteNotification`(content-available=1) 수신 → refresh 조회 → 재스케줄·배너 갱신.
- `Projects/App/Project.swift` infoPlist에 `UIBackgroundModes: ["remote-notification"]` 추가.
- **`AlarmSyncService`(App)로 갱신 일원화**: 앱 시작·포그라운드 복귀·푸시 수신 3경로가 전부 같은 `RefreshAlarmUseCase`를 경유하게 리팩터링 (Phase 7의 복귀 로직 흡수).
- FCM 토큰 서버 전달: 방식이 [미확정 입력](#미확정-입력-사용자-제공-대기) — 스펙 확인 후 구현, 그전까지는 토큰 로깅만.
- **하드닝 체크리스트** (전부 점검·수정): 막차 종료/경로 없음 UX, 위치·AlarmKit 권한 거부, 오프라인(네트워크 에러 시 토스트+재시도), 알람 교체(기존 알람 있는 상태에서 새 경로 등록), 배너 시각과 실제 알람 시각 일치, plist 부재 시 FCM 경로 완전 비활성.

### Constraints
- **plist 부재 상태에서 전 acceptance 통과가 기본선** — FCM 코드는 전부 dead-path여야 하고, 폴링만으로 전 기능이 성립해야 한다.
- 사일런트 푸시에 `UNUserNotificationCenter.requestAuthorization` 호출 금지.
- 내부 모듈 Firebase import 금지, `Tuist/Package.swift`·`Package.resolved` 무변경 확인 (git diff로).

### Acceptance
공통 acceptance + **Release 구성 빌드 1회 추가** + 전 모듈 테스트 스킴 일괄(`Domain`/`AtchaData`/`CoreStorage`/`CoreAuth`/`CoreAlarm`/`DesignSystem`/`SearchFeature`/`HomeFeature`) + `tuist graph`로 최종 의존 규칙 검증(모듈 지도와 일치).

### 사람 검수
`GoogleService-Info.plist` 발급 시 `Projects/App/Resources/`에 투입 → Firebase 자동 활성·푸시 수신 확인 (발급 전엔 폴링만으로 시연).

---

## 진행 프로토콜

1. **한 번에 한 Phase만.** 사용자가 지정한 Phase의 시작 절차(공통 규칙)부터 수행한다.
2. Phase 진행 중 **뒤 Phase의 산출물을 선취하지 않는다** (예: Phase 1에서 더미 제거, Phase 5에서 홈 연결).
3. Phase 완료 시 **acceptance 명령을 전부 실행하고 결과를 그대로 보고**한다 (실패를 숨기지 않는다).
4. **사람 검수 포인트가 있으면 정지**하고 확인을 요청한다. "블로킹" 표시가 있으면 확인 전 다음 Phase 진행 금지.
5. 이 문서의 결정사항과 다른 방향이 필요해 보이면 **임의로 바꾸지 말고 근거와 함께 사용자에게 물을 것.**
6. [미확정 입력](#미확정-입력-사용자-제공-대기)이 필요한 시점이 오면 사용자에게 요청하고, 받기 전까지는 명시된 임시 동작(플레이스홀더·로깅)으로 진행한다.
7. Phase 4(DesignSystem)는 Phase 1~3과 독립이므로 병렬(먼저) 실행 가능. 그 외에는 번호 순서가 기본값.

## 미확정 입력 (사용자 제공 대기)

| # | 항목 | 필요한 Phase | 받기 전 임시 동작 |
|---|---|---|---|
| 1 | 실서버 base URL (Dev/Stage/Live) | 3 | `AppEnvironment` 플레이스홀더 유지, 실서버 스모크 보류 |
| 2 | 익명 인증 발급 엔드포인트 스펙 (레거시엔 소셜 로그인뿐) | 3 | 프로토콜·스텁으로 구현, 실호출 보류 |
| 3 | "막차 종료"/"경로 없음"의 서버 표현 (responseCode 실측값) | 1 | 빈 목록 = `serviceEnded` 가정, TODO 주석 |
| 4 | 알람 등록 API의 단일 알람 규약 (서버가 교체? 클라가 삭제 후 등록?) | 1, 7 | 클라가 삭제 후 등록으로 가정, TODO 주석 |
| 5 | FCM 토큰 서버 전달 방식 (익명 체계에서) | 8 | 토큰 로깅만, 전달 보류 |
| 6 | `com.atcha.iOS.v2`용 GoogleService-Info.plist | 8 | plist 가드로 FCM 비활성, 폴링만 동작 |
