# AtchaV2 최근 경로 원탭 칩 구현 프롬프트 — 홈 원탭 재검색 (3탭 → 1탭)

> **사용법**: 이 문서 전체를 Claude Code에 컨텍스트로 전달하고 `"Phase 18을 진행해"`라고 지시한다.
> 실행 에이전트는 [마스터 프롬프트](atcha-v2-master-prompt.md)의 **진행 프로토콜·공통 규칙·공통 acceptance를 그대로 상속**하며, 한 번에 한 Phase만 수행한다.
> 갭 분석·우선순위 정본은 [Post-12 로드맵](../planning/atcha-v2-post12-roadmap.md)의 "Phase 18 — 최근 경로 원탭 칩" 절. 충돌 시 **CLAUDE.md > 마스터 프롬프트 > [LA 프롬프트](atcha-v2-live-activity-prompt.md) > [세션 수명주기 프롬프트](atcha-v2-session-lifecycle-prompt.md) > [인지 채널 방어선 프롬프트](atcha-v2-channel-defense-prompt.md) > [갱신 신뢰성 프롬프트](atcha-v2-refresh-reliability-prompt.md) > [마찰 팩 프롬프트](atcha-v2-friction-pack-prompt.md) > 이 문서** 순.
> **검수는 사람 검수가 아니라 [자동 검수 규약](atcha-v2-auto-verification.md)을 따른다** — 실행 에이전트가 computer use로 직접 수행·증적 보고하고, 실기기 잔여 항목만 사용자에게 이관한다.
> 작성일: 2026-08-24.

---

## Goal (최상위)

**"간편 그 자체"를 반복 사용자에게 체감시킨다 — 어제 검색한 그 경로를 오늘은 한 탭으로.** 3탭(홈 필드 탭 → 최근 검색 행 탭 → 결과 경로 탭)이 1탭(홈 칩 탭)이 된다.

현재 홈은 매 방문이 백지에서 시작한다 — 최근 검색이 로컬에 저장돼 있는데도(Phase 2) 그 데이터가 닿는 표면은 검색 화면의 목록뿐이라, 매일 같은 경로를 확인하는 핵심 사용자(심야 귀가 반복)도 매번 검색 화면을 왕복해야 한다. 이 문서는 홈 검색 필드 아래에 **마지막 도착지 칩 1개**("→ 신림동")를 놓고, 탭 시 **현재 위치 기준 즉시 재검색 → 결과 카드를 홈에 바로 표출**한다(검색 화면 생략). 이것은 **"최근 검색만, 즐겨찾기 없음" 확정 결정과 충돌하지 않는 표면 확장**이다 — 별도 저장·관리 UI가 없고, 데이터 원천은 기존 `RecentSearchRepository` 하나뿐이다. **알람 자동 등록은 하지 않는다** — 칩의 종착은 카드 표출까지고, 등록은 명시적 버튼 탭만. Phase 번호는 마찰 팩(17)에 이어 **18**.

원탭 칩의 완성 상태 (이 문서가 만드는 구조):

```
홈
  출발지/도착지 필드
  [→ 신림동]  ◄── 최근 검색 최신 1건 (RecentSearchesUseCase.fetch()[0])
      │              경로 선택 시 도착지를 save로 승격(중복 최신 갱신 재사용)
      └─ 탭 ──► 현재 위치 조회 ──► SearchLastRoutesUseCase(start: 현재 위치, end: 칩 도착지)
                     │                  │
                     │ 실패             ├─ available → featured(0번) 카드 즉시 표출
                     ▼                  │   (routeSelected 수렴 — 검색 복귀와 같은 상태 의미)
                기존 위치 토스트        ├─ serviceEnded/noRoute/실패 → 토스트 (카드 무변경)
                3분기 재사용            └─ 알람 등록 없음 — "알람 등록하기" 버튼이 다음 탭
```

확정된 제품 결정사항 (변경하려면 사용자에게 먼저 물을 것 — [로드맵](../planning/atcha-v2-post12-roadmap.md) 2026-08-23 확정 + 이 문서 2026-08-24 구체화):

