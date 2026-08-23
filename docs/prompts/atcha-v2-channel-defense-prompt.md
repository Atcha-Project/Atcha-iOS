# AtchaV2 인지 채널 방어선 구현 프롬프트 — 폴백 확대 + time-sensitive + 노티 라우팅 + 권한 회복

> **사용법**: 이 문서 전체를 Claude Code에 컨텍스트로 전달하고 `"Phase 15를 진행해"`라고 지시한다.
> 실행 에이전트는 [마스터 프롬프트](atcha-v2-master-prompt.md)의 **진행 프로토콜·공통 규칙·공통 acceptance를 그대로 상속**하며, 한 번에 한 Phase만 수행한다.
> 갭 분석·우선순위 정본은 [Post-12 로드맵](../planning/atcha-v2-post12-roadmap.md)의 "Phase 15 — 인지 채널 방어선" 절. 충돌 시 **CLAUDE.md > 마스터 프롬프트 > [LA 프롬프트](atcha-v2-live-activity-prompt.md) > [세션 수명주기 프롬프트](atcha-v2-session-lifecycle-prompt.md) > 이 문서** 순.
> **검수는 사람 검수가 아니라 [자동 검수 규약](atcha-v2-auto-verification.md)을 따른다** — 실행 에이전트가 computer use로 직접 수행·증적 보고하고, 실기기 잔여 항목만 사용자에게 이관한다.
> 작성일: 2026-08-23.

---

## Goal (최상위)

**Phase 12의 폴백이 실전에서 뚫리는 지점을 막는다 — 어떤 설정의 유저에게도 인지 채널이 0이 되지 않게.**

Phase 10~12의 인지 계층은 "LA가 살아 있는 유저"를 전제로 설계됐고, 폴백 트리거는 dismiss 기록 하나뿐이다. 그래서 LA를 설정에서 꺼 둔 유저는 변경 alert를 어떤 채널로도 받지 못하고, 폴백 노티가 오더라도 심야에 흔한 집중 모드가 그것을 억제하며, 노티를 탭해도 시스템 기본 동작 외의 랜딩이 없고, 알림 권한을 거부한 유저는 자신이 무엇을 잃었는지 안내받지 못한다. 위치 권한을 설정에서 되살려도 홈은 `viewDidLoad` 1회 조회뿐이라 출발지가 돌아오지 않는다. 이 문서는 그 구멍들을 막는다. Phase 번호는 세션 수명주기 프롬프트의 13~14에 이어 **15**.

인지 채널 방어선의 완성 상태 (이 문서가 만드는 판정):

```
변경 판정(advanced/missed) 표출 시점
  ├─ 앱 포그라운드          ──► 인앱 채널 단일 (배너 강조 + 토스트) — LA alert·노티 없음 (이중 알림 0)
  └─ 앱 백그라운드
       ├─ LA alert 도달 가능 ──► LA alert (기존 경로)
       └─ LA alert 도달 불가 ──► 로컬 노티 (time-sensitive — 집중 모드 관통)
          = dismissed ∨ 활성 activity 없음 ∨ areActivitiesEnabled false

  노티 탭            ──► 홈 랜딩 (검색 플로우가 떠 있으면 접는다)
  알림 권한 거부      ──► 1회 안내 토스트 (재요청·재안내 스팸 없음)
  위치 권한 회복      ──► didBecomeActive 재확인 → 출발지 자동 재조회
```

확정된 제품 결정사항 (변경하려면 사용자에게 먼저 물을 것 — [로드맵](../planning/atcha-v2-post12-roadmap.md) 2026-08-23 확정):

