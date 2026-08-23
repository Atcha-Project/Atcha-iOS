# AtchaV2 갱신 신뢰성 구현 프롬프트 — 수동 갱신 + 타임아웃·재시도 + 오프라인 구분 + 신선도 스탬프 + App 테스트 타겟

> **사용법**: 이 문서 전체를 Claude Code에 컨텍스트로 전달하고 `"Phase 16을 진행해"`라고 지시한다.
> 실행 에이전트는 [마스터 프롬프트](atcha-v2-master-prompt.md)의 **진행 프로토콜·공통 규칙·공통 acceptance를 그대로 상속**하며, 한 번에 한 Phase만 수행한다.
> 갭 분석·우선순위 정본은 [Post-12 로드맵](../planning/atcha-v2-post12-roadmap.md)의 "Phase 16 — 갱신 신뢰성" 절. 충돌 시 **CLAUDE.md > 마스터 프롬프트 > [LA 프롬프트](atcha-v2-live-activity-prompt.md) > [세션 수명주기 프롬프트](atcha-v2-session-lifecycle-prompt.md) > [인지 채널 방어선 프롬프트](atcha-v2-channel-defense-prompt.md) > 이 문서** 순.
> **검수는 사람 검수가 아니라 [자동 검수 규약](atcha-v2-auto-verification.md)을 따른다** — 실행 에이전트가 computer use로 직접 수행·증적 보고하고, 실기기 잔여 항목만 사용자에게 이관한다.
> 작성일: 2026-08-23.

---

## Goal (최상위)

**갱신이 조용히 실패해도 앱이 거짓말하지 않게 한다 — 사용자에게 수동 갱신 수단을 주고, 네트워크가 빨리 실패하게 하고, 화면의 숫자가 언제 확인된 값인지 말한다.**

Phase 8의 갱신 채널은 자동 트리거 3경로(앱 시작·포그라운드 복귀·푸시)뿐이라 사용자가 지금 값을 의심해도 할 수 있는 일이 없고, Stage/Release의 URLSession은 기본 60초 타임아웃이라 심야의 약한 연결에서 스플래시·갱신이 1분을 침묵하며, 실패 문구는 원인 불문 "네트워크 연결을 확인해주세요" 하나고, sync 실패는 완전한 무음이라 배너·카드가 언제 값인지 아무도 모른다. 그리고 이 모든 판정·폴백 분기의 심장인 `AlarmSyncService`는 App 타겟에 테스트 타겟이 없어 **무테스트**다. 이 문서는 그 다섯 구멍을 막는다. Phase 번호는 인지 채널 방어선(15)에 이어 **16**.