| 항목 | 결정 |
|---|---|
| 칩 데이터 원천 | **`RecentSearchesUseCase.fetch()`의 최신 1건**(기존 레포 정책: 최신순·중복 최신 갱신·10개 제한 — 소비만 하고 정책 무변경). 칩 전용 저장 키·스냅샷 확장·별도 영속화 **금지** — "최근 검색의 표면 확장" 정의를 코드로 지킨다 |
| 도착지 승격 | `routeSelected(_:arrival:)`가 도착지를 `save`로 **승격**(기존 "중복 시 최신 갱신" 재사용 — 새 저장 의미 없음). 출발지를 나중에 확정한 경우에도 칩 = "마지막으로 경로를 확정한 도착지"가 되도록 하는 최소 수단이다. 칩 탭 성공도 같은 경로로 수렴하므로 멱등 재저장이다 |
| 칩 라벨·개수 | `"→ {도착지명}"` **1개만**. N개 목록·삭제 액세서리·관리 UI 금지(그건 즐겨찾기다 — 반대 확정). 최근 검색 0건이면 칩 자체가 없다 |
| 칩 위치 | 도착지 필드 행 아래, 경로 카드 위 — leading 정렬(스택 전폭 늘림 금지) |
| 칩 갱신 시점 | ① `viewDidLoad` ② `viewWillAppear`(검색 화면을 다녀온 뒤의 삭제 반영 — 승격 save 진행 중이면 no-op, 승격 파이프라인이 끝나며 최신을 반영한다) ③ `routeSelected` 직접 세팅(fetch 대기 없이 즉시 정합) |
| 탭 플로우 | 현재 위치 조회(`GetCurrentLocationUseCase` — 역지오코딩 불필요, 좌표만) → `SearchLastRoutesUseCase.execute(start: 현재 위치, end: 칩 도착지)` → `.available`의 **featured(0번, 가장 늦은 차)**를 `routeSelected(_:arrival:)`로 수렴 — 카드·arrivalText·배너 무효화·버튼 계산이 검색 복귀와 완전히 같은 의미다. 대안 경로 표출은 풀 검색 화면의 몫(칩은 featured 원탭 전용) |
| 실패 표면 | **전부 토스트, 카드·필드 무변경**(홈에 카드 외 빈 상태 표면을 새로 만들지 않는다). `LocationError` 3분기는 기존 토스트 재사용(denied/전역 OFF/restricted — Phase 17 문구·액션 그대로), `unavailable`·기타 위치 실패 → "현재 위치를 확인하지 못했어요. 잠시 후 다시 시도해 주세요", `serviceEnded` → "오늘 막차가 끊겼어요", `noRoute` → "대중교통 경로를 찾지 못했어요"(검색 DSEmptyState 제목과 동일 표기 — 화면 간 어휘 통일), 경로 검색 throw → "막차를 찾지 못했어요. 다시 시도해 주세요". 신규 4건 전부 액션 버튼 없음 |
| 재진입 가드 | `State.isChipBusy` — 진행 중 칩 비활성(더블 탭 1회 실행). 알람 busy와는 독립(검색 복귀 경로와 같은 노출 수준 유지 — 추가 가드 금지) |
| 알람 자동 등록 금지 | 칩 탭 경로에서 `RegisterAlarmUseCase` 호출 **0회** — 테스트가 직접 검증한다. 카드 표출 후 "알람 등록하기" 버튼이 명시적 다음 탭이다 |
| DSChip 신설 | `DSButton`은 title이 init 고정이라(홈의 버튼 2개 우회가 그 한계의 기록) 동적 도착지명에 부적합 — **`DSChip`(UIButton 서브클래스, `setText(_:)` 갱신 가능)** 신설. height 32 + `DSTypography.label2` + cornerRadius `DSRadius.lg`(= 높이 절반, pill) + secondary 계열 색 매핑(bg `Fill.elevated`/text `Text.primary`, disabled `Fill.surface`/`Text.disabled`) — DSButton의 configuration·eager 컬러 적용 패턴 준수. 갤러리(ComponentDemos) 데모 1행 추가 |
| DEV 검수 훅 | **신규 0건** — 기존 재료로 전 시나리오가 성립한다: 데모 장소 선택 → 최근 저장(칩 생성), "경로없음" 데모 장소(Phase 17 훅) → 칩 serviceEnded 재현, `simctl location set` → 현재 위치 주입. `DevDemoFallbacks` 무변경 |