| 항목 | 결정 |
|---|---|
| 폴백 조건 | `isDismissedByUser` 단일 → **"LA alert 도달 불가"** 3조건 합집합(dismissed ∨ 활성 activity 없음 ∨ `areActivitiesEnabled` false). 판정은 **어댑터의 단일 게터**로 — 호출자(AlarmSyncService)가 조건을 조립하지 않는다 |
| 폴백 확대의 의미 | **채널 갈아타기이지 LA 재생성이 아니다** — push-to-start 금지·dismiss 존중 정책 전부 불변 |
| 노티 강도 | 폴백 노티 전부 `.timeSensitive` interruptionLevel + time-sensitive entitlement — 집중 모드(심야에 흔함) 관통 |
| 노티 탭 랜딩 | **홈 랜딩** — 새 화면·딥링크·payload 파싱 없음. presented 정리 + 검색 플로우 접기. 앱 종료 상태에서의 탭은 스플래시 → 홈 자연 랜딩이 곧 목적지라 라우터가 할 일이 없다 |
| 포그라운드 표시 정책 | `willPresent` **`[.banner, .sound]` 명시** — 포그라운드에서는 애초에 노티를 발송하지 않는 것(표출 분기의 applicationState 선행 검사)이 1차 방어라 이중 알림은 구조적으로 없고, 이 정책은 "백그라운드 발송 → 활성화 직후 도달" 경합에서 유일한 가시 채널을 살리는 안전망이다 |
| 알림 권한 거부 안내 | **이번 호출로 최초 요청이 이뤄졌고 거부됐을 때만** 1회 토스트("막차 변경 알림을 받으려면 설정에서 알림을 허용해주세요"). 기존 재요청 금지 가드(요청 이력 키) 불변 — 이력이 있으면 요청도 안내도 없다 |
| 최후통첩 이중 알림 | 마지노선 침범 분기에 **applicationState 선행 검사** — 포그라운드면 조용한 LA 상태 갱신 + 인앱 채널 단일(일반 advanced 분기와 동일 구조). "포그라운드 여부와 무관하게 즉시"는 **백그라운드 한정**으로 정정한다 |
| 위치 권한 재확인 | `didBecomeActive` 시 출발지가 `needsSearch`일 때만 재조회. 재확인 경로는 **loading 전환·거부 토스트 없이** 조용히 — 성공 시에만 상태를 바꾼다(거부 유지 유저의 매 포그라운드 깜빡임·토스트 스팸 방지) |

---

## 이 문서가 다시 정의하지 않는 것 (중복 금지)

아래는 기존 Phase 산출물이다. **계약을 바꾸지 않고 명시된 지점만 확장한다.** 이 목록의 계약을 깨고 싶어지면 멈추고 사용자에게 물을 것.

| 산출물 | 소속 | 이 문서에서의 취급 |
|---|---|---|
| `LastTrainActivityPort` (Domain 문서 고정 계약) | Phase 10 | **시그니처 불변** (`isDismissedByUser` 포함). 도달 가능성 게터는 App 내부 확장 포트(`LastTrainChangeAlerting`)에만 추가 |
| `EvaluateAlarmChangeUseCase` / `AlarmChangeVerdict` | Phase 11 | 그대로 사용. 케이스 추가 금지 |
| 방향 비대칭(앞당김 alert/늦춤 조용)·배지 10분·행동 중심 문구 | Phase 11 | 불변 — 바뀌는 것은 **채널 선택 분기**뿐 |
| `LocalNotificationAdapter` 권한 요청 시점(등록 성공 직후 1곳)·재요청 금지 가드 | Phase 12 | 시점·가드 불변. **반환값만 확장**해 거부 사실을 위로 전달 |
| dismiss 감지·push-to-start 금지·사일런트 푸시 경로 requestAuthorization 금지 | Phase 8·10·12 | 그대로 유지 |
| 만료 판정·departed·스냅샷·고아 재부착·죽은 세션 재시작 | Phase 13·14 | 불변. 재시작이 `propagateChange`보다 선행하므로 재시작 성공 세션은 자연히 "도달 가능"으로 판정된다 |
| `AlarmSyncService` 3경로 일원화 구조·판정 훅 | Phase 8·11 | 구조 불변 — 폴백 분기의 **조건식 교체**와 최후통첩 분기의 **applicationState 선행 검사**만 |
| 서버 계약 전체 | 마스터 공통 규칙 | **서버 변경 0.** 이 문서의 전 작업은 클라 단독 |

