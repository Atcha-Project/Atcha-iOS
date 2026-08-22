# AtchaV2 인지 계층 구현 프롬프트 — 막차 변경 Live Activity + 알림

> **사용법**: 이 문서 전체를 Claude Code에 컨텍스트로 전달하고 `"Phase N을 진행해"`라고 지시한다.
> 실행 에이전트는 [마스터 프롬프트](atcha-v2-master-prompt.md)의 **진행 프로토콜·공통 규칙·공통 acceptance를 그대로 상속**하며, 한 번에 한 Phase만 수행한다.
> UX 정본은 [막차 시간 변경 알림 정책](../policy/last-train-change-notification.md), 아키텍처 정본은 마스터 프롬프트 + 레포 `CLAUDE.md`. 충돌 시 **CLAUDE.md > 마스터 프롬프트 > 이 문서** 순.
> 작성일: 2026-08-22.

---

## Goal (최상위)

**사명: 무조건 막차를 태워 보낸다.** 막차 시간이 변경됐을 때 유저가 확실히 인지하고 제때 출발하게 만드는 "인지 계층"을 Live Activity + 알림으로 구축한다.

이 문서는 마스터 프롬프트 Goal 표의 `Live Activity 위젯 익스텐션은 스코프 제외` 행을 **해제·초과하는 후속 스코프**다. Phase 번호는 마스터의 1~8에 이어 **9~12**.

채널 에스컬레이션 사다리 (주의 강도 순, 대체가 아닌 단계 관계):

```
0. 사일런트 푸시 + 폴링  → 알람 재스케줄·앱 동기화 (유저 비노출, Phase 8 산출물 — 이 문서 밖)
1. LA 조용한 업데이트    → 잠금화면·다이나믹 아일랜드 상시 최신값 (glance 인지)
2. LA + alert           → 화면 켜짐 + 워치 알림 (능동 인지)
2'. 포그라운드 인앱 채널  → DSBanner 갱신 강조 + DSToast (앱 사용 중일 때의 2단계 대체)
3. AlarmKit 알람        → 출발 시점 풀스크린 (안전망이자 최종 단계, Phase 7 산출물)
```

확정된 제품 결정사항 (변경하려면 사용자에게 먼저 물을 것 — 근거·상세는 정책 문서):