---

## 이 문서가 다시 정의하지 않는 것 (중복 금지)

아래는 기존 Phase 산출물이다. **계약을 바꾸지 않고 명시된 지점만 확장한다.** 이 목록의 계약을 깨고 싶어지면 멈추고 사용자에게 물을 것.

| 산출물 | 소속 | 이 문서에서의 취급 |
|---|---|---|
| 검색 화면 전부 (상태 머신·빈 상태·didShow 정리·스와이프·내일 라벨) | Phase 5·17 | **SearchFeature 소스 변경 0.** 칩은 검색 화면을 생략하는 별도 진입로다 |
| `RecentSearchRepositoryImpl` 정책 (최신순·중복 최신 갱신·10개 제한) | Phase 2 | 불변 — 칩은 소비자일 뿐. 승격 저장도 기존 save 의미(중복 갱신)를 그대로 쓴다 |
| `routeSelected(_:arrival:)`의 상태 의미 (카드·arrivalText·배너 무효화·버튼 계산) | Phase 6~17 | 불변 — 칩 성공 경로가 **이 한 지점으로 수렴**한다(칩 전용 상태 전이 신설 금지). 승격 저장 한 줄이 얹힐 뿐 |
| `DefaultSearchLastRoutesUseCase` 정규화 (빈 목록 = serviceEnded 가정, 미확정 #3 TODO) | Phase 1 | 불변 — 칩은 정규화 결과의 소비자다. responseCode 매핑 추가 금지 |
| 위치 실패 3분기 (`LocationError` 세분화 + ToastEvent 3종 + 문구·액션) | Phase 17 | 불변 — 칩 탭의 위치 실패가 **같은 이벤트를 재사용**한다(문구 분기 중복 신설 금지) |
| `AlarmSyncService` 판정·폴백·만료 / LA·알람·세션 수명주기 / 스탬프·pull-to-refresh | Phase 8~16 | **무변경.** 이 Phase는 알람 경로를 건드리지 않는다 — 자동 등록 금지가 그 경계다 |
| Interface 공개 계약 (`HomeCoordinatorBuildable`·`SearchCoordinatorBuildable`·`SearchEntryField`) | Phase 5~17 | **변경 0** — 칩은 홈 내부 표면이라 Interface에 닿지 않는다 |
| DEV 데모 폴백·변경 시뮬레이터·검수 훅 3건 | Phase 7~17 | **무변경** — 결정사항대로 신규 훅 없이 기존 재료를 조합한다 |
| 서버 계약 전체 | 마스터 공통 규칙 | **서버 변경 0. Domain 변경 0** — 필요한 UseCase(`SearchLastRoutesUseCase`·`RecentSearchesUseCase`)는 Phase 1·2 산출물 그대로다 |

## 전제 조건

1. **Phase 17 완료가 전제** (`feat/v2-phase17-friction-pack` 기준). 이 문서 내부의 병렬 없음 — Phase 18 단일. 작업 브랜치는 Phase 17 완료 커밋 위 `feat/v2-phase18-one-tap-chip`(스택 PR 관례 — 커밋 전 브랜치 확인).
2. 서버 트랙(로드맵 S1~S4)과 **완전 독립** — 미확정 입력을 새로 요구하지 않는다. 검수는 [자동 검수 규약](atcha-v2-auto-verification.md)에 따라 DEV 데모 폴백을 재료로 에이전트가 직접 수행한다.
3. 현재 위치 검수 재료는 **`xcrun simctl location booted set <lat>,<lon>`**(헤드리스 좌표 주입)으로 확보한다. Mac 화면 잠금 시에는 규약의 대체 경로(XCUITest 하니스)를 그대로 상속한다 — 칩 탭·타이핑·권한 알럿 전부 그 경로로 성립한다(2026-08-24 실측 승계).

---

## Phase 18 — 최근 경로 원탭 칩

### Goal
반복 사용자의 재검색이 홈에서 끝난다 — 마지막 도착지가 칩으로 홈에 상주하고(최근 검색의 표면 확장), 탭 한 번에 현재 위치 기준 막차가 카드로 표출되며(검색 화면 생략), 알람 등록은 여전히 명시적 버튼 탭만이 수행한다(자동 등록 금지).

### Requirements

- **DesignSystem — `DSChip` 신설**:
  ```swift
  /// 컴팩트 pill 칩 — 동적 텍스트(setText) 지원이 DSButton(title init 고정)과의 차이다.
  public final class DSChip: UIButton {
      public init()
      public func setText(_ text: String)
  }
  ```
  결정사항의 시각 스펙(height 32·label2·`DSRadius.lg` pill·secondary 계열 색·disabled 상태)과 DSButton의 configuration 패턴(eager 컬러 적용 + `configurationUpdateHandler` — 호스트 없는 테스트에서도 초기 구성이 완전해야 한다)을 따른다. `DSChipTests`(기존 DS 테스트 관례 — 초기 구성·setText 반영·disabled 색) + `ComponentDemos` 갤러리 데모 1행.
- **HomeFeature — 칩 상태·탭 플로우·승격 저장**:
  - `HomeViewModel`: `init`에 `searchLastRoutesUseCase: any SearchLastRoutesUseCase`·`recentSearchesUseCase: any RecentSearchesUseCase` 주입 추가. `State`에 `recentRouteChipText: String?`(nil = 칩 숨김)·`isChipBusy: Bool = false` 추가, 원본 `chipPlace: Place?`는 private 보관(표시는 문자열, 검색은 Place — Entity 뷰 노출 금지 관례). Task 3개 신설·보관·deinit cancel: `chipTask`(fetch), `chipSaveTask`(승격 저장 — fetch류가 저장을 cancel하면 안 되므로 분리, 검색 VM `saveTask` 선례), `chipSearchTask`(원탭 재검색).
    - `refreshChip()` (private): `chipSaveTask` 진행 중이면 no-op → `recentSearchesUseCase.fetch()` 최신 1건으로 `chipPlace`·`recentRouteChipText`(`"→ {name}"`) 갱신, 0건이면 nil. `viewDidLoad()`와 신설 `viewWillAppear()`가 호출한다.
    - `routeSelected(_:arrival:)` 확장: `chipPlace = arrival` + 칩 텍스트 직접 세팅(즉시 정합) + `chipSaveTask`로 `save(arrival)` 승격(완료 시 task nil 리셋 — `refreshChip`의 no-op 가드 해제 지점). 기존 카드·arrivalText·배너·버튼 전이는 무변경.
    - `chipTapped()`: `chipPlace` 존재 ∧ `!isChipBusy` 가드 → `isChipBusy = true` → `chipSearchTask`에서 현재 위치 조회 → 재검색 → 결과 분기(결정사항 표). 성공(`.available` 비어 있지 않음)은 `routeSelected(routes[0], arrival: chipPlace)` 수렴, 빈 `available`은 `noRoute` 취급(검색 VM의 방어 선례). 종료 시 `isChipBusy = false`(성공·실패 공통). `[weak self]` + `Task.isCancelled` 가드 관례 준수.
    - `ToastEvent`에 4건 추가: `chipLocationUnavailable`·`chipSearchFailed`·`chipServiceEnded`·`chipNoRoute`. 위치 실패의 denied/전역 OFF/restricted는 **기존 3종 이벤트를 그대로 재발화**한다(분기 로직은 `loadCurrentLocation`의 catch와 같은 매핑 — 문구·액션 중복 신설 금지).
  - `HomeViewController`: `viewWillAppear`에서 `viewModel.viewWillAppear()` 호출 추가. 도착지 필드 행 아래에 칩 행(래퍼 UIView + `DSChip` leading 고정 — 스택 전폭 늘림 방지) 삽입, `render`가 `recentRouteChipText` nil ↔ 행 숨김·`setText` 반영·`isChipBusy` ↔ `isEnabled` 반영. 칩 액션 → `chipTapped()`. 신규 토스트 4건 매핑(전부 액션 없음, 문구는 결정사항 표).
  - `HomeDIContainer`: init에 UseCase 2건 추가(파괴적 변경 — 콜사이트는 `AppDIContainer`·Home Example뿐, 전부 따라간다) + `makeHomeViewController` 주입.
- **App — 조합 루트 공유 배선 (이 Phase의 App 변경은 이것뿐)**:
  - `AppDIContainer.makeHomeDIContainer`: `DefaultSearchLastRoutesUseCase`·`DefaultRecentSearchesUseCase`를 지역 상수로 1회 생성해 **Search·Home 컨테이너에 같은 인스턴스를 공유**한다(같은 저장소를 봐야 검색의 저장·삭제가 칩에 그대로 비친다 — 기존 `recentSearchRepository` 1회 생성과 같은 이유).
- **Example — Home 스텁 추종**: `PreviewRecentSearchesUseCase`(canned 1건 — `makeCannedArrival()` 재사용, 칩 즉시 표출)·`PreviewSearchLastRoutesUseCase`(canned 경로 1건 반환 — 칩 탭 시연 성립) 신설·주입.
- **테스트 (Swift Testing — 스텁·주입, 실 Date()·실 UserDefaults 금지)**:
  - `HomeFeatureTests`: ① 최근 1건 이상 → `viewDidLoad` 후 칩 `"→ {name}"` / 0건 → nil ② `routeSelected` → 칩 즉시 갱신 + 승격 save 호출 기록 검증 ③ `chipTapped` 성공 → 카드(featured)·arrivalText·`alarmButton == .register`·배너 nil + busy 해제 + **`RegisterAlarmUseCase` 호출 0회(자동 등록 금지 직접 검증)** ④ 위치 실패 4분기(denied·전역 OFF·restricted → 기존 토스트 3종 / unavailable → `chipLocationUnavailable`) + 카드 무변경 ⑤ `serviceEnded` → `chipServiceEnded` / `noRoute`·빈 `available` → `chipNoRoute` / throw → `chipSearchFailed`, 전부 카드 무변경 + busy 해제 ⑥ 더블 탭 → 재검색 1회(busy 가드) ⑦ `viewWillAppear` 재조회 — 삭제 반영(칩 nil 전환)·승격 save 진행 중 no-op ⑧ 기존 배너·스탬프·복원 테스트 무회귀.
  - `DesignSystemTests`: `DSChipTests` (위 DS 절).

### Constraints
- **즐겨찾기 선취 금지**: 칩 데이터의 유일한 원천은 `RecentSearchRepository` — 칩 전용 저장 키·별도 영속화·관리 UI(삭제·고정·다중) 금지. `AlarmSessionSnapshot` 확장 금지(재실행 복원 arrivalText placeholder 수용은 Phase 17 결정 그대로 — 칩은 그것과 별개 표면으로 공존한다).
- **알람 자동 등록 금지**: 칩 탭 경로에서 `RegisterAlarmUseCase`·`AlarmScheduler`에 닿는 코드 금지. 밤 시간대 자동 재검색·제안 카드([제품 결정 트랙](../planning/atcha-v2-post12-roadmap.md) v1.1 후보)·"집" 배지 선취 금지 — 칩은 탭이라는 명시적 의사가 있을 때만 검색한다.
- **SearchFeature·Domain·AtchaData·CoreStorage 소스 변경 0.** Interface 공개 계약 변경 0. `DevDemoFallbacks` 변경 0. 매니페스트(`Project.swift`/`Workspace.swift`)·`Tuist/Package.swift`·`Package.resolved` 무변경 — 신규 타겟 없음. 단 신규 소스 파일(`DSChip.swift` 등)은 생성 시점 글롭에 잡히도록 `tuist generate --no-open` 1회 재생성이 필요하다(2026-08-24 실측 — 매니페스트 무변경과 별개다).
- 알람·LA·sync·스냅샷 경로 무변경. 홈 pull-to-refresh·스탬프·배너·복원 회귀 금지 — 칩 성공 경로는 `routeSelected` 수렴이라 이 표면들과 같은 규칙을 자동 상속한다.
- DesignSystem 변경은 `DSChip`(+테스트·갤러리 데모)에 한정 — 기존 컴포넌트 API 파괴적 변경 금지.
- 미확정 #3(serviceEnded/noRoute의 responseCode 실측) 해소 시도 금지 — 정규화 로직·TODO 불변.

### Acceptance
공통 acceptance(Debug+Stage 빌드) + `-scheme DesignSystem test` + `-scheme HomeFeature test` + `-scheme AtchaV2 test`(조합 루트 변경 회귀) + `HomeFeatureExample` Debug 빌드(스텁 시그니처 추종 확인) + `git diff --stat`으로 SearchFeature·Domain·AtchaData·매니페스트·`Package.resolved` 무변경 확인.

### 자동 검수 (블로킹 — [자동 검수 규약](atcha-v2-auto-verification.md))
iOS 26 시뮬레이터(Debug/DEV)에서 에이전트가 직접 수행하고 단계별 스크린샷 증적으로 보고. 재료: DEV 데모 폴백(기존 그대로) + `simctl location set` 좌표 주입 + Phase 17 검수 훅("경로없음" 데모 장소). Mac 잠금 시 XCUITest 하니스 대체 경로 상속.
① **칩 없음 — 초기 상태**: 앱 데이터 초기화(`simctl uninstall` 후 재설치)·위치 허용으로 실행 → 홈에 칩 미표출 스크린샷 (최근 검색 0건 = 칩 없음의 직접 증명).
② **칩 생성**: 검색 진입 → 데모 장소를 도착지로 선택 → 데모 경로 선택 → 홈 복귀 → **칩 "→ {장소명}" + arrivalField 동시 표출** 스크린샷.
③ **칩 영속**: `simctl terminate` → 재실행 → 홈에 칩 유지 스크린샷 (재실행 복원 경로의 arrivalText는 placeholder 유지 — 칩과의 공존이 정상 상태다).
④ **원탭 재검색 (핵심)**: 칩 탭 → **검색 화면 진입 없이** 홈에 경로 카드 즉시 표출 — 탭 직전·직후 스크린샷 쌍으로 화면 전환 없음을 증명. 카드와 함께 "알람 등록하기" 버튼이 노출되되 **배너 없음 = 알람 미등록**(자동 등록 금지의 화면 증거) 확인.
⑤ **칩 serviceEnded**: 검색에서 "경로없음" 데모 장소를 도착지로 선택(최근 1위 갱신) → serviceEnded 화면에서 백 → 홈 칩 "→ 경로없음 (데모)" → 탭 → **"오늘 막차가 끊겼어요" 토스트 + 카드 무변경** 스크린샷.
⑥ **위치 거부 분기**: 재설치 후 위치 권한 "허용 안 함" → 검색 플로우(출발지·도착지 모두 수동)로 최근을 만든 뒤 → 칩 탭 → "위치 권한이 꺼져 있어요"+설정 이동 토스트 스크린샷 (denied 분기 — 카드 미표출). 전역 위치 OFF·restricted는 Phase 17과 동일 취급(설정 조작 성립 시에만 시도, restricted는 항상 실기기 잔여 — 매핑은 기존 테스트 담보).
⑦ **최근 삭제 정합**: 검색 진입 → 최근 검색 전부 삭제 → 백 → **홈 칩 소멸** 스크린샷 (viewWillAppear 재조회의 직접 증명).
⑧ **명시적 등록 + 회귀**: 칩 탭으로 표출된 카드에서 "알람 등록하기" AXPress(권한 알럿 처리 포함) → **배너+스탬프+카드 동시 표출** 정상(Phase 16·17 표면 회귀 없음) 스크린샷.
경로 검색 throw 폴백(`chipSearchFailed`)은 DEV 데모 폴백이 실패를 삼켜 시뮬레이터 재현이 불가하다 — 단위 테스트 ⑤로 갈음하고 그렇게 기록한다.

**실기기 잔여**: 실기기 GPS 기반 칩 재검색 실측(시뮬 좌표 주입은 참고값). restricted(스크린타임 제약) 실측(Phase 17 승계). 사일런트 푸시 실수신(기존 항상-잔여 항목 — 이 Phase 무관 승계).

> **검수 결과 기록 (2026-08-24 실측)**: [규약의 XCUITest 하니스 경로](atcha-v2-auto-verification.md)(Phase 17 하니스 승계)로 ①~⑧ 전 시나리오 자동 검수 **통과**(Run 1: 위치 허용 7건 + Run 2: 위치 거부 1건, 증적 p18-01~p18-10). Run 2는 도착지→출발지 순 확정으로 저장 순서상 최근 1위가 출발지가 되는 상황을 만들어 **승격 저장(칩 = 확정 도착지)을 화면으로 직접 검증**했다. 검수 중 앱 결함 0건 — 초기 2회 실패는 전부 하니스·환경 원인: ① 권한 알럿 자동화의 `label IN` firstMatch가 **"한 번 허용(Allow Once)"을 눌러** 재실행부터 권한이 소멸(→ 위치 재조회가 nil 업데이트 후 즉시 종료 = unavailable), ② `simctl location start`(waypoint)·`simctl location set` 펌프·`XCUIDevice.location` 주입 모두 Allow Once 상태의 재조회 스트림을 구제하지 못함. **While-Using 정식 허용 + 사전 `simctl location set` 정적 좌표**면 재조회 스트림(검색 프리필·칩 탭)까지 픽스가 정상 도달한다 — 규약에 실측 추가. 실기기 잔여는 위 목록 그대로.

---

## 진행 프로토콜

[마스터 프롬프트의 진행 프로토콜](atcha-v2-master-prompt.md#진행-프로토콜) 1~6을 그대로 상속한다. 추가 규칙:

1. 이 문서는 **Phase 18 단일** — 내부 병렬 없음. Phase 17 완료 커밋 위 `feat/v2-phase18-one-tap-chip` 브랜치에서 진행한다(커밋 전 브랜치 확인).
2. ["이 문서가 다시 정의하지 않는 것"](#이-문서가-다시-정의하지-않는-것-중복-금지) 표의 계약을 바꾸고 싶어지면 멈추고 사용자에게 물을 것.
3. **[제품 결정 트랙](../planning/atcha-v2-post12-roadmap.md)의 산출물을 선취하지 않는다** — 밤 시간 자동 재검색·"집" 배지·홈 위치 기반 자동 막차는 별도 논의 후의 몫이다.
4. 검수는 [자동 검수 규약](atcha-v2-auto-verification.md)을 따른다 — "자동 검수 (블로킹)"는 에이전트가 computer use로 수행·증적 보고를 마쳐야 하고, "실기기 잔여"만 사용자에게 이관한다. **acceptance 전부 실행·보고 + 자동 검수 증적 보고 후 정지** — 다음 Phase로 진행하지 않는다.
5. 자동화 불가가 확정된 항목은 결과를 **이 문서 자동 검수 절에 기록**하고 명시된 대체 경로로 검수를 완료한다.

## 미확정 입력 (참조)

이 문서는 새 미확정 입력을 만들지 않는다. 관련 기존 항목의 취급:

| # | 항목 | 이 문서에서의 취급 |
|---|---|---|
| 3 | "막차 종료"/"경로 없음"의 서버 표현 (responseCode 실측값) | **미해소 유지** — 칩은 정규화 결과(`serviceEnded`/`noRoute`)를 토스트로 표면화할 뿐이다. 검수 ⑤는 이 가정(빈 목록 = serviceEnded) 위에서 기존 훅을 재료로 쓴다 |
| 원장 전체 | [Post-12 로드맵](../planning/atcha-v2-post12-roadmap.md)의 "미확정 입력 원장" 절 참조 | |
