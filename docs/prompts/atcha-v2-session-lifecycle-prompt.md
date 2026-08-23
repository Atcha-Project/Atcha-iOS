# AtchaV2 세션 수명주기 구현 프롬프트 — 알람 이후 + 재실행 정합성

> **사용법**: 이 문서 전체를 Claude Code에 컨텍스트로 전달하고 `"Phase N을 진행해"`라고 지시한다.
> 실행 에이전트는 [마스터 프롬프트](atcha-v2-master-prompt.md)의 **진행 프로토콜·공통 규칙·공통 acceptance를 그대로 상속**하며, 한 번에 한 Phase만 수행한다.
> 갭 분석·우선순위 정본은 [Post-12 로드맵](../planning/atcha-v2-post12-roadmap.md). 충돌 시 **CLAUDE.md > 마스터 프롬프트 > [LA 프롬프트](atcha-v2-live-activity-prompt.md) > 이 문서** 순.
> **검수는 사람 검수가 아니라 [자동 검수 규약](atcha-v2-auto-verification.md)을 따른다** — 실행 에이전트가 computer use로 직접 수행·증적 보고하고, 실기기 잔여 항목만 사용자에게 이관한다.
> 작성일: 2026-08-23.

---

## Goal (최상위)

**사명의 후반부를 완성한다: 알람이 울린 이후에도, 앱이 죽었다 살아난 이후에도, 앱은 거짓말하지 않는다.**

Phase 12까지의 인지 계층은 "알람이 울리기 전"의 세계다. 울린 이후는 비어 있다 — 발화를 감지하지 못하고, 막차 시각이 지나도 배너는 "출발까지 0분"을 무한 표시하며, 강제 종료 후 재실행하면 잠금화면의 LA는 갱신도 종료도 불가능한 고아가 되고, 다음날 홈에는 "무슨 경로인지 모르는 해제 버튼"만 남는다. 이 문서는 그 후반부를 닫는다. Phase 번호는 LA 프롬프트의 9~12에 이어 **13~14**.

세션의 전체 수명 (이 문서가 완성하는 상태 기계):

```
등록 ──► active ("출발까지 N분")
           │ 알람 발화(출발−버퍼) + "확인" 탭         ← stopIntent가 감지 (Phase 13)
           ▼
        departed ("지금 출발하세요")                  ← 신설 phase (Phase 13)
           │ 출발 시각 + 10분
           ▼
        자동 소멸 (LA 예약 dismissal + 홈 정리)        ← 앱이 깨지 않아도 (Phase 13)

  [어느 시점이든] 서버 sessionEnded ──► serviceEnded 종료 (기존)
  [어느 시점이든] 못 타는 앞당김     ──► missed 고정 (기존)
  [wake 시점마다] 출발+유예 경과     ──► 클라 자체 만료 = 로컬 sessionEnded (Phase 13)
  [재실행 시]    스냅샷 복원 + LA 재부착 + 카드 복원   (Phase 14)
```

확정된 제품 결정사항 (변경하려면 사용자에게 먼저 물을 것 — 2026-08-23 논의 확정):