| 항목 | 결정 |
|---|---|
| 핵심 원칙 | **인지는 수단, 안전망은 로컬 알람.** 변경 수신 즉시 알람 재스케줄이 1순위, LA·alert는 보조 인지 채널 |
| v1 아키텍처 | **Phase 8 피기백 — 서버 변경 0.** 사일런트 푸시/폴링이 앱을 깨운 시점에 LA를 로컬 업데이트. 서버 주도 LA push는 v2 승격 옵션 |
| diff 계산 | **클라이언트**: 이전 값 = 로컬 저장 `AlarmInfo`, 새 값 = refresh 응답. payload 확장 불필요 |
| 알림 강도 | **방향 비대칭**: 앞당겨짐 → `alertConfiguration` 포함 업데이트(화면 켜짐) / 늦춰짐 → 조용한 업데이트. 임계값 승격 없음(YAGNI) |
| 메시지 | **행동 중심**: 제목 "15분 일찍 나가야 해요" + 본문 "막차가 23:40 → 23:25로 당겨졌어요" |
| LA 화면 | 긴급도 3단계 색(여유/주의/임박) 상시 + 변경 직후 "⚠ 당겨짐" 배지 10분 노출. 취소선·변경 흔적 상시 표시 없음 |
| 버퍼·스누즈 | **버퍼 = 스누즈 예산**: 알람은 기준 시각 −3분(고정, 설정 없음), 스누즈는 마지노선(기준 시각)까지만, 도달 후 "지금 안 나가면 못 타요" |
| 폴백 | LA dismiss 감지 → 이후 변경은 로컬 노티로 (push-to-start 재생성 금지 — 유저 의도 존중). 알림 권한 필요 |
| 알람 발화 후 변경 | 새 알람 시각이 이미 과거 → 즉시 최후통첩(임박 상태) / 미래 → `replaceAlarm` 재스케줄로 자동 처리 |
| 실패 상태 | 못 타게 됨(새 시간 < 현재 + 이동시간)·운행 종료 → LA final state 전환. 대안 제시(심야버스)는 [미확정 입력](#미확정-입력-사용자-제공-대기) |

---

## 이 문서가 다시 정의하지 않는 것 (중복 금지)

아래는 마스터 프롬프트 Phase 7·8의 산출물이다. **참조만 하고 재정의·재구현·수정하지 않는다.** 이 목록의 코드를 고치고 싶어지면 멈추고 사용자에게 물을 것.

| 산출물 | 소속 | 이 문서에서의 취급 |
|---|---|---|
| `CoreAlarm` · `AlarmKitScheduling` · AlarmKit 어댑터 | Phase 7 | 알람 재스케줄은 기존 경로 그대로 사용 |
| FCM 사일런트 푸시 수신 · 폴링 폴백 · `UIBackgroundModes` | Phase 8 | 앱을 깨우는 트리거로만 사용 |
| `AlarmSyncService` (앱 시작·포그라운드 복귀·푸시 수신 3경로 일원화) | Phase 8 | **유일한 훅 지점** — 갱신 성공 시점에 인지 계층을 이어 붙인다 |
| `RefreshAlarmUseCase` · `GET /routes/user-routes/refresh` | Phase 1·8 | 새 값의 유일한 출처 |
| 서버 계약 전체 | 마스터 공통 규칙 | v1은 서버 변경 0 — 새 엔드포인트·payload 제안 금지 |

## 전제 조건

1. **Phase 10~12는 마스터 Phase 7(CoreAlarm)·Phase 8(갱신 채널) 완료가 전제.** 예외는 Phase 9뿐 — 산출물이 전부 신규 파일이라 **마스터 Phase 7~8과 병렬 진행 가능** (Phase 9의 병렬 가드 준수).
2. **`GoogleService-Info.plist` 투입 (하드 전제)** — FCM이 없으면 백그라운드 깨움이 없어 피기백이 폴링(포그라운드 전용)으로 퇴화한다. 미투입 상태로도 빌드·구현은 진행하되, 백그라운드 인지 시연이 불가함을 사용자에게 고지할 것 (마스터 미확정 입력 #6).
3. V2에는 현재 entitlements·`NSSupportsLiveActivities`·위젯 익스텐션 인프라가 전무하다 — Phase 9가 이를 만든다.

---

## Phase 9 — 빌드 인프라: 위젯 익스텐션 타겟 + CoreLiveActivity + entitlements *(마스터 Phase 7~8과 병렬 가능)*

### Goal
Live Activity를 올릴 수 있는 빌드 기반을 만든다 — 위젯 익스텐션 타겟, 공유 Attributes 모듈, entitlements. UI·로직 없이 빈 껍데기까지만.

### Requirements
- **Tuist DSL 확장**: `Tuist/ProjectDescriptionHelpers/`에 위젯 익스텐션 타겟 헬퍼 신설(또는 `Projects/App/Project.swift`에 인라인 선언). `product: .appExtension`, bundleId `com.atcha.iOS.v2.widget`(앱 접두 필수), infoPlist에 `NSExtension` → `NSExtensionPointIdentifier: com.apple.widgetkit-extension`, **settings는 반드시 `Settings.atchaV2()` 경유** (Stage 3구성 함정 — 이 레포 1순위 함정).
- **앱 타겟 dependencies에 `.target(name:)`으로 익스텐션 추가** → Tuist 자동 임베드.
- **`CoreLiveActivity` 공유 모듈**: `Projects/Core/LiveActivity`에 `Project.layer(name: "CoreLiveActivity", bundleSuffix: "core.liveactivity", isolation: .nonisolated)` + Workspace 등록. `ActivityAttributes` 정의(막차 세션 고정 정보) + `ContentState`(출발 시각, 알람 시각, 긴급도 단계, 변경 배지 만료 시각, 세션 상태) — 앱·익스텐션 양쪽에 링크 (전부 static framework라 중복 심볼 문제 없음). **ActivityKit import는 CoreLiveActivity·위젯 익스텐션·App 어댑터 3곳으로 한정** — Domain·Feature 유출 금지.
- **entitlements**: `Projects/App/Project.swift`에 Tuist `entitlements:` DSL로 `aps-environment` 추가 (마스터 Phase 7 Constraints의 "수동 파일 대신 매니페스트로" 방침 준수). 익스텐션 타겟도 동일 DSL 경유.
- **infoPlist 키**: 앱 타겟에 `NSSupportsLiveActivities: true`. `NSSupportsLiveActivitiesFrequentUpdates`는 추가하지 않는다 (저빈도 정책 — 필요해지면 사용자에게 물을 것).
- **UI 규약 예외 선언**: 위젯 익스텐션은 SwiftUI + WidgetKit — 레포 UIKit 규약의 **유일한 명시적 예외**. DesignSystem 토큰(`DSColor` 등 UIColor 기반)의 SwiftUI 브리지(`Color(uiColor:)`) 헬퍼를 CoreLiveActivity 또는 익스텐션 내부에 둔다 (DesignSystem 모듈 수정 최소화).
- 익스텐션에 플레이스홀더 위젯(빈 잠금화면 뷰)까지만 — 실제 UI는 Phase 10.

### Constraints
- **Firebase 등 외부 라이브러리를 익스텐션에 링크 금지** (공통 constraints).
- `Tuist/Package.swift`·`Package.resolved` 무변경 (ActivityKit·WidgetKit은 시스템 프레임워크).
- CoreLiveActivity는 Domain을 import하지 않는다 (CoreAlarm과 동일한 무의존 원칙 — 중립 타입만).
- **병렬 가드** (마스터 Phase 7~8과 동시 진행 시):
  - **별도 브랜치**에서 진행 (Phase 6 완료 커밋 기준). Phase 7~8 브랜치의 파일을 건드리지 않는다.
  - 공유 충돌 지점은 2파일뿐: `Projects/App/Project.swift`(Phase 7도 AlarmKit entitlements를 추가할 수 있음)·`Workspace.swift`(양쪽 다 모듈 등록). **신규 파일 작업(헬퍼·CoreLiveActivity·익스텐션)을 먼저 완성하고, 이 2파일의 수정은 최소 diff로 마지막에** — Phase 7~8 머지 후 리베이스 시 충돌을 몇 줄로 한정한다.
  - entitlements 병합 시 **양쪽 항목을 모두 유지** (aps-environment + AlarmKit 관련) — 한쪽을 덮어쓰지 않는다.
  - acceptance는 자기 브랜치에서 통과시키고, **Phase 7~8 머지 후 리베이스한 뒤 공통 acceptance를 한 번 더 실행**해야 Phase 10 진입 가능.

### Acceptance
공통 acceptance (tuist generate + Debug·Stage 빌드 — 익스텐션은 앱 스킴에 임베드되므로 앱 빌드가 커버) + `-scheme CoreLiveActivity test`.

### 사람 검수
빌드 산출물에 익스텐션이 임베드됐는지(`.app/PlugIns/`) 확인 보고. 시각 검수는 Phase 10에서.

---

## Phase 10 — LA 라이프사이클 + 화면: 시작/종료 + 긴급도 색

### Goal
알람 등록 세션과 Live Activity의 수명을 일치시키고, 잠금화면·다이나믹 아일랜드 화면을 정책 3대로 구현한다.

### Requirements
- **Domain 포트** (포트+어댑터 패턴 — 마스터 공통 규칙): Domain에 순수 프로토콜 신설:
  ```swift
  public protocol LastTrainActivityPort: Sendable {
      func start(session: AlarmInfo, route: LastRoute) async
      func update(state: LastTrainActivityState, alert: Bool) async
      func end(final: LastTrainActivityState) async
      var isDismissedByUser: Bool { get async }
  }
  ```
  App의 `Projects/App/Sources/Adapters/`에 ActivityKit 어댑터 구현 (`AppDIContainer` 주입 — `NoopAlarmScheduler` 교체와 동일 패턴). Feature는 이 포트를 직접 보지 않는다 — UseCase 경유.
- **수명 연동**: `RegisterAlarmUseCase` 성공 → LA 시작. `CancelAlarmUseCase` → LA 종료. 알람 발화 후 세션 종료 시점(막차 출발 시각 경과) → final state로 종료.
- **잠금화면 + 다이나믹 아일랜드 UI** (정책 3):
  - 잠금화면: 노선명·"출발까지 ⏱ N분" 카운트다운·출발 시각·도보 안내. 다이나믹 아일랜드: compact(카운트다운) / expanded(잠금화면 축약).
  - **긴급도 3단계 색** 상시: 여유/주의/임박 — 임계 정의는 Domain에 두고(예: 남은 시간 비율), 색 토큰은 DSColor의 SwiftUI 브리지 경유. 기존 `DSBanner.Style`(normal/urgent 2단계)과 단계 의미가 어긋나지 않게 매핑 정리.
  - "⚠ 당겨짐" 배지 슬롯 (표시 조건은 Phase 11에서 연결).
- **dismiss 감지**: 어댑터가 `activityStateUpdates` 관찰 → 유저 스와이프 dismiss를 로컬에 기록 (Phase 12의 폴백 트리거).
- **구현 노트 — LA 예약 업데이트 불가 제약**: LA는 미래 시점 상태 변경을 예약할 수 없다. 카운트다운은 `Text(timerInterval:)` 등 시스템 타이머 뷰로 렌더 고정을 우회하고, **`staleDate`를 설정**해 갱신이 끊긴(강제종료 등) LA가 오래된 정보를 신선한 것처럼 보이지 않게 방어한다. 긴급도 색 전환은 앱 깨움 시점(푸시·폴링·알람 발화·포그라운드 복귀)마다 재평가로 근사 — 이 한계를 코드 주석으로 명시.

### Constraints
- ActivityKit 심볼이 Domain·Feature로 새어나가면 안 됨 (`tuist graph` + import 검사).
- 익스텐션 UI는 CoreLiveActivity의 `ContentState`만 소비 — 네트워크·저장소 접근 금지.
- 단위 테스트는 ActivityKit 직접 호출 없이 — 수명 정책(등록→시작, 취소→종료)은 Domain UseCase를 스텁 포트로 테스트. 긴급도 임계 계산은 순수 함수로 분리해 테스트.

### Acceptance
공통 acceptance + `-scheme Domain test` + `-scheme CoreLiveActivity test`.

### 사람 검수 (블로킹)
**LA 표시는 자동 검증 불가** — iOS 26 시뮬레이터/실기기에서 알람 등록 → 잠금화면·다이나믹 아일랜드 표시 → 취소 시 소멸을 사용자가 직접 확인해야 다음 Phase 진행.

---

## Phase 11 — 변경 반영 피기백: diff 판정 + 방향 비대칭 + 버퍼

### Goal
Phase 8의 갱신 성공 지점에 인지 계층을 이어 붙인다 — 변경 판정은 Domain, 표출은 어댑터. 버퍼·마지노선 정책을 알람 스케줄에 반영한다.

### Requirements
- **Domain 변경 판정 UseCase** (정책의 코드화 — 이 문서의 심장):
  ```swift
  public enum AlarmChangeVerdict: Sendable, Equatable {
      case unchanged
      case delayed(by: TimeInterval)                  // 늦춰짐 → 조용한 업데이트
      case advanced(by: TimeInterval, actionable: Bool) // 앞당겨짐 → alert. actionable=false면 이미 못 탐
      case sessionEnded                               // 운행 종료·경로 소멸
  }
  public protocol EvaluateAlarmChangeUseCase: Sendable {
      func execute(previous: AlarmInfo, latest: AlarmInfo, now: Date) -> AlarmChangeVerdict
  }
  ```
  diff는 **클라 계산**: 이전 = 로컬 저장 `AlarmInfo`, 최신 = refresh 응답. 스텁 없이 순수 로직이므로 경계 케이스(동일 시각·자정 경계·과거 시각) 테스트 필수.
- **`AlarmSyncService` 훅**: 3경로(앱 시작·포그라운드 복귀·푸시 수신) 갱신 성공 → 판정 → ① 알람 재스케줄(기존 경로, 무조건 선행 — 핵심 원칙) ② LA 업데이트: `advanced` → `alert: true` + 행동 중심 문구("N분 일찍 나가야 해요" / "막차가 HH:mm → HH:mm로 당겨졌어요") + 배지 만료 시각 = now + 10분 (배지 소멸은 익스텐션이 타이머 뷰 조건으로 처리 — Phase 10 노트) / `delayed` → 조용한 업데이트.
- **포그라운드 인앱 채널**: 앱이 포그라운드인 상태로 판정이 나오면 LA alert 대신 **DSBanner 갱신 강조 + DSToast**("막차가 15분 당겨졌어요"). 채널 선택(포그라운드/백그라운드)은 훅에서 분기.
- **버퍼·마지노선** (정책 5): `RegisterAlarmUseCase`·재스케줄 경로가 **기준 시각 −3분**에 로컬 알람을 걸도록 수정 (현재 departureTime 그대로 스케줄 중 — `RegisterAlarmUseCase.swift`). 기준 시각은 [미확정 입력 #7](#미확정-입력-사용자-제공-대기) — 받기 전엔 클라 계산. 배너·LA의 "출발까지 N분"도 같은 기준으로 통일 (이중 시각 금지).
- **스누즈 클램프 검증**: AlarmKit 기본 UI의 반복(스누즈) 버튼으로 "마지노선까지만" 클램프가 가능한지 검증 — **불가하면 반복 버튼 제거 + 단발 알람 폴백**을 적용하고 결과를 사용자에게 보고 (정책 문서 Phase 7 검증 항목).
- **알람 발화 후 변경 도착**: 새 알람 시각이 이미 과거 → 즉시 최후통첩(임박 상태 + alert "지금 안 나가면 못 타요") / 미래 → 기존 `replaceAlarm` 재스케줄로 자동 처리 (분기 로직은 판정 UseCase의 `actionable`·now 파라미터로).
- **디버그 변경 시뮬레이터**: 실서버 변경을 기다릴 수 없으므로, DEV 빌드 한정 디버그 메뉴(또는 스텁 refresh)로 "N분 앞당겨짐/늦춰짐/종료" 주입 수단을 만든다 — 사람 검수의 전제.

### Constraints
- `AlarmSyncService`·`RefreshAlarmUseCase`의 기존 계약을 바꾸지 않는다 — 훅은 갱신 성공 이후에 덧붙이는 방식 (Phase 8 코드 최소 침습).
- 알람 재스케줄이 LA 업데이트보다 **항상 선행** — LA 실패가 알람을 막으면 안 됨 (핵심 원칙의 코드 표현).
- 메시지 문구는 하드코딩 상수로 두되 한 파일에 모을 것 (추후 문구 정책 변경 대비).

### Acceptance
공통 acceptance + `-scheme Domain test`(판정 UseCase 경계 케이스 포함) + `-scheme HomeFeature test`(배너 갱신).

### 사람 검수 (블로킹)
디버그 시뮬레이터로 **앞당겨짐(백그라운드 → LA alert 화면 켜짐 / 포그라운드 → 배너+토스트), 늦춰짐(조용한 갱신), 알람 후 변경(즉시 최후통첩)** 3종 시연 후 확인받을 것. 스누즈 클램프 검증 결과(가능/폴백 적용)도 이때 보고.

---

## Phase 12 — 폴백·하드닝: dismiss 로컬 노티 + 실패 상태 + 마감

### Goal
인지 계층의 구멍(LA를 지운 유저, 못 타게 된 유저, 세션 소멸)을 막고 전체 시나리오를 마감한다.

### Requirements
- **알림 권한 요청**: `UNUserNotificationCenter.requestAuthorization`을 [미확정 입력 #8](#미확정-입력-사용자-제공-대기)의 시점에 요청 (임시: 알람 등록 성공 직후). **AlarmKit 권한 요청(Phase 7, 등록 버튼 탭 시점)과 연속 팝업이 되지 않게** 순서·간격을 설계하고 사람 검수에서 확인. 거부 시: LA·알람은 정상 동작(LA는 알림 권한 불필요), 로컬 노티 폴백만 비활성 — 상태를 기록해 두고 재요청 스팸 금지.
- **dismiss 폴백**: Phase 10의 dismiss 기록이 있으면 이후 `advanced` 판정 시 LA alert 대신 **로컬 노티**(같은 행동 중심 문구) 발송 — 피기백 시점엔 앱이 깨어 있으므로 서버 무관여로 가능. push-to-start 재생성 금지.
- **실패·종료 상태**: `advanced(actionable: false)`(못 타게 됨) → LA를 실패 상태로 전환 + "막차가 지나갔어요" (대안 제시는 미확정 입력 #9 — 받기 전엔 문구만). `sessionEnded`(운행 종료·경로 소멸 — refresh가 경로 없음 반환) → LA final state 종료 + 알람 취소 + 배너 정리.
- **하드닝 체크리스트** (전부 점검·수정): 알림 권한 거부, 유저가 설정에서 LA 비활성(`areActivitiesEnabled` false — 알람만으로 동작), LA 8시간 제한 초과 세션, 강제종료 후 stale LA(`staleDate` 동작 확인), 자정 경계 시간 계산(23:40 → 00:10 등 날짜 넘김 diff·카운트다운), plist 부재 시 인지 계층이 폴링 경로에서만이라도 정상 동작, dismiss 기록의 세션 간 초기화(새 알람 등록 시 리셋).

### Constraints
- 사일런트 푸시 경로에는 여전히 `requestAuthorization` 호출 금지 (Phase 8 Constraints 유지 — 권한 요청은 명시된 시점 한 곳뿐).
- 로컬 노티는 App에서만 (`UNUserNotificationCenter` import가 Feature·Domain에 유입 금지).

### Acceptance
공통 acceptance + **Release 구성 빌드 1회 추가** + 전 모듈 테스트 스킴 일괄(`Domain`/`AtchaData`/`CoreStorage`/`CoreAuth`/`CoreAlarm`/`CoreLiveActivity`/`DesignSystem`/`SearchFeature`/`HomeFeature`) + `tuist graph`로 의존 규칙 최종 검증(ActivityKit·UNUserNotificationCenter 유출 없음).

### 사람 검수 (블로킹)
① 권한 팝업 순서(AlarmKit → 알림) UX ② LA dismiss 후 변경 주입 → 로컬 노티 수신 ③ 운행 종료 주입 → LA 정리, 3종 시연 후 전체 스코프 마감 확인.

---

## 진행 프로토콜

[마스터 프롬프트의 진행 프로토콜](atcha-v2-master-prompt.md#진행-프로토콜) 1~6을 그대로 상속한다. 추가 규칙:

1. **Phase 10~12는 마스터 Phase 7·8 완료 전에 시작하지 않는다.** Phase 9만 예외적으로 병렬 가능 (Phase 9의 병렬 가드 준수).
2. ["이 문서가 다시 정의하지 않는 것"](#이-문서가-다시-정의하지-않는-것-중복-금지) 표의 코드를 수정하고 싶어지면 멈추고 사용자에게 물을 것.
3. Phase 9는 빌드 인프라 전용 — UI·로직을 선취하지 않는다. 9 → 10 → 11 → 12 순서 고정 (이 문서 내부의 병렬 없음).
4. v2(서버 주도 LA push 승격)는 이 문서 스코프 밖 — 제안하지 말 것.

## 미확정 입력 (사용자 제공 대기)

번호는 마스터 프롬프트의 #1~6에 이어 #7부터.

| # | 항목 | 필요한 Phase | 받기 전 임시 동작 |
|---|---|---|---|
| 7 | **알람 기준 시각의 서버 필드** — refresh 응답에 `departureTime`뿐이라 서버 계산 알람 시각이 없다 (`AlarmInfo` TODO 실측). 서버 필드 추가 요청? 클라 계산 확정? | 11 | 클라 계산: `departureTime − 첫 도보 구간 시간 − 3분 버퍼`, TODO 주석 |
| 8 | 알림 권한 요청 시점 UX 확정 | 12 | 알람 등록 성공 직후 요청 |
| 9 | 대안 제시(심야버스 등) 데이터 소스 | 12 | 실패 문구만 ("막차가 지나갔어요") |
| 10 | `GoogleService-Info.plist` (마스터 #6과 동일 항목) | 11~12 시연 | plist 가드로 FCM 비활성 — 피기백이 폴링 경로에서만 동작, 백그라운드 인지 시연 불가 고지 |