## 전제 조건

1. **Phase 14 완료가 전제** (`feat/v2-phase14-relaunch-consistency` 기준). 이 문서 내부의 병렬 없음 — Phase 15 단일.
2. 서버 트랙(로드맵 S1~S4)과 **완전 독립** — 미확정 입력을 새로 요구하지 않는다. 검수는 [자동 검수 규약](atcha-v2-auto-verification.md)에 따라 DEV 데모 폴백·변경 시뮬레이터(플로팅 "변경" 버튼·dismiss 토글)를 재료로 에이전트가 직접 수행한다.
3. time-sensitive entitlement(`com.apple.developer.usernotifications.time-sensitive`)는 개발 서명·시뮬레이터에서 프로비저닝 없이 동작하는 것이 통례지만, 시뮬레이터 렌더가 라벨을 생략하면 판정을 "자동화 불가"로 기록하고 실기기 잔여로 이관한다(규약의 불가 시 분기).

---

## Phase 15 — 인지 채널 방어선

### Goal
LA alert가 도달할 수 없는 모든 상태에서 로컬 노티가 대신 서고, 그 노티가 집중 모드를 관통하며, 탭하면 홈에 내려앉고, 권한을 잃은 유저에게는 회복 경로(안내 토스트·설정 복귀 재조회)가 열리게 한다. 포그라운드 이중 알림은 구조적으로 제거한다.

### Requirements

- **폴백 조건 확대 (App — `LastTrainChangeAlerting` 확장)**: App 내부 확장 포트에 도달 가능성 게터를 추가하고, 어댑터(`LastTrainLiveActivityAdapter`)가 3조건을 단일 판정한다:
  ```swift
  /// Phase 15 — LA alert 도달 가능성 단일 판정.
  /// 보유 activity 있음 ∧ ActivityAuthorizationInfo().areActivitiesEnabled ∧ ¬dismissedByUser.
  /// false면 update(alert:)가 no-op이거나 잠금화면에 표면이 없다 — 호출자는 로컬 노티로 갈아탄다.
  var isAlertReachable: Bool { get async }
  ```
  `AlarmSyncService`의 alert 채널 분기 3곳(최후통첩·일반 advanced 백그라운드·missed)의 `isDismissedByUser` 조회를 전부 `!isAlertReachable`로 교체한다. Domain 포트의 `isDismissedByUser`는 시그니처 불변(문서 고정 계약)이고, dismiss 기록의 의미(재부착·재시작 금지 판정)도 그대로다. `sessionEnded`·`delayed`·`unchanged`의 조용한 경로는 폴백 대상이 아니다(행동을 요구하지 않는다 — 기존 정책 불변).
- **폴백 노티 time-sensitive (App 어댑터 + 매니페스트)**: `LocalNotificationAdapter.post`의 content에 `interruptionLevel = .timeSensitive`를 설정하고, `Projects/App/Project.swift`의 앱 타겟 entitlements DSL에 `com.apple.developer.usernotifications.time-sensitive: true`를 추가한다(기존 `aps-environment`와 병기 — 덮어쓰기 금지). 위젯 익스텐션은 노티를 발송하지 않으므로 대상 아님. 권한 요청 옵션(`[.alert, .sound]`)은 불변 — time-sensitive는 별도 런타임 권한이 없고, 유저가 설정에서 앱별로 끌 수 있는 것은 수용한다.
- **`UNUserNotificationCenterDelegate` 도입 (App 신규 파일)**: 델리게이트 어댑터를 App에 신설하고 `AppDelegate.didFinishLaunching`에서 `UNUserNotificationCenter.current().delegate`로 등록한다(탭이 앱을 cold start시키는 경우까지 잡으려면 launch 완료 전 등록이 필수).
  - `willPresent` → `[.banner, .sound]` 반환 (결정사항 — 근거 포함 주석 명시).
  - `didReceive`(탭) → 메인 액터 복귀 후 홈 랜딩 훅 호출. 훅은 SceneDelegate가 배선한다(`AppCoordinator`에 `returnToHome()` 신설 — presented가 있으면 dismiss, 내비게이션 스택을 홈 루트로 pop). payload 파싱·identifier 분기 없음 — 이 앱의 모든 노티는 폴백 노티 하나뿐이다.
  - 앱 종료 상태에서의 탭(훅 미배선 시점)은 버린다 — 스플래시 → 홈이 곧 랜딩이라 의미가 같다(주석 명시).
  - 프로그램적 pop은 `SearchCoordinator`의 `closeFlow()`를 타지 않아 자식 코디네이터가 잔존할 수 있다 — 스와이프 백 누수(Phase 17 몫)와 같은 계열이므로 **여기서 고치지 않고** 랜딩 지점 주석에 Phase 17 참조로 명시만 한다.
  - "UserNotifications import는 App에서 `LocalNotificationAdapter` 한 파일뿐" 주석 규칙은 "App 한정(어댑터 + 델리게이트)"으로 갱신한다 — Feature·Domain 유입 금지는 불변.