| 항목 | 결정 |
|---|---|
| 알람 이후 UX | **조용한 원상복귀.** 새 화면·새 버튼 없음 — 기존 서피스(LA·배너·카드)의 상태 전이로만. 알람 "확인"은 앱을 열지 않는 것이 기본값 |
| 발화 감지 | AlarmKit **stopIntent** (LiveActivityIntent — 앱 프로세스에서 실행, 필요 시 백그라운드 깨움). secondaryButton("경로 보기")은 붙이지 않는다 — 심야 버튼 2개는 인지 부하 (제품 결정 트랙에 기록됨) |
| 만료 판정 | **이중 구조**: 깨어 있을 때는 홈 배너 틱이, 깨어날 때는 `AlarmSyncService` 진입점이 판정. 서버 refresh가 미래 시각을 주면 **서버 우선**(만료 취소) |
| 만료 유예 | 출발 시각 + 60초 (wake 시점 판정) / LA 예약 소멸은 출발 + 10분 (`.after`) — 잠금화면에 "지금 출발" 상태가 잠시 남는 것이 취지 |
| 세션 영속화 | 스냅샷(AlarmInfo + 첫 도보 초 + 노선 표시명·수단)을 Domain 포트 + App 어댑터로. 알람 세션의 정본은 여전히 서버 — 스냅샷은 재실행 브리지 |
| 도보 시간 | **클라 임시안 확정 (미확정 #7 해소)**: 알람 기준 시각 = `departureTime − 첫 도보 구간 시간 − 3분 버퍼`. 도보 초는 등록 시점 경로에서 취득해 스냅샷에 저장. 서버 필드가 생기면 대체 |
| 고아 LA | 재실행 시 `Activity.activities` 재부착. dismiss 기록이 없는 죽은 세션(8시간 한도·시작 실패 포함)은 sync 시점 **로컬 재시작** — push-to-start 금지 정책과 무관 (그 정책은 유저가 지운 LA의 재생성 금지) |

---

## 이 문서가 다시 정의하지 않는 것 (중복 금지)

아래는 기존 Phase 산출물이다. **계약을 바꾸지 않고 덧붙이거나, 명시된 지점만 확장한다.** 이 목록의 계약을 깨고 싶어지면 멈추고 사용자에게 물을 것.

| 산출물 | 소속 | 이 문서에서의 취급 |
|---|---|---|
| `AlarmSyncService` 3경로 일원화 + 판정 훅 | Phase 8·11 | 진입점에 만료 판정을 **선행 삽입**, `lastInfo`에 초기 로드를 추가 — 판정·채널 분기 로직 자체는 불변 |
| `EvaluateAlarmChangeUseCase` / `AlarmChangeVerdict` | Phase 11 | 그대로 사용. 케이스 추가 금지 (만료는 verdict가 아니라 로컬 sessionEnded 처리) |
| `LastTrainActivityPort` (Domain 문서 고정 계약) | Phase 10 | **시그니처 불변.** `departed`는 `LastTrainSessionPhase` 케이스 추가일 뿐 포트는 그대로 |
| dismiss 감지·폴백, 방향 비대칭, 배지 10분 | Phase 10~12 | 그대로 사용. 폴백 조건 확대는 Phase 15 몫 — 선취 금지 |
| `AlarmKitScheduling` / `AlarmKitEngine` | Phase 7 | stopIntent 주입 지점만 확장 (아래 명세) |
| 서버 계약 전체 | 마스터 공통 규칙 | **서버 변경 0.** 이 문서의 전 작업은 클라 단독 — 새 엔드포인트·payload 제안 금지 |

## 전제 조건

1. **Phase 12 완료가 전제** (`feat/v2-phase12-fallback-hardening` 기준). 13 → 14 순서 고정 — 14의 스냅샷·재부착이 13의 `departed`·만료 개념에 의존한다.
2. 서버 트랙(로드맵 S1~S4)과 **완전 독립** — 미확정 입력을 새로 요구하지 않는다. 실서버 미인증 상태이므로 검수는 [자동 검수 규약](atcha-v2-auto-verification.md)에 따라 DEV 데모 폴백·변경 시뮬레이터를 재료로 에이전트가 직접 수행한다.
3. AlarmKit `stopIntent`의 정확한 이니셜라이저 형태(iOS 26 SDK)는 구현 시점에 **SDK에서 실검증**한다 — 이 문서의 요구는 행동 명세("stop 버튼 탭 시 LiveActivityIntent 실행")이며, 편의 이니셜라이저 `.alarm(schedule:attributes:)`를 full configuration으로 교체하는 방향만 고정한다.

---

## Phase 13 — 알람 이후: 세션 수명 완결

### Goal
알람 발화("확인" 탭)를 감지하고, 시간 경과를 클라가 스스로 판정하며, 세션이 자연 만료되게 한다. 지나간 막차를 "탈 수 있다"고 표시하는 경로를 전부 제거한다.

### Requirements
- **`departed` phase 신설 (wire 계약 확장)**: Domain `LastTrainSessionPhase`와 CoreLiveActivity `LastTrainSessionStatus`에 `departed` 추가 (rawValue 동일 규약 유지 — 앱·익스텐션 동일 바이너리 배포라 wire 안전. 기존 방어값 정책상 미지 rawValue는 `.active`로 떨어지므로 추가도 안전). 위젯: `departed`는 카운트다운 대신 상태 문구 **"지금 출발하세요"** + 출발 시각, glance 색은 imminent와 동일 척도.
- **stopIntent 연결 (CoreAlarm 확장)**: `AlarmKitEngine.schedule`을 full `AlarmConfiguration`으로 교체하고 stop 버튼에 인텐트를 싣는다. 인텐트 **타입**은 App의 `Projects/App/Sources/Intents/`에 둔다 (`LiveActivityIntent` 채택, `perform()`에서 조합 루트의 세션 수명 서비스 호출). CoreAlarm은 인텐트 **인스턴스를 주입받는 전달 수단**만 가진다 — AlarmKit·AppIntents는 시스템 프레임워크라 무의존 원칙 위배가 아니지만, App 타입이 CoreAlarm으로 새어 들어가면 안 된다 (주입 방향은 App → CoreAlarm 한 방향).
- **`alarmAcknowledged()` (App 세션 수명 로직)**: 인텐트 실행 시 ① 스냅샷에 확인 기록(Phase 14에서 영속화 — 13에서는 인메모리) ② LA를 `departed` 상태로 갱신 ③ `end(dismissalPolicy: .after(departureTime + 10분))` 예약 — **앱이 다시 깨지 않아도 잠금화면에서 자동 소멸**된다. end 이후 남은 시간 창(최대 3분+10분)의 재변경 인지는 알람 재스케줄(기존 경로)이 담당 — LA 재생성은 하지 않는다.
- **`AlarmSyncService.expireLocallyIfNeeded(now:)`**: `sync()` 파이프라인 **진입 시** 선행 판정 — 보유 세션의 `departureTime + 60초 < now`면 refresh 결과와 무관하게 **로컬 sessionEnded 처리**(알람 레코드 정리 → LA `end(final: .serviceEnded)` → changes 스트림 yield → 홈 정리는 기존 `sessionEnded` 소비 경로 재사용). 단 refresh가 **성공해 미래 출발 시각을 반환하면 서버 우선** — 만료를 취소하고 정상 갱신 경로로. 만료 처리 여부를 기록해 이후 refresh가 같은 과거 세션으로 배너를 되살리지 못하게 한다 (`alarmSynced`의 미래 시각 가드가 1차 방어, 기록이 2차).
- **홈 배너 3단계 전이** (`HomeViewModel` — 기존 60초 틱 재사용, 신규 인프라 없음):
  1. `now < alarmTime`: "출발까지 N분" (기존)
  2. `alarmTime ≤ now < departureTime + 유예`: **"지금 출발하세요"** (imminent 고정) — "출발까지 0분" 문구 제거
  3. 유예 경과: 배너 제거 + 카드를 **"지난 막차" 상태**(비활성 톤 + "HH:mm 출발이었어요")로 전환 + 알람 버튼 hidden. 틱 루프 종료.
  `makeBanner`류 순수 함수로 구현해 경계 테스트 (자정 경계 포함 — 기존 테스트 패턴 재사용).
- **위젯 `context.isStale` 분기**: 갱신이 끊긴 채 `staleDate`(=출발 시각)가 지난 LA는 카운트다운 대신 **"시간이 지났어요 — 앱에서 확인하세요"** 렌더. 앱 깨움 없이 동작하는 마지막 방어선 (강제 종료·고아 케이스의 UI 완충 — 근본 해소는 Phase 14).

### Constraints
- 알람 재스케줄·안전망 경로에 회귀 금지 — stopIntent 추가로 알람 등록이 실패하게 되면 안 된다 (인텐트 주입 실패 시 인텐트 없이 스케줄되는 fallback 유지).
- AppIntents·ActivityKit 심볼의 Domain·Feature 유출 금지 (`tuist graph` + import 검사 — 기존 규약).
- 만료 판정·배너 전이는 순수 함수로 분리해 시각 주입 테스트 (실 `Date()` 의존 금지 — 기존 `now` 주입 패턴 재사용).
- `AlarmChangeVerdict`에 케이스를 추가하지 않는다 — 만료는 기존 `sessionEnded` 소비 경로를 로컬에서 트리거하는 방식.

### Acceptance
공통 acceptance + `-scheme Domain test` + `-scheme HomeFeature test` + `-scheme CoreLiveActivity test` + `-scheme CoreAlarm test`.

### 자동 검수 (블로킹 — [자동 검수 규약](atcha-v2-auto-verification.md))
iOS 26 시뮬레이터에서 에이전트가 직접 수행하고 단계별 스크린샷 증적으로 보고:
① 알람 등록 → 발화 대기 → **"확인" AXPress → 잠금(Device ▸ Lock) 스크린샷으로 LA "지금 출발하세요" 전환 확인 → 출발+10분 자동 소멸 확인** (대기가 과도하면 데모 출발 시각·소멸 유예를 DEV 한정 단축 — 규약의 `DevDemoFallbacks` 관례)
② `simctl terminate`로 종료한 상태에서 발화 → "확인" → 재실행 후 확인 기록(스냅샷·로그)으로 인텐트 실행 여부 판정 — **시뮬레이터 결과는 참고값** (최종 판정은 실기기 잔여)
③ 확인도 앱 재진입도 없이 방치 → `staleDate` 경과 후 잠금화면 isStale 렌더 스크린샷
④ DEV 플로팅 "변경" 버튼으로 만료 직전 "미래로 늦춰짐" 주입 → 서버 우선(만료 취소) — 배너·LA 갱신 스크린샷.

**실기기 잔여**: 강제 종료 상태의 stopIntent 실행 여부 **최종 판정** — 실행 안 되면(시스템 제약 판명) wake 시점 리컨실(`expireLocallyIfNeeded`)만으로 커버됨을 확정하고 **판명 결과를 이 문서에 기록** (확정 전까지는 리컨실이 커버한다는 보수적 가정으로 진행). AlarmKit 발화의 무음·집중 모드 관통.

---

## Phase 14 — 재실행 정합성: 스냅샷 + 고아 LA 재부착 + 도보 시간

### Goal
앱 프로세스 수명과 알람 세션 수명을 분리한다 — 강제 종료·재실행이 정보를 잃지 않고, 잠금화면의 고아 LA가 사라지고, 알람 시각에 도보 시간이 반영된다.

### Requirements
- **세션 스냅샷 (Domain 포트 + App 어댑터 — 기존 포트+어댑터 패턴)**:
  ```swift
  public struct AlarmSessionSnapshot: Sendable, Equatable, Codable {
      public let info: AlarmInfo            // AlarmInfo에 Codable 채택 추가
      public let firstWalkSeconds: Int?     // 등록 시점 경로의 첫 도보 구간 (없으면 nil)
      public let routeDisplayName: String   // LA·카드 복원용 표시명
      public let acknowledged: Bool         // stopIntent 확인 기록 (Phase 13 연동)
      public let expired: Bool              // 로컬 만료 기록 (Phase 13 연동)
  }
  public protocol AlarmSessionSnapshotStore: Sendable {
      func load() async -> AlarmSessionSnapshot?
      func save(_ snapshot: AlarmSessionSnapshot) async
      func clear() async
  }
  ```
  App 어댑터는 `KeyValueStore+Codable` 재사용 (UserDefaults 백엔드). 필드 추가에 대비해 디코딩 실패는 nil로 무해화 (최근 검색 저장소의 자가치유 패턴 재사용). 기록 시점: 등록 성공·sync 성공 시 save, 취소·sessionEnded·만료 확정 시 clear.
- **diff 휘발 해소**: `AlarmSyncService.lastInfo`의 초기값을 스냅샷에서 로드 — 재실행 후 첫 sync가 `previous == nil → unchanged`로 끝나지 않고 **종료 중 발생한 변경을 실제로 판정**한다.
- **고아 LA 재부착**: 부트스트랩 직후(어댑터 초기화 시점) `Activity<LastTrainActivityAttributes>.activities` 스캔 —
  - 스냅샷과 `routeId` 일치 + 미만료 → **adopt**: 어댑터가 보관하고 `activityStateUpdates` 관찰 재개 (이후 update/end가 정상 동작)
  - 불일치·만료·스냅샷 없음 → `end(nil, dismissalPolicy: .immediate)` 정리
- **죽은 세션 재시작**: sync 성공 시 "스냅샷은 살아 있는데(미만료) 활성 activity가 없고 dismiss 기록도 없으면" LA를 로컬 재시작 — 8시간 한도로 시스템이 내린 세션·시작 실패 세션 커버. dismiss 기록이 있으면 재시작 금지 (유저 의도 존중 — 기존 정책 그대로).
- **카드 복원**: Domain에 `GetLastRouteDetailUseCase` 신설 — 기존 미사용 자산 `LastRouteRepository.lastRoute(id:)` / `RouteEndpoint.detail` 재활용. 홈은 `alarmSynced` 수신 시 `routeCard == nil`이면 상세를 재조회해 카드 복원 (실패 시 현행 폴백 — 카드 없이 해제 버튼, 단 이제 만료 정리가 있어 유령이 오래가지 않는다). "알람 있는데 무슨 경로인지 모름" 상태 해소.
- **도보 시간 반영 (미확정 #7 임시안 실현)**: `AlarmTiming.alarmFireDate(departureTime:firstWalkSeconds:)` 확장 — 기준 시각 = `departureTime − firstWalkSeconds − 180초`. 등록 시 `route.legs`의 첫 `.walk` leg `sectionTime`을 스냅샷에 저장하고, **등록/refresh 재스케줄/LA alarmTime/홈 배너 4곳이 같은 값을 쓴다** (이중 시각 금지 — 기존 원칙). 도보 데이터가 없으면 기존 −180초로 폴백. LA 3행의 공석("정류장 도보 N분")도 이 값으로 채운다.
- **소소 정합성 일괄** (개별 이슈로 격상하지 않고 이 Phase에 포함):
  - `RegisterAlarmUseCase`에 과거 fireDate **사전 가드** + `AlarmError.tooLate` 케이스 추가 — 서버 등록 성공 후 로컬 스케줄이 실패하는 서버/로컬 불일치 차단. 홈 토스트 "이미 출발 시간이 지난 경로예요". DEV 데모 경로 출발 시각은 이미 now+8분으로 조정됨(`18b60f7`) — 도보 시간 반영 후에도 가드에 걸리지 않는지 확인
  - `unchanged`/`delayed` 조용한 갱신이 `changeBadgeExpiry: nil`로 덮어써 **"당겨짐" 배지가 10분을 못 채우고 소멸**하는 문제 — 직전 만료 시각을 보존
  - 최초 LA start의 긴급도만 출발 시각 기준(이후 갱신은 알람 시각 기준)인 불일치 — **알람 시각 기준으로 통일**
  - 변경 분 표기 반올림 불일치(LA `.up` vs 홈 `.rounded()`) — `.up`으로 통일
  - DI compact 아이콘 버스 고정 — `LastTrainActivityAttributes`에 수단 필드 추가(고정 정보라 Attributes가 맞는 자리, 동일 배포라 wire 안전)해 지하철/버스 아이콘 분기

### Constraints
- 스냅샷은 **재실행 브리지이지 정본이 아니다** — 서버 refresh 결과와 충돌하면 항상 서버 우선. 스냅샷만으로 알람을 새로 만들지 않는다.
- `AlarmRepository`·서버 계약 불변. `LastTrainActivityPort` 시그니처 불변 (재부착은 어댑터 내부 동작).
- Domain 테스트는 스텁 스토어로 — 실 UserDefaults 금지 (기존 규약).
- 도보 시간 확장 시 기존 `AlarmTiming` 테스트·`RefreshAlarmUseCase`의 기대 발화 시각 계산이 전부 새 시그니처를 타는지 확인 — 한 곳이라도 구 시그니처가 남으면 이중 시각 재발.

### Acceptance
공통 acceptance + `-scheme Domain test`(스냅샷·도보 반영·tooLate 가드) + `-scheme HomeFeature test`(카드 복원·배너 기준) + `-scheme CoreLiveActivity test`(Attributes 수단 필드) + `-scheme CoreAlarm test`.

### 자동 검수 (블로킹 — [자동 검수 규약](atcha-v2-auto-verification.md))
iOS 26 시뮬레이터에서 에이전트가 직접 수행하고 단계별 스크린샷 증적으로 보고:
① 알람 등록 → **`simctl terminate` → `simctl launch`** → 카드·배너·LA가 일관 복원되고, 변경 주입 시 LA가 실제 갱신되는지 (고아 아님 확인)
② **재실행 직후 DEV 플로팅 버튼으로 변경 주입** → 이전 스냅샷 대비 diff가 판정되는지 (재실행 후 첫 sync가 unchanged로 뭉개지지 않는지)
③ 도보 구간이 있는 경로로 등록 → 알람 발화 시각·배너·LA가 전부 "출발 − 도보 − 3분" 기준으로 일치하는지 (데모 경로에 도보 구간이 없으면 `DevDemoFallbacks`에 walk leg 추가)
④ DEV dismiss 토글 on → 재실행 → LA가 재시작되지 **않는지** (dismiss 존중 유지 — 잠금화면 스와이프 자동화가 불안정하므로 규약대로 토글 사용).

**실기기 잔여**: 없음 — Phase 14의 검수는 전부 시뮬레이터에서 재현 가능하다.

---

## 진행 프로토콜

[마스터 프롬프트의 진행 프로토콜](atcha-v2-master-prompt.md#진행-프로토콜) 1~6을 그대로 상속한다. 추가 규칙:

1. **13 → 14 순서 고정** (14가 13의 `departed`·만료 개념에 의존). 이 문서 내부의 병렬 없음.
2. ["이 문서가 다시 정의하지 않는 것"](#이-문서가-다시-정의하지-않는-것-중복-금지) 표의 계약을 바꾸고 싶어지면 멈추고 사용자에게 물을 것.
3. Phase 15 이후 산출물(폴백 조건 확대, time-sensitive, 노티 탭 라우팅, pull-to-refresh 등)을 **선취하지 않는다** — [로드맵](../planning/atcha-v2-post12-roadmap.md)의 몫.
4. 검수는 [자동 검수 규약](atcha-v2-auto-verification.md)을 따른다 — "자동 검수 (블로킹)"는 에이전트가 computer use로 수행·증적 보고를 마쳐야 다음 진행, "실기기 잔여"만 사용자에게 이관한다.
5. stopIntent의 강제 종료 시 실행 여부가 실기기 잔여 검수에서 판명되면 결과를 **이 문서 Phase 13 절에 기록**하고, 불가 시 "wake 시점 리컨실만으로 커버"를 확정 사실로 남긴다. 확정 전까지는 보수적 가정(리컨실이 커버)으로 진행한다.

## 미확정 입력 (참조)

이 문서는 새 미확정 입력을 만들지 않는다. 관련 기존 항목의 취급:

| # | 항목 | 이 문서에서의 취급 |
|---|---|---|
| 7 | 알람 기준 시각 서버 필드 | **Phase 14 클라 임시안으로 해소** — 서버 필드 확정 시 스냅샷의 도보 초를 서버 값으로 대체 |
| 11 | 서버 "등록된 알람 없음" 표현 | 이 문서 밖 (S3) — 단 Phase 13의 로컬 만료가 유령 알람의 체감을 크게 줄인다 |
| 원장 전체 | [Post-12 로드맵](../planning/atcha-v2-post12-roadmap.md)의 "미확정 입력 원장" 절 참조 | |