[신뢰 UX 원칙](../planning/atcha-v2-post12-roadmap.md#신뢰-ux-원칙-전-phase-공통) 3("신선도 스탬프 — 갱신 실패를 토스트로 소음화하지 않고 조용히 정직하게")·4("안전망 약속의 문장화")의 직접 구현이다.

갱신 신뢰성의 완성 상태 (이 문서가 만드는 구조):

```
갱신 트리거 4경로 — 전부 같은 sync() 한 곳으로 (기존 3 + 수동 1, inFlight 합류)
  앱 시작 ────────────┐
  포그라운드 복귀 ─────┤──► AlarmSyncService.sync()
  사일런트 푸시 ───────┤        ├─ 성공 ──► updates(AlarmSyncUpdate: info + checkedAt)
  홈 pull-to-refresh ──┘        │            └─► 배너·카드 + "HH:mm 확인 기준" 스탬프
   (신설 — AlarmSyncRequesting)  └─ 실패 ──► 무음 — 스탬프가 낡은 시각을 정직하게 유지

  네트워크 요청 1회의 수명
    Stage/Release 타임아웃 10초(기본 60초 해소) ──► GET + transport 실패면 1회 재시도
    연결 자체가 없음 ──► NetworkError.offline ──► 스플래시 실패 문구 분기

  App 타겟 테스트 타겟(AtchaV2Tests) ──► AlarmSyncService 판정·폴백·만료 분기 회귀 방어
    (UIApplication.shared·Date() 직접 참조 → isAppActive·now 주입으로 교체)
```

확정된 제품 결정사항 (변경하려면 사용자에게 먼저 물을 것 — [로드맵](../planning/atcha-v2-post12-roadmap.md) 2026-08-23 확정):

| 항목 | 결정 |
|---|---|
| 수동 갱신 표면 | **홈 pull-to-refresh 단일** (새 버튼·화면 없음). Domain 포트 `AlarmSyncRequesting` + `RequestAlarmSyncUseCase` — 홈은 UseCase만 본다(Observe 계열과 같은 패턴). `AlarmSyncService`가 4번째 트리거로 순응하되 **기존 inFlight 합류를 재사용** — 당김·포그라운드 복귀가 겹쳐도 refresh는 1회다 |
| 수동 갱신 실패 | **무음** — 실패 토스트 금지(원칙 3: 소음화 지양). 스피너 종료 + 스탬프가 낡은 시각을 유지하는 것이 실패의 표면이다 |
| 스탬프 문구·위치 | **"HH:mm 확인 기준"** — 배너 보조 라인(`DSBanner` detailText) + 카드 푸터(`DSRouteCard` footnoteText) 두 서피스, 값은 단일 소스(State 필드 1개). 표출 조건: **등록 세션 존재 ∧ 확인 시각 존재**. 세션 정리(해제·만료·sessionEnded)와 함께 사라진다 — "지난 막차" 카드에는 스탬프가 없다 |
| 스탬프의 원천 | **서버가 값을 확인해준 시각만** — 등록 성공 시각·refresh 성공 시각. 홈이 수신 시각으로 찍지 않는다(스냅샷 시딩 복원값이 "지금 확인됨"으로 둔갑하는 거짓 방지). 시딩은 스냅샷에 영속화된 마지막 확인 시각(`syncedAt`)을 나른다 — 재실행·오프라인에서도 "마지막으로 확인된 그 시각"이 표시된다 |
| 타임아웃 | Stage/Release `URLSessionConfiguration.default` 기반 **request 10초 · resource 30초**. DEV의 3/5초는 검수용 임시 우회로 불변(제거 조건은 DevDemoFallbacks와 동반 — 기존 주석) |
| 재시도 | **멱등 GET 1회**, `URLSessionNetworkClient` 내부. 대상은 transport 계열(타임아웃·연결 끊김)만 — offline(즉시 재실패라 무의미)·취소(사용자 의사)·HTTP 상태·디코딩은 제외. **POST/DELETE 재시도 금지**(알람 등록·해제 이중 발사 방지) |
| 오프라인 구분 | `NetworkError.offline` 신설 — URLError `.notConnectedToInternet`·`.dataNotAllowed`만. `.networkConnectionLost`는 일시 장애로 transport 유지(재시도로 살리는 쪽이 맞다) |
| 스플래시 문구 | offline → "네트워크 연결을 확인해주세요"(기존 문구 유지) / 그 외 → **"일시적인 문제가 생겼어요. 잠시 후 다시 시도해주세요"**. 매핑은 App의 순수 헬퍼 함수로(테스트 대상). 현 DEV는 `bootstrap()`이 `issuerNotConfigured`를 삼켜 재시도 화면 자체가 안 뜬다 — 실표출은 S1(익명 인증) 이후이므로 **이 분기의 검수는 단위 테스트**다 |
| App 테스트 타겟 | `AtchaV2Tests` 신설(**host app 방식** — 앱 타겟 의존으로 internal 심볼 `@testable` 접근) + `AtchaV2` 스킴에 testAction. `AlarmSyncService`의 `UIApplication.shared` 직접 참조 3곳·`Date()` 직접 호출 5곳을 **주입(isAppActive·now)으로 교체** — 판정·폴백·만료 분기의 회귀 방어가 이 Phase의 핵심 산출물이다. 테스트 진입점은 `syncNow()`(수동 갱신과 동일 경로 — 부수 효과로 NotificationCenter 없이 전 분기 도달) |

---

## 이 문서가 다시 정의하지 않는 것 (중복 금지)

아래는 기존 Phase 산출물이다. **계약을 바꾸지 않고 명시된 지점만 확장한다.** 이 목록의 계약을 깨고 싶어지면 멈추고 사용자에게 물을 것.

| 산출물 | 소속 | 이 문서에서의 취급 |
|---|---|---|
| `AlarmSyncService` 3경로 일원화 구조·판정 훅·폴백 조건(`isAlertReachable`)·최후통첩 applicationState 선행 검사 | Phase 8·11·15 | **구조·조건 불변** — 수동 트리거가 같은 `sync()`에 합류하고, `UIApplication`/`Date()` 참조가 주입으로 바뀔 뿐 분기 의미는 그대로다. 분기들은 이제 회귀 테스트의 대상이 된다 |
| `LastTrainActivityPort`(문서 고정 계약) / `AlarmChangeVerdict` / `LocalNotificationPort` | Phase 10·11·12·15 | **시그니처 불변.** 케이스 추가 금지 |
| 스냅샷 = 재실행 브리지, 정본은 서버 | Phase 14 | 성격 불변 — `syncedAt` 필드 1개만 추가(Codable 하위호환: 구 스냅샷은 nil로 디코딩된다 — `decodeIfPresent` 합성) |
| `AlarmSyncEvents` replay-1·실패 무음 정책 | Phase 8 | 정책 불변 — **방출 타입만** `AlarmSyncUpdate`(info + checkedAt)로 확장. 실패는 여전히 스트림에 흐르지 않는다 |
| DEV 데모 폴백·변경 시뮬레이터·DEV 3/5초 타임아웃 | Phase 11·14 | 불변 — 검수 재료. **DEV refresh가 주입 없이는 실서버 실패를 그대로 실패시키는 동작**이 "무음 실패 시 스탬프 유지" 검수의 재료가 된다 |
| 서버 계약 전체 | 마스터 공통 규칙 | **서버 변경 0.** 미확정 #11("등록된 알람 없음" 표현)을 이 Phase가 해소하지 않는다 — pull-to-refresh도 알람 없음을 정리하지 않는다(기존 TODO 유지) |

## 전제 조건

1. **Phase 15 완료가 전제** (`feat/v2-phase15-channel-defense` 기준). 이 문서 내부의 병렬 없음 — Phase 16 단일.
2. 서버 트랙(로드맵 S1~S4)과 **완전 독립** — 미확정 입력을 새로 요구하지 않는다. 검수는 [자동 검수 규약](atcha-v2-auto-verification.md)에 따라 DEV 데모 폴백·변경 시뮬레이터를 재료로 에이전트가 직접 수행한다.
3. pull-to-refresh의 **당김 제스처** 자동화는 실측 제약(AX 액션 기반 조작만 신뢰)에 걸릴 수 있다 — 불가로 판명되면 규약의 불가 시 분기를 따른다(자동 검수 절에 명시).

---

## Phase 16 — 갱신 신뢰성

### Goal
사용자가 원할 때 갱신할 수 있고(당김), 갱신이 빨리 실패하고(타임아웃·재시도), 실패의 원인이 구분되고(오프라인), 화면의 숫자가 언제 확인된 값인지 항상 말하며(스탬프), 그 전 과정을 회귀 테스트가 지키게 한다(App 테스트 타겟).

### Requirements

- **수동 갱신 경로 (Domain 포트 + App 순응 + 홈 pull-to-refresh)**: Domain에 요청 포트와 UseCase를 신설한다:
  ```swift
  /// 수동 동기화 요청 포트(Phase 16) — 구현은 App의 AlarmSyncService(4번째 트리거).
  public protocol AlarmSyncRequesting: Sendable {
      /// 동기화 1회를 요청하고 완료까지 기다린다. 진행 중 동기화가 있으면 합류한다.
      /// 실패를 던지지 않는다 — 결과는 AlarmSyncEvents.updates()로만 흐른다(무음 정책 공유).
      func syncNow() async
  }
  // RequestAlarmSyncUseCase (프로토콜 + Default) — Observe 계열과 동일 패턴.
  ```
  `AlarmSyncService`는 `AlarmSyncRequesting`을 채택한다(`nonisolated func syncNow() async`가 메인 액터의 `sync()`로 hop — inFlight 합류가 이미 있어 재진입 무해). `HomeViewController`는 contentStack을 `UIScrollView`(alwaysBounceVertical)로 감싸고 `UIRefreshControl`을 부착한다 — 시각 레이아웃은 불변. `HomeViewModel.refreshPulled()`는 진행 중 재진입을 no-op으로 가드하고, 완료 시 `onManualSyncFinished` 훅으로 VC가 `endRefreshing()`한다. 수동 경로가 **새 표출 채널을 만들지 않는다** — 시각·상태 갱신은 기존 updates()/changes() 스트림이 그대로 담당한다.
- **Stage/Release 타임아웃 (App — `AppDIContainer`)**: `#else`(비-DEV) 분기의 `URLSessionNetworkClient`에 `URLSessionConfiguration.default` 기반 `timeoutIntervalForRequest = 10`, `timeoutIntervalForResource = 30` 세션을 주입한다. DEV의 3/5초 임시 우회 분기는 불변.
- **멱등 GET 1회 재시도 (CoreNetwork — `URLSessionNetworkClient`)**: `data(for:)`에서 `endpoint.method == .get`이고 첫 시도가 **transport로 분류되는** 실패면 즉시 1회 재시도한다. offline 분류·취소(`URLError.cancelled`/`CancellationError`)·HTTP 상태·디코딩 실패는 재시도하지 않는다. GET 외 메서드는 재시도 없음.
- **오프라인 구분 + 스플래시 문구 분기 (CoreNetwork + App)**: `NetworkError`에 케이스를 신설하고 분류를 전송 계층 한 곳에서 한다:
  ```swift
  public enum NetworkError: Error, Sendable {
      case invalidURL
      /// 연결 자체가 없음(URLError .notConnectedToInternet/.dataNotAllowed) — 재시도 무의미.
      /// .networkConnectionLost는 일시 장애로 transport 유지(재시도 대상).
      case offline(underlying: any Error)
      case transport(underlying: any Error)
      case invalidResponse
      case unacceptableStatus(code: Int, data: Data)
      case decoding(underlying: any Error)
  }
  ```
  `isOffline` 편의 게터를 함께 둔다. App에는 순수 매핑 헬퍼(예: `BootstrapFailureMessage.text(for: any Error) -> String`)를 신설해 `AppCoordinator.bootstrap()`의 catch가 `SplashViewController.showRetry(message:)`(시그니처 확장 — 기본 문구 유지)로 전달한다: offline → "네트워크 연결을 확인해주세요" / 그 외 → "일시적인 문제가 생겼어요. 잠시 후 다시 시도해주세요". 헬퍼는 `AtchaV2Tests` 대상 — 현 DEV에선 재시도 화면이 도달 불가(전제 조건 참고)라 UI 검수 항목이 아니다.
- **신선도 스탬프 (Domain 방출 확장 + 스냅샷 영속화 + 홈·DS 표출)**:
  - Domain: `AlarmSyncEvents.updates()`의 방출 타입을 확장한다(정책 불변 — 값에 확인 시각만 동봉):
    ```swift
    /// 동기화 성공 방출값 — info에 "언제 서버로 확인했는가"를 동봉한다(신선도 스탬프의 원천).
    public struct AlarmSyncUpdate: Sendable, Equatable {
        public let info: AlarmInfo
        /// 서버 확인 시각. 스냅샷 시딩 복원이면 직전 세션의 마지막 확인 시각, 그것도 없으면 nil(스탬프 없음).
        public let checkedAt: Date?
    }
    public protocol AlarmSyncEvents: Sendable {
        func updates() -> AsyncStream<AlarmSyncUpdate>
    }
    ```
    `ObserveAlarmUseCase`·`DefaultObserveAlarmUseCase`가 따라간다. `AlarmSessionSnapshot`에 `syncedAt: Date?`를 추가한다(init 기본값 nil + `updating`에 갱신 파라미터 — 구 스냅샷은 nil 디코딩으로 하위호환).
  - App: `AlarmSyncService`가 sync 성공 시 `checkedAt = now()`로 방출·스냅샷 병합 저장에 `syncedAt` 기록, 시딩 방출은 `snapshot.syncedAt`을 나른다. `DefaultRegisterAlarmUseCase`는 등록 성공 스냅샷 저장 시 `syncedAt = now()`(등록도 서버 확인이다).
  - HomeFeature: `State`에 `freshnessText: String?` 단일 필드 — "HH:mm 확인 기준"(기존 캐시 포매터 재사용). 표출 조건은 등록 세션 존재 ∧ 확인 시각 존재이고, 등록 성공 시 `now()` 기준으로 세팅, updates 수신 시 `checkedAt`으로 갱신(nil이면 유지하지 않고 nil — 낡음을 숨기지 않는다), 해제·만료·sessionEnded 정리 시 nil. 배너 틱은 스탬프를 건드리지 않는다(배너 텍스트와 독립).
  - DesignSystem(추가만 — 기존 API 파괴 금지): `DSBanner.configure(text:style:detailText: String? = nil)` — 스타일별 보조 톤의 caption 라인, nil이면 기존 렌더와 동일. `DSRouteCard.Content`에 `footnoteText: String? = nil` — caption·tertiary 푸터, muted 톤 대응. 색·폰트는 기존 토큰 경유(신규 토큰 불필요 판단이 기본).
  - VC: `render()`가 `state.freshnessText`를 배너 detailText와 카드 footnote 두 서피스에 반영한다(`RouteCardViewData.dsContent`는 footnote 주입 형태로 조정).
- **App 테스트 타겟 신설 (Tuist 매니페스트 + `AlarmSyncService` 주입 + 회귀 테스트)**:
  - `Projects/App/Project.swift`에 유닛 테스트 타겟을 추가하고 스킴에 연결한다:
    ```swift
    let testTarget = Target.target(
        name: "AtchaV2Tests",
        destinations: Atcha.destinations,
        product: .unitTests,
        bundleId: "\(Atcha.v2BundleID).tests",
        deploymentTargets: Atcha.v2Deployment,
        infoPlist: .default,
        sources: ["Tests/**"],
        dependencies: [.target(name: "AtchaV2")],   // host app — internal 심볼 @testable 접근
        settings: .atchaV2()
    )
    // AtchaV2 스킴: testAction: .targets(["AtchaV2Tests"]) 추가 (Debug 기본)
    ```
    Workspace.swift 변경 없음(기존 프로젝트에 타겟 추가). `tuist generate` 필수.
  - `AlarmSyncService`의 시스템 직결 지점을 주입으로 교체한다(기본값이 현 동작 — 콜사이트 무변경):
    ```swift
    init(
        ...,
        /// 표출 채널 분기용 앱 활성 판정(Phase 16) — UIApplication 직접 참조를 걷어내 테스트가 상태를 주입한다.
        isAppActive: @escaping @MainActor () -> Bool = { UIApplication.shared.applicationState == .active },
        /// 만료·판정·스탬프의 시각 주입 — 실 Date() 직접 호출 제거(기존 UseCase·VM 관례와 동일).
        now: @escaping @Sendable () -> Date = { Date() }
    )
    ```
    본문의 `UIApplication.shared.applicationState == .active` 3곳 → `isAppActive()`, `Date()` 5곳 → `now()`.
  - `Projects/App/Tests/`에 Swift Testing으로 회귀 테스트를 작성한다(스텁: 큐잉 `RefreshAlarmUseCase`, 고정 판정 `EvaluateAlarmChangeUseCase`, reachable 제어 가능한 `LastTrainChangeAlerting` 스파이, `LocalNotificationPort`·`AlarmScheduler`·`LastTrainSessionRestoring` 스파이, 인메모리 `AlarmSessionSnapshotStore` — Tests/Example 스텁 중복은 기존 트레이드오프). 진입은 `syncNow()`. 최소 커버 목록:
    1. advanced(actionable) **백그라운드 + reachable** → LA alert 1회, 로컬 노티 0
    2. advanced **백그라운드 + unreachable** → 로컬 노티 1회, LA alert 0 (Phase 15 폴백 회귀)
    3. advanced **포그라운드** → 조용한 update(alert nil)만 + verdict yield (인앱 채널 단독)
    4. **최후통첩**(새 알람 시각 과거·출발 미래) 포그라운드 → 조용한 update만, alert·노티 0 (Phase 15 이중 알림 제거 회귀)
    5. 최후통첩 백그라운드 reachable → LA alert / unreachable → 로컬 노티
    6. missed(actionable=false) 3분기(포그라운드 조용 / reachable alert / unreachable 노티)
    7. sessionEnded → 알람 취소 + 스냅샷 clear + LA end (배지 정리 포함)
    8. **클라 자체 만료**: 시딩된 과거 세션 + refresh 실패 → 알람 취소·expired 톰스톤·sessionEnded yield (Phase 13 회귀 — now 주입으로 시각 고정)
    9. **서버 우선**: 만료 후보 상태에서 refresh가 미래 출발 반환 → 만료 취소·정상 갱신
    10. **신선도**: sync 성공 → `checkedAt` = 주입 now / 시딩 → `snapshot.syncedAt` / 실패 → yield 없음
  - `BootstrapFailureMessage` 매핑 테스트(offline/기타/비 NetworkError)도 같은 타겟에 둔다.

### Constraints
- 알람 재스케줄·안전망 경로에 회귀 금지 — 이 Phase는 트리거 1개 추가·주입 교체·표출 확장뿐, `RefreshAlarmUseCase` 내부 정책과 판정·폴백 분기의 의미를 바꾸지 않는다.
- 수동 갱신 실패에 토스트·알럿 금지(결정사항). 오프라인 구분을 홈 표출에 쓰지 않는다 — 이번 스코프의 오프라인 분기는 스플래시 문구뿐.
- `UNUserNotificationCenter`·ActivityKit·`UIApplication` 심볼의 Domain·Feature 유입 금지(기존 규약 — `AlarmSyncRequesting`·`AlarmSyncUpdate`는 순수 타입). `tuist graph`로 의존 방향 확인.
- 테스트는 Swift Testing, 실 `Date()`·실 UserDefaults 금지(주입·인메모리 스텁 — 기존 관례). AtchaV2Tests는 host app에서 돌지만 **서비스 단독 인스턴스**를 만들어 테스트한다(앱이 띄운 전역 상태에 의존·간섭 금지).
- `Tuist/Package.swift`·`Package.resolved` 무변경. 레거시 무변경.
- Phase 17~18 선취 금지: 검색·홈 빈 상태, `arrivalField` 바인딩, `LocationError` 세분화, 오늘/내일 라벨, SearchCoordinator 누수 수정(17), 최근 경로 칩(18)은 이 문서 밖. 미확정 #11(알람 없음 표현) 해소 시도 금지 — 기존 TODO 유지.

### Acceptance
공통 acceptance + `-scheme Domain test`(AlarmSyncUpdate·RequestAlarmSyncUseCase·스냅샷 syncedAt) + `-scheme CoreNetwork test`(offline 분류·GET 재시도·비멱등 무재시도·취소 무재시도) + `-scheme DesignSystem test` + `-scheme HomeFeature test`(refreshPulled 가드·완료 훅·스탬프 표출/유지/정리) + **`-scheme AtchaV2 test`(신설 — App 타겟 회귀)**.

### 자동 검수 (블로킹 — [자동 검수 규약](atcha-v2-auto-verification.md))
iOS 26 시뮬레이터(Debug/DEV)에서 에이전트가 직접 수행하고 단계별 스크린샷 증적으로 보고. DEV refresh는 변경 주입이 없으면 실서버 실패를 그대로 실패시킨다 — 이 동작이 ②의 재료다.
① **스탬프 표출**: 데모 경로 알람 등록 → 배너 보조 라인·카드 푸터에 "HH:mm 확인 기준"(등록 시각) 표출 스크린샷.
② **무음 실패 정직성**: 1분 이상 경과 후 pull-to-refresh(주입 없음 → refresh 실패) → 스피너 종료 + **스탬프 시각 불변**(등록 시각 유지) + 실패 토스트 없음 스크린샷 — "낡았다고 말한다"의 직접 증명.
③ **수동 갱신 성공**: DEV "변경" 버튼으로 늦춤 주입 → pull-to-refresh → 배너 시각 갱신(조용한 delayed) + **스탬프가 현재 시각으로 갱신** 스크린샷 — 당김이 실동작하는 수동 갱신 수단이라는 직접 증명.
④ **재실행 복원**: `simctl terminate` → 재실행 → 시딩 스탬프가 **마지막 확인 시각을 유지**(재실행 시각으로 둔갑하지 않음) 스크린샷 (직후 자동 sync는 주입 없으면 실패하므로 관찰 가능).
⑤ **회귀**: 앞당김 주입 + 포그라운드 → 기존 인앱 채널(토스트 + 배너 강조) 동작 유지 + 스탬프 갱신. 스피너 진행 중 재당김 → 재진입 no-op(로그 증적).
당김 제스처 자동화가 불가로 판명되면(AX 기반 조작 한계): 판정을 "자동화 불가"로 기록하고, VM 경로는 단위 테스트로 검증돼 있으므로 **DEV 플로팅 디버그 메뉴에 검수용 "수동 갱신" 항목(syncNow 직결, DEV 한정 — 변경 시뮬레이터와 동일 취급)을 추가**해 ②·③의 스탬프 판정을 대체 수행하고, 실제 당김 제스처만 실기기 잔여로 이관한다.

> **검수 결과 기록 (2026-08-23 수행)**: ①③④⑤ 통과(증적 스크린샷 확보 — 스탬프 표출·성공 sync 전진·재실행 시딩 복원·포그라운드 인앱 채널+스탬프 갱신). ②의 "무음 실패 시 스탬프 유지"는 재실행 직후 자동 sync 실패(주입 없음)와 대기 관찰로 입증(23:14 스탬프가 23:17까지, 23:18 스탬프가 재실행 후에도 유지). **당김 제스처는 "자동화 불가" 판정** — orca 합성 마우스 드래그가 UIRefreshControl을 확정적으로 울리는지 스피너 증적을 잡지 못했다. 당김 아래 전 체인(refreshPulled → UseCase → syncNow → sync 합류)은 3계층 단위 테스트로 검증돼 있고 스탬프 판정 ②·③이 주입 sync로 이미 확보돼, 대체 수단(DEV "수동 갱신" 항목)은 추가하지 않았다. 실제 당김 제스처 실동작만 실기기 잔여로 이관.

**실기기 잔여**: pull-to-refresh 당김 제스처 실동작(위 기록 — 스피너 표출·당김 트리거 확인). 실서버 오프라인·타임아웃 실측(스플래시 문구 분기 실표출 포함 — 현 DEV는 issuerNotConfigured 삼킴으로 재시도 화면 도달 불가, S1 이후 확인). 사일런트 푸시 실수신 경로(기존 항상-잔여 항목).

---

## 진행 프로토콜

[마스터 프롬프트의 진행 프로토콜](atcha-v2-master-prompt.md#진행-프로토콜) 1~6을 그대로 상속한다. 추가 규칙:

1. 이 문서는 **Phase 16 단일** — 내부 병렬 없음. Phase 15 완료 커밋 위에서 진행한다.
2. ["이 문서가 다시 정의하지 않는 것"](#이-문서가-다시-정의하지-않는-것-중복-금지) 표의 계약을 바꾸고 싶어지면 멈추고 사용자에게 물을 것.
3. Phase 17~18 산출물을 **선취하지 않는다** — [로드맵](../planning/atcha-v2-post12-roadmap.md)의 몫.
4. 검수는 [자동 검수 규약](atcha-v2-auto-verification.md)을 따른다 — "자동 검수 (블로킹)"는 에이전트가 computer use로 수행·증적 보고를 마쳐야 다음 진행, "실기기 잔여"만 사용자에게 이관한다.
5. 당김 제스처 자동화 불가가 확정되면 결과를 **이 문서 자동 검수 절에 기록**하고 명시된 대체 수단(DEV 메뉴 항목)으로 검수를 완료한다.

## 미확정 입력 (참조)

이 문서는 새 미확정 입력을 만들지 않는다. 관련 기존 항목의 취급:

| # | 항목 | 이 문서에서의 취급 |
|---|---|---|
| 11 | 서버의 "등록된 알람 없음" 표현 | **미해소 유지** — pull-to-refresh도 실패 무음 정책을 공유하므로 유령 알람을 정리하지 않는다(기존 `HomeViewModel` TODO 그대로). 표현 확정 시 정리 이벤트가 이 스트림 위에 얹힌다 |
| 1 | Stage 전용 호스트 | 이 문서 밖 — 타임아웃 설정은 호스트와 무관하게 유효하다 |
| 2 | 익명 인증 발급 엔드포인트 | 이 문서 밖(S1) — 스플래시 문구 분기는 S1 이후 실표출되지만 매핑·테스트는 지금 완성한다 |
| 원장 전체 | [Post-12 로드맵](../planning/atcha-v2-post12-roadmap.md)의 "미확정 입력 원장" 절 참조 | |