- **알림 권한 거부 1회 안내 (Domain 반환값 확장 + 홈 토스트)**: 포트·UseCase의 반환값을 확장해 "이번에 거부됨"을 위로 전달한다:
  ```swift
  public enum LocalNotificationAuthorizationOutcome: Sendable, Equatable {
      case granted          // 이번 호출로 요청이 이뤄졌고 허용됨
      case deniedNow        // 이번 호출로 최초 요청이 이뤄졌고 거부됨 — 1회 안내의 유일한 트리거
      case alreadySettled   // 요청 이력 있음(결과 무관) — 요청도 안내도 없다
  }
  // LocalNotificationPort
  @discardableResult
  func requestAuthorizationIfNeeded() async -> LocalNotificationAuthorizationOutcome
  // RegisterAlarmUseCase — 등록 성공의 후속 안내 신호(등록 실패 경로는 기존 throw 그대로)
  @discardableResult
  func execute(route: LastRoute) async throws -> LocalNotificationAuthorizationOutcome
  ```
  `DefaultRegisterAlarmUseCase`는 기존 훅 위치(등록 성공 마지막)에서 포트 결과를 그대로 반환한다(포트 nil이면 `.alreadySettled`). `HomeViewModel`은 등록 성공 시 `.deniedNow`일 때만 신규 `ToastEvent.notificationPermissionDenied`를 발화하고, VC는 "막차 변경 알림을 받으려면 설정에서 알림을 허용해주세요" 토스트를 띄운다. 요청 이력 키·"요청했음만 기록" 어댑터 가드는 불변 — 시스템 요청이 평생 1회이므로 안내도 구조적으로 최대 1회다. `@discardableResult`라 기존 콜사이트는 무변경, 스텁(Tests/Example)만 시그니처를 따라간다.
- **최후통첩 포그라운드 이중 알림 제거 (App — `AlarmSyncService.presentAdvanced` 마지노선 분기)**: 새 알람 시각이 이미 과거인 분기에 `UIApplication.shared.applicationState == .active` 검사를 선행한다 — 포그라운드면 LA alert·로컬 노티 없이 조용한 상태 갱신(imminent + 배지)만 하고, 사용자 주의는 인앱 채널(changes 스트림 → 배너 강조 + 토스트)이 단독으로 맡는다(일반 advanced·missed 분기와 동일 구조). 백그라운드면 기존대로 즉시 최후통첩(도달 가능 → LA alert / 불가 → 로컬 노티). 주석의 "포그라운드 여부와 무관하게"는 이 정정에 맞게 고친다.
- **위치 권한 `didBecomeActive` 재확인 (HomeFeature)**: `HomeViewController`가 `UIApplication.didBecomeActiveNotification`을 관찰해 `viewModel.didBecomeActive()`를 호출한다(관찰 해제는 기존 VC 수명 관례). ViewModel은 출발지가 `.needsSearch`(사유 무관)일 때만 재조회하고, 재확인 경로는:
  - `.loading` 전환 없이 기존 표시를 유지한 채 조회, **성공 시에만** `.current`로 갱신(깜빡임 방지).
  - 실패(여전히 거부·불가) 시 상태 유지 + **`locationPermissionNeeded` 토스트 재발화 금지** — 그 토스트는 최초 진입(viewDidLoad) 경로 1회뿐(스팸 방지).
  - `.loading`·`.current` 상태면 no-op(진행 중 재진입·불필요 재조회 방지 — 권한 팝업 닫힘도 didBecomeActive를 울리므로 이 가드가 필수다).
  `LocationError` 세분화(denied/restricted/전역 OFF)는 Phase 17 몫 — 기존 2케이스 그대로 쓴다.

### Constraints
- 알람 재스케줄·안전망 경로에 회귀 금지 — 채널 분기는 표출 계층에서만 바뀐다(재스케줄은 `RefreshAlarmUseCase.execute` 안에서 이미 끝난 뒤라는 기존 구조 불변).
- `UNUserNotificationCenter`·ActivityKit 심볼의 Domain·Feature 유출 금지(`tuist graph` + import 검사 — 기존 규약). 신규 델리게이트 파일 포함 전부 App.
- 알림 권한 요청 지점은 여전히 등록 성공 직후 한 곳 — 델리게이트·재확인 어디에도 새 요청 지점을 만들지 않는다(미확정 #8 유지). 사일런트 푸시 경로 requestAuthorization 금지도 그대로.
- `AlarmChangeVerdict` 케이스 추가 금지. `LastTrainActivityPort` 시그니처 불변.
- 판정·전이는 순수 함수/시각·상태 주입으로 테스트(실 `Date()`·실 UserDefaults 금지 — 기존 `now` 주입·인메모리 스텁 패턴 재사용). `isAlertReachable`·델리게이트 자체는 시스템 프레임워크 직결이라 단위 테스트 대상이 아니다 — 분기 정책(UseCase·ViewModel)을 스텁으로 테스트한다.
- Phase 16~18 선취 금지: pull-to-refresh·타임아웃·신선도 스탬프(16), `LocationError` 세분화·SearchCoordinator 누수 수정·arrivalField(17), 최근 경로 칩(18)은 이 문서 밖.

### Acceptance
공통 acceptance + `-scheme Domain test`(RegisterAlarmUseCase 반환값·outcome 정책) + `-scheme HomeFeature test`(권한 거부 토스트·didBecomeActive 재확인·재발화 금지).

### 자동 검수 (블로킹 — [자동 검수 규약](atcha-v2-auto-verification.md))
iOS 26 시뮬레이터에서 에이전트가 직접 수행하고 단계별 스크린샷 증적으로 보고:
① **LA 비활성 폴백**: 설정 앱에서 앗차의 Live Activity OFF → 알람 등록(LA 시작 no-op) → 백그라운드 전환 + DEV "변경" 버튼 앞당김 주입 → **로컬 노티 도달** 스크린샷("인지 채널 0" 해소의 직접 증명). 회귀 확인: LA ON + DEV dismiss 토글 ON 경로도 여전히 노티 폴백.
② **time-sensitive**: ①의 노티 배너에 "시간 민감형" 라벨 확인 스크린샷. 가능하면 집중 모드(방해금지) ON 상태에서 도달까지 — 시뮬레이터가 라벨·집중 모드 semantics를 렌더하지 않으면 "자동화 불가"로 기록하고 실기기 잔여로 이관(규약의 불가 시 분기).
③ **노티 탭 → 홈 랜딩**: 검색 화면 진입 상태로 백그라운드 → 폴백 노티 발생 → 노티 탭 → 검색 플로우가 접히고 홈(카드·배너)으로 복귀하는 스크린샷. 참고: 앱 `simctl terminate` 후 노티 탭 → 스플래시 → 홈 cold start 랜딩도 1회 확인.
④ **권한 거부 1회 안내**: `simctl uninstall` 후 재설치(요청 이력 초기화) → 등록 → AlarmKit 팝업 허용 → 알림 권한 팝업 **"허용 안 함" AXPress** → 안내 토스트 스크린샷 → 알람 해제 후 재등록 → 권한 팝업·토스트 **재발화 없음** 확인.
⑤ **최후통첩 이중 알림 제거**: 포그라운드 유지 상태에서 마지노선 침범 앞당김(데모 경로 기준 "5분 앞당김", 지연 0에 준하게) 주입 → 인앱 토스트 + 배너 "지금 출발하세요"만 표출되고 LA alert 경로를 타지 않았음을 화면 + 로그로 증적. 백그라운드 재주입 시 기존 최후통첩(LA alert 또는 노티)이 유지되는지 회귀 확인.
⑥ **위치 권한 재확인**: 위치 팝업 "허용 안 함" → 홈 `needsSearch` 상태 스크린샷 → 설정 앱에서 위치 허용 → 앱 복귀 → 출발지 라벨 자동 복원 스크린샷. 스팸 확인: 거부 유지 상태로 백/포그라운드 2회 반복 → 거부 토스트·출발지 깜빡임 재발 없음.

**실기기 잔여**: 집중 모드에서의 time-sensitive 노티 실표시(②가 시뮬레이터에서 판정 불가로 판명된 경우 — 판명 결과를 이 문서에 기록). 사일런트 푸시 실수신 경로의 폴백 동작(기존 항상-잔여 항목의 연장 — DEV 주입은 같은 `syncFromPush` 경로라 로직 검증은 시뮬레이터로 충분).

---

## 진행 프로토콜

[마스터 프롬프트의 진행 프로토콜](atcha-v2-master-prompt.md#진행-프로토콜) 1~6을 그대로 상속한다. 추가 규칙:

1. 이 문서는 **Phase 15 단일** — 내부 병렬 없음. Phase 14 완료 커밋 위에서 진행한다.
2. ["이 문서가 다시 정의하지 않는 것"](#이-문서가-다시-정의하지-않는-것-중복-금지) 표의 계약을 바꾸고 싶어지면 멈추고 사용자에게 물을 것.
3. Phase 16~18 산출물(pull-to-refresh, 타임아웃·오프라인 구분, 신선도 스탬프, App 테스트 타겟, `LocationError` 세분화, SearchCoordinator 누수 수정, 최근 경로 칩)을 **선취하지 않는다** — [로드맵](../planning/atcha-v2-post12-roadmap.md)의 몫.
4. 검수는 [자동 검수 규약](atcha-v2-auto-verification.md)을 따른다 — "자동 검수 (블로킹)"는 에이전트가 computer use로 수행·증적 보고를 마쳐야 다음 진행, "실기기 잔여"만 사용자에게 이관한다.
5. time-sensitive의 시뮬레이터 판정 불가가 확정되면 결과를 **이 문서 자동 검수 절에 기록**하고 실기기 잔여로 이관한다. 확정 전까지는 entitlement + interruptionLevel 설정을 코드 사실로 보고한다.

## 미확정 입력 (참조)

이 문서는 새 미확정 입력을 만들지 않는다. 관련 기존 항목의 취급:

| # | 항목 | 이 문서에서의 취급 |
|---|---|---|
| 8 | 알림 권한 요청 시점 | **시점 불변**(알람 등록 성공 직후) — 이 문서는 거부 이후의 안내만 추가한다. 시점 확정 시에도 안내 구조는 재사용된다 |
| 5·6·10 | FCM 토큰 전달·plist | 이 문서 밖(S2) — 폴백 노티는 로컬 발송이라 FCM 무관, plist 부재 상태에서 전 기능 성립(기존 기본선 유지) |
| 원장 전체 | [Post-12 로드맵](../planning/atcha-v2-post12-roadmap.md)의 "미확정 입력 원장" 절 참조 | |
