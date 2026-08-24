# AtchaV2 검색·홈 마찰 팩 구현 프롬프트 — 빈 상태 + 필드 정합 + 진입·이탈 경로 + 오늘/내일 라벨

> **사용법**: 이 문서 전체를 Claude Code에 컨텍스트로 전달하고 `"Phase 17을 진행해"`라고 지시한다.
> 실행 에이전트는 [마스터 프롬프트](atcha-v2-master-prompt.md)의 **진행 프로토콜·공통 규칙·공통 acceptance를 그대로 상속**하며, 한 번에 한 Phase만 수행한다.
> 갭 분석·우선순위 정본은 [Post-12 로드맵](../planning/atcha-v2-post12-roadmap.md)의 "Phase 17 — 검색·홈 마찰 팩" 절. 충돌 시 **CLAUDE.md > 마스터 프롬프트 > [LA 프롬프트](atcha-v2-live-activity-prompt.md) > [세션 수명주기 프롬프트](atcha-v2-session-lifecycle-prompt.md) > [인지 채널 방어선 프롬프트](atcha-v2-channel-defense-prompt.md) > [갱신 신뢰성 프롬프트](atcha-v2-refresh-reliability-prompt.md) > 이 문서** 순.
> **검수는 사람 검수가 아니라 [자동 검수 규약](atcha-v2-auto-verification.md)을 따른다** — 실행 에이전트가 computer use로 직접 수행·증적 보고하고, 실기기 잔여 항목만 사용자에게 이관한다.
> 작성일: 2026-08-23.

---

## Goal (최상위)

**첫 90초의 이탈 요인을 제거한다 — 빈 화면이 말을 하게 하고, 탭한 필드로 들어가게 하고, 나가는 모든 경로가 흔적 없이 닫히게 하고, 심야의 시각이 어느 날인지 말하게 한다.** 권한을 전부 거부한 "조회 전용 사용자"의 최소 동작 보장이기도 하다.

현재 검색 화면은 최근 검색 0건·검색 결과 0건에서 **완전한 백지**고(DSEmptyState는 있는데 이 두 상태엔 안 쓴다), 장소 검색엔 로딩 상태가 없어 타이핑 후 침묵한다. 홈 `arrivalField`는 어떤 상태와도 연결되지 않아 경로 카드 옆에 placeholder("도착지를 검색해 주세요")가 영구 공존하고, 출발지·도착지 어느 필드를 탭해도 같은 화면·같은 슬롯으로 들어간다. 검색 화면의 이탈 경로는 `closeFlow()` 하나만 코디네이터를 정리한다 — 스와이프 백은 (숨긴 내비바 때문에) 아예 비활성이고, 노티 탭 랜딩의 `popToRootViewController`는 `SearchCoordinator`를 누수시킨다(AppCoordinator에 "Phase 17이 일괄 해소" 주석으로 기록된 빚). `LocationError`는 2케이스뿐이라 전역 위치 OFF·restricted가 전부 "권한 거부 + 설정으로 이동"으로 뭉개지고(restricted엔 설정 이동이 무의미하다), 심야 앱인데 "도착 00:29"가 오늘인지 내일인지 아무도 말하지 않는다. `serviceEnded`/`noRoute`의 "다시 검색하기"는 최근 검색 화면 복귀만 하고(재검색 실동작 없음), 기획서가 요구한 최근 검색 스와이프 삭제는 누락돼 있다. 이 문서는 그 일곱 구멍을 막는다. Phase 번호는 갱신 신뢰성(16)에 이어 **17**.

마찰 팩의 완성 상태 (이 문서가 만드는 구조):

```
홈
  출발지/도착지 필드 ── 탭한 필드로 진입 ──────► 검색 (SearchEntryField — Interface 신설)
  arrivalField ◄── 선택 경로의 도착지명 ──────── onRouteSelected가 (LastRoute, Place) 동반
  위치 실패 3분기 ── denied(설정 이동) / 전역 OFF(설정 이동) / restricted(설정 이동 없음)

검색
  최근 검색 0건·결과 0건 ──► DSEmptyState (백지 해소)   키워드 검색 ──► .loadingPlaces 스피너
  serviceEnded·noRoute "다시 검색하기" ──► 도착지 슬롯 초기화 + 포커스 (실동작)
  최근 검색 행 ──► trailing 스와이프 삭제 (기존 X 버튼 유지)

이탈 경로 — didShow 단일 정리 지점 (UINavigationControllerDelegate)
  백 버튼 pop ─┬─► navigationController(_:didShow:) → 검색 VC가 스택에 없으면
  스와이프 백 ─┤    SearchCoordinator.finish() 1회 (스와이프 백은 이번에 활성화)
  popToRoot ───┘    → returnToHome 누수 빚 청산 (AppCoordinator 주석 마감)

시각 표기 — "내일"만 접두, 무라벨 = 오늘
  "내일 00:10 출발" / "도착 내일 00:29 · 환승 1회"  (검색 결과 카드·대안 행·홈 카드 공통)
```

확정된 제품 결정사항 (변경하려면 사용자에게 먼저 물을 것 — [로드맵](../planning/atcha-v2-post12-roadmap.md) 2026-08-23 확정):

| 항목 | 결정 |
|---|---|
| 검색 빈 상태 2종 | `.recent([])` → "최근 검색이 없어요" + "도착지를 검색해 막차 시간을 확인해 보세요" / `.places([])` → "검색 결과가 없어요" + "다른 키워드로 검색해 보세요". 둘 다 **액션 버튼 없음**(타이핑이 곧 회복 경로), 아이콘은 기존 `DSIcon.illustCharacterGray` 재사용. 빈 recent엔 "최근 검색" 헤더도 없다(기존 `rows.isEmpty` 가드 유지) |
| 장소 검색 로딩 | `State`에 `.loadingPlaces` 신설 — **디바운스 통과 후** 요청 직전에 진입(타이핑 중 매 글자 깜빡임 방지). 기존 `activityIndicator` 재사용, `loadingRoutes`와 달리 **키보드를 내리지 않는다**(타이핑 계속이 정상 흐름) |
| 도착지 반환 | `onRouteSelected` 콜백을 `(LastRoute, Place) -> Void`로 확장 — Place는 확정된 도착지(경로 검색의 불변식상 항상 존재). 홈 `State.arrivalText: String?`에 바인딩. **재실행 복원 경로는 placeholder 유지 수용** — 복원엔 도착지 명칭 원천이 없다(스냅샷 확장은 스코프 밖) |
| 필드 구분 진입 | Interface에 `public enum SearchEntryField: Sendable, Equatable { case departure, arrival }` 신설 + `makeSearchCoordinator(navigationController:initialField:onRouteSelected:)`. initialField는 **초기 활성 슬롯만** 결정 — 현재 위치 프리필 정책(성공 시 도착지로 포커스 이동, 사용자가 만진 슬롯 불가침)은 불변 |
| 코디네이터 정리 | `SearchCoordinator`가 `NSObject` + `UINavigationControllerDelegate` 채택, `didShow`에서 검색 VC가 스택에 없으면 정리 — **백 버튼·스와이프 백·popToRoot가 전부 이 한 지점으로 수렴**한다(`closeFlow`는 pop만 남긴다). 이전 delegate 보관·복원. 스와이프 백 제스처는 검색 화면에서 활성화(숨긴 내비바로 현재 죽어 있음 — `interactivePopGestureRecognizer` delegate 조정, 루트에선 시작 금지) |
| LocationError | `restricted`·`servicesDisabled` 케이스 신설(기존 2케이스 유지 — 추가만). 어댑터 매핑은 **순수 함수** `classify(denied:deniedGlobally:restricted:)`로 분리(AtchaV2Tests 대상): restricted → `.restricted` > deniedGlobally → `.servicesDisabled` > denied → `.permissionDenied` 우선순위. 홈 토스트 3분기: denied → 기존 문구+설정 이동 / 전역 OFF → "기기의 위치 서비스가 꺼져 있어요"+설정 이동 / restricted → "이 기기에선 위치를 사용할 수 없어요. 출발지를 검색해 주세요" **설정 이동 없음** |
| 오늘/내일 라벨 | **"내일"만 접두, 무라벨 = 오늘** (라벨 소음 최소화). 적용 표면: 검색 결과 카드·대안 행·홈 경로 카드의 출발/도착 시각. 판정은 순수 함수(캘린더 일자 비교, `Calendar` 주입으로 테스트 고정) — 오늘 nil / 내일 "내일" / 그 외 nil(막차 도메인상 비발생, 방어). "지난 막차" 카드(`asPastTrain`)는 **제외**(과거 시각 라벨은 스코프 밖). ViewData 생성에 `now` 주입 — SearchViewModel에 `now` 주입 신설(기존 VM 관례와 동일) |
| 다시 검색하기 실동작 | `serviceEnded`/`noRoute`의 액션 = **도착지 슬롯 초기화**(arrival 미확정 + arrivalText 비움 + activeField `.arrival`) + 최근 검색 복귀 — 키보드가 도착지로 포커스돼 즉시 재검색 가능. `.failed`(두 슬롯 확정)의 "다시 시도" = 경로 재검색은 현행 유지 |
| 최근 검색 스와이프 삭제 | `trailingSwipeActionsConfigurationForRowAt` — `.recent` 행에만 destructive "삭제" → 기존 `didDeleteRecent(at:)` 경유. **기존 X 버튼(accessory .delete)은 유지**(스와이프는 추가 수단, 기획서 요구 충족) |
| DEV 검수 훅 | `DevDemoFallbacks`에 검수 재료 3건 추가(DEV 한정 — 변경 시뮬레이터와 동일 취급): ① 예약 키워드 "결과없음" → 장소 0건 ② 예약 키워드 "경로없음" → 좌표 (0,0) 데모 장소 1건 + 경로 검색이 end (0,0)이면 빈 목록(→ 정규화 가정에 따라 serviceEnded) ③ 데모 대안 경로 1건(id `dev-demo-route-tomorrow`, **다음 자정+10분 출발**) — 더보기 확장·내일 라벨 검수 재료. 예약 훅은 base 호출 **전에** 판정(결정론 확보). featured(index 0)는 기존 데모 경로 그대로 — 변경 시뮬레이터 기준 시각(`noteKnownSession`) 정합 불변 |

---

## 이 문서가 다시 정의하지 않는 것 (중복 금지)

아래는 기존 Phase 산출물이다. **계약을 바꾸지 않고 명시된 지점만 확장한다.** 이 목록의 계약을 깨고 싶어지면 멈추고 사용자에게 물을 것.

| 산출물 | 소속 | 이 문서에서의 취급 |
|---|---|---|
| `DSEmptyState`·`DSListCell`·`DSTextField`·`DSToast` API | Phase 4 | **DesignSystem 소스 변경 0이 기본** — 기존 API로 전부 성립한다(빈 상태는 configure 재사용, 스와이프는 tableView 레벨). 부족이 발견되면 멈추고 물을 것 |
| 검색 상태 머신 불변식 (`.loadingRoutes`/`.routes`는 두 슬롯 확정 시에만) | Phase 5 | 불변 — `.loadingPlaces`는 키워드 검색 전용 상태로 **추가**만 한다. 디바운스+이전 Task cancel 구조 불변 |
| 현재 위치 프리필 정책 (실패 무음, 사용자가 만진 슬롯 불가침, 늦은 도착 마감) | Phase 5·6 | 불변 — initialField는 초기 활성 슬롯만 정한다. 권한 안내 UX는 홈 담당 유지 |
| Phase 16 산출물 전체 (pull-to-refresh·스탬프·`AlarmSyncRequesting`·홈 스크롤 구조) | Phase 16 | 불변 — 홈 렌더에 arrivalField 바인딩 한 줄이 얹힐 뿐. 배너·카드·스탬프 표출 로직 무변경 |
| `AlarmSyncService` 판정·폴백·만료 분기 / LA·알람·세션 수명주기 | Phase 8~16 | **무변경.** 이 Phase는 알람 경로를 건드리지 않는다 |
| `DefaultSearchLastRoutesUseCase` 정규화(빈 목록 = serviceEnded 가정, 미확정 #3 TODO) | Phase 1 | 불변 — "다시 검색하기"는 표출 이후의 회복 동작만 바꾼다. responseCode 매핑 추가 금지 |
| DEV 데모 폴백·변경 시뮬레이터 성격 (실패 시에만 대체, 실서버 확정 시 일괄 제거) | Phase 7·11·14 | 성격 불변 — 검수 훅 3건을 **같은 파일·같은 제거 단위**로 추가한다. 예약 훅의 사전 판정은 "실패 시에만"의 명시적 예외로 주석에 기록 |
| 서버 계약 전체 | 마스터 공통 규칙 | **서버 변경 0.** Domain 변경은 `LocationError` 케이스 추가뿐 |

## 전제 조건

1. **Phase 16 완료가 전제** (`feat/v2-phase16-refresh-reliability` 기준). 이 문서 내부의 병렬 없음 — Phase 17 단일.
2. 서버 트랙(로드맵 S1~S4)과 **완전 독립** — 미확정 입력을 새로 요구하지 않는다. 검수는 [자동 검수 규약](atcha-v2-auto-verification.md)에 따라 DEV 데모 폴백(+이번 검수 훅)을 재료로 에이전트가 직접 수행한다.
3. **스와이프 제스처(엣지 스와이프 백·셀 스와이프 삭제) 자동화는 실측 제약**(AX 액션 기반 조작만 신뢰)에 걸릴 수 있다 — 불가로 판명되면 자동 검수 절에 명시된 대체 경로(백 버튼 pop = 같은 didShow 정리 경로 / X 버튼 삭제 = 같은 `didDeleteRecent` 경로 + 단위 테스트)로 판정하고 실제 제스처만 실기기 잔여로 이관한다.

---

## Phase 17 — 검색·홈 마찰 팩

### Goal
빈 화면이 다음 행동을 말하고(빈 상태 2종+로딩), 홈 필드가 상태와 정합하고(arrivalField·필드 구분 진입), 검색 화면의 모든 이탈 경로가 코디네이터를 정리하고(didShow 일원화+스와이프 백 활성화), 위치 실패가 사유별로 정직하게 안내되고(LocationError 세분화), 심야의 시각이 날짜를 말하고(내일 라벨), 막힌 검색이 한 탭으로 재개된다(다시 검색하기 실동작+스와이프 삭제).

### Requirements

- **Domain — `LocationError` 세분화 (추가만)**:
  ```swift
  public enum LocationError: Error, Equatable, Sendable {
      case permissionDenied     // 이 앱의 권한 거부 — "설정으로 이동"이 유효
      /// 스크린타임·MDM 제약 — 사용자가 설정으로 못 푼다. "설정으로 이동" 무의미.
      case restricted
      /// 기기 전역 위치 서비스 OFF — 앱 설정이 아니라 시스템 설정의 문제.
      case servicesDisabled
      case unavailable
  }
  ```
- **App — `CoreLocationServiceAdapter` 매핑 분리**: 판정을 순수 함수로 추출하고 어댑터는 이를 경유한다:
  ```swift
  /// CLLocationUpdate의 3개 거부 플래그 → LocationError. nil이면 계속 대기(진행 중).
  /// 우선순위: restricted > servicesDisabled > permissionDenied — 더 좁은 회복 경로가 이긴다.
  static func classify(denied: Bool, deniedGlobally: Bool, restricted: Bool) -> LocationError?
  ```
  `AtchaV2Tests`에 4분기(+전부 false → nil) 테스트.
- **SearchFeatureInterface — 진입 필드 + 도착지 반환 (파괴적 변경 2건, 이 두 건 외 시그니처 불변)**:
  ```swift
  /// 검색 진입 시 활성화할 슬롯 — 홈의 어느 필드를 탭했는지가 그대로 넘어온다(Phase 17).
  public enum SearchEntryField: Sendable, Equatable {
      case departure
      case arrival
  }
  @MainActor
  public protocol SearchCoordinatorBuildable {
      func makeSearchCoordinator(
          navigationController: UINavigationController,
          initialField: SearchEntryField,
          onRouteSelected: @escaping (LastRoute, Place) -> Void   // Place = 확정된 도착지
      ) -> any Coordinator
  }
  ```
  콜사이트는 `HomeDIContainer`·Home Example 스텁뿐 — 전부 따라간다.
- **SearchFeature — 빈 상태·로딩·진입 필드·다시 검색하기·스와이프 삭제·내일 라벨**:
  - `SearchViewModel`: `init`에 `initialField: SearchEntryField = .departure`(→ `fields.activeField` 초깃값 매핑)와 `now: @escaping @Sendable () -> Date = { Date() }` 주입 추가. `State`에 `case loadingPlaces` 추가 — `keywordDidChange`의 검색 Task가 **디바운스 통과 후** `.loadingPlaces`로 전이하고 성공 시 `.places`(0건 포함), 실패 시 기존 `.failed`. `onRouteChosen: ((LastRoute, Place) -> Void)?`로 확장 — `didSelectRoute`가 확정 `arrival`을 동반한다(불변식상 항상 존재, `guard let` 방어). `didTapEmptyAction`의 `serviceEnded`/`noRoute` 분기: `arrival = nil` + `arrivalText` 비움 + `activeField = .arrival` + `showRecent()` — 키보드 포커스는 기존 `renderFields` diff가 처리한다. `.failed` 분기 현행 유지.
  - `RouteViewData`/`RouteResultsViewData`: `now` 파라미터 추가, 출발·도착 시각에 내일 접두 — `"내일 00:10 출발"` / `"도착 내일 00:29 · 환승 1회"`. 내일 판정 순수 함수는 파일 스코프 헬퍼로 두고 **HomeFeature와 중복을 허용**한다(`TransportBadgeMapper` 선례 — 피처 간 공유 모듈 신설 금지):
    ```swift
    /// 내일이면 "내일 " 접두, 오늘·그 외는 빈 문자열 (무라벨 = 오늘. 이틀+ 미래·과거는 막차 도메인상 비발생 — 방어적 무라벨).
    func dayPrefix(for date: Date, now: Date, calendar: Calendar = .current) -> String
    ```
  - `SearchViewController`: `.recent([])`·`.places([])`에 결정사항 문구로 `DSEmptyState` 표출(액션 버튼 없음), `.loadingPlaces`에 `activityIndicator` 표출(키보드 유지·rows 비움). `.recent` 행에 trailing 스와이프 "삭제"(destructive) → `didDeleteRecent(at:)`. 스와이프 백 활성화: `viewDidAppear`에서 `interactivePopGestureRecognizer` delegate를 잡고 `gestureRecognizerShouldBegin`에서 `viewControllers.count > 1`일 때만 허용.
  - `SearchCoordinator`: `NSObject` 상속 + `UINavigationControllerDelegate`. `start()`에서 이전 delegate 보관 후 자신을 설치하고 pushed VC를 weak 보관. `navigationController(_:didShow:)`에서 **검색 VC가 스택에 없으면** 이전 delegate 복원 + `finish()` — 1회 가드(finished 플래그). `closeFlow()`는 pop만 한다(finish는 didShow로 일원화 — 백 버튼·경로 선택·스와이프 백·popToRoot가 전부 같은 지점에서 정리). 테스트: didShow를 직접 호출해 pop 후 정리 1회·재호출 no-op·검색 VC 잔존 시 no-op을 검증.
  - `SearchDIContainer`: `initialField` 전달 + 콜백 시그니처 추종. Example 앱 스텁도 따라간다.
- **HomeFeature — arrivalField 바인딩 + 필드 구분 진입 + 위치 3분기 + 내일 라벨**:
  - `HomeViewModel`: `import SearchFeatureInterface`(의존 그래프상 기존 허용). `searchFieldTapped(_ field: SearchEntryField)`로 확장, `onSearchRequested: ((_ initialField: SearchEntryField, _ onRouteSelected: @escaping (LastRoute, Place) -> Void) -> Void)?`. `routeSelected(_ route: LastRoute, arrival: Place)` — `State.arrivalText: String?`에 `arrival.name` 세팅(다음 선택 시 교체, 세션 정리에도 유지 — 도착지는 세션이 끝나도 사실이다). 재실행 복원 경로는 세팅하지 않는다(결정사항 — placeholder 수용, 주석으로 기록). `DepartureState.needsSearch`의 `deniedPermission` 연관값 제거(미사용 — 사유는 ToastEvent가 나른다). `ToastEvent`에 `locationServicesDisabled`·`locationRestricted` 추가, `loadCurrentLocation`의 catch를 `LocationError` 케이스별 3분기로(restricted·servicesDisabled → `.needsSearch` + 각 토스트, `unavailable`·기타 → 기존 무토스트 `.needsSearch`). `didBecomeActive` 재확인 가드는 불변(사유 불문 `.needsSearch`면 재조회 — restricted에도 무해).
  - `RouteCardViewData`: `init(entity:now:)`로 확장 — 출발·도착 시각 내일 접두(검색과 같은 규칙·중복 헬퍼). `asPastTrain`은 불변. 콜사이트(`routeSelected`·`restoreRouteCardIfNeeded`)는 VM의 `now()`를 넘긴다.
  - `HomeViewController`: `render`가 `arrivalField.setText(state.arrivalText ?? "")` 반영. 필드 행 액션을 필드별로 분리(`searchFieldTapped(.departure)`/`.arrival`). 토스트 3분기 — restricted만 액션 없음.
  - `HomeCoordinator`·`HomeDIContainer`: `initialField`·`(LastRoute, Place)` 배선 통과. Example 앱 스텁 추종.
- **App — 누수 빚 청산 + DEV 검수 훅**:
  - `AppCoordinator.returnToHome`: 누수 주석을 해소 기록으로 교체 — popToRoot가 didShow 정리 경로를 타므로 추가 코드 없음(주석만 갱신).
  - `DevDemoFallbacks`: 결정사항의 검수 훅 3건 — ① `searchPlaces`가 base 호출 전에 키워드 "결과없음"이면 `[]` ② "경로없음"이면 좌표 (0,0) 데모 장소 1건, `searchLastRoutes`가 base 호출 전에 end (0,0)이면 `[]`(빈 목록 정규화 = serviceEnded 표면) ③ 데모 경로 목록에 대안 1건 추가 — id `dev-demo-route-tomorrow`, 출발 = **다음 자정+10분**(`Calendar.startOfDay` 기준 계산, 검수 시각 무관 항상 "내일"), 기존 legs 재사용 가능. `noteKnownSession`은 계속 index 0(기존 데모 경로) 기준 — 변경 시뮬레이터·알람 검수 플로우 불변.
- **테스트 (Swift Testing — 스텁·주입, 실 Date()·실 UserDefaults 금지)**:
  - `SearchFeatureTests`: ① initialField `.arrival` → 초기 `fields.activeField == .arrival` ② 디바운스 통과 후 `.loadingPlaces` → 성공 `.places` / 0건 `.places([])` / 실패 `.failed` ③ `didSelectRoute` → `(route, arrivalPlace)` 전달 ④ `didTapEmptyAction`(serviceEnded·noRoute) → arrivalText 비움 + activeField `.arrival` + `.recent` 복귀, 이후 장소 선택 시 도착지 슬롯에 반영 ⑤ `dayPrefix`·`RouteViewData` 내일 접두(고정 now·고정 캘린더) ⑥ `SearchCoordinator` didShow 정리(1회 가드·잔존 시 no-op·delegate 복원).
  - `HomeFeatureTests`: ① `routeSelected(_:arrival:)` → `arrivalText` 세팅 + 기존 카드·배너 동작 회귀 ② `searchFieldTapped(.arrival)`/`(.departure)` → `onSearchRequested`에 그대로 전달 ③ `LocationError` 3분기 토스트(restricted·servicesDisabled·permissionDenied) + `.needsSearch` 전이 ④ `RouteCardViewData` 내일 접두(고정 now) + `asPastTrain` 무라벨 유지.
  - `AtchaV2Tests`: `classify` 4분기 + 우선순위.

### Constraints
- **Phase 18 선취 금지**: 최근 경로 원탭 칩, 홈에서의 즉시 재검색, `SearchLastRoutesUseCase`의 홈 주입은 이 문서 밖. 재실행 복원의 arrivalText를 스냅샷·최근 검색으로 채우려는 시도 금지(결정사항 — placeholder 수용).
- 미확정 #3(serviceEnded/noRoute의 responseCode 실측) 해소 시도 금지 — 정규화 로직·TODO 불변.
- DesignSystem 소스 변경 0이 기본(기존 컴포넌트 API로 성립). `Tuist/Package.swift`·`Package.resolved`·매니페스트(`Project.swift`/`Workspace.swift`) 무변경 — 신규 타겟 없음, `tuist generate` 불필요.
- 알람·LA·sync·스냅샷 경로 무변경 (`AlarmSyncService`·`RefreshAlarmUseCase`·`AlarmSessionSnapshot` 등). 홈 pull-to-refresh·스탬프 표출 회귀 금지.
- `UIApplication`·CoreLocation 심볼의 Domain·Feature 유입 금지(기존 규약 — `SearchEntryField`·`LocationError`는 순수 타입). Feature 간 공유 모듈 신설 금지 — 내일 라벨 헬퍼는 중복 허용(선례 명시).
- Interface 파괴적 변경은 명시된 2건(initialField·arrival 동반)뿐 — 그 외 공개 시그니처 불변. 레거시 무변경.

### Acceptance
공통 acceptance(Debug+Stage 빌드) + `-scheme Domain test` + `-scheme SearchFeature test` + `-scheme HomeFeature test` + `-scheme AtchaV2 test` + `SearchFeatureExample`·`HomeFeatureExample` Debug 빌드(스텁 시그니처 추종 확인) + `git diff --stat`으로 DesignSystem·매니페스트·`Package.resolved` 무변경 확인.

### 자동 검수 (블로킹 — [자동 검수 규약](atcha-v2-auto-verification.md))
iOS 26 시뮬레이터(Debug/DEV)에서 에이전트가 직접 수행하고 단계별 스크린샷 증적으로 보고. 재료: DEV 데모 폴백 + 이번 검수 훅 3건. 시나리오 ①·②·⑤·⑥은 검색 진입·타이핑·AXPress만으로 성립한다.
① **빈 상태 — 최근 검색 0건**: 앱 데이터 초기화 상태(`simctl uninstall` 후 재설치)로 실행 → 검색 진입 → "최근 검색이 없어요" 빈 상태 스크린샷 (백지 아님의 직접 증명).
② **빈 상태 — 검색 결과 0건 + 로딩**: 도착지 슬롯에 예약 키워드 "결과없음" 입력 → "검색 결과가 없어요" 빈 상태 스크린샷. 로딩 스피너는 순간적이라 스크린샷 타이밍이 플레이키하다 — 포착되면 증적, 못 잡으면 "관찰 불가(순간 상태)"로 기록하고 단위 테스트(②)로 갈음한다.
③ **도착지 탭 진입 + arrivalField 바인딩**: 홈 도착지 필드 탭 → 검색 화면 **도착지 슬롯 활성**(키보드 포커스) 증적 / 홈 복귀 후 출발지 필드 탭 → 출발지 슬롯 활성 증적. 이어서 데모 경로 선택 → 홈 복귀 → **arrivalField에 도착지명 표출**(placeholder 아님) 스크린샷.
④ **스와이프 백 + 코디네이터 정리**: 검색 진입 → 좌측 엣지 스와이프 백 시도(computer use). 제스처 자동화 불가로 판명되면(규약 실측 제약): 판정을 "자동화 불가"로 기록하고 — 백 버튼 pop이 **같은 didShow 정리 경로**이므로 백 버튼 검수 + 단위 테스트 ⑥ 증적으로 갈음, 실제 스와이프 제스처만 실기기 잔여로 이관한다. 어느 경로든 **pop 후 재진입 → 검색 플로우 정상 동작**(검색·선택 재수행 가능) 스크린샷 필수.
⑤ **오늘/내일 라벨**: 데모 검색(아무 키워드) → 결과 화면 "더보기" AXPress → 대안 행에 "내일 HH:mm" 라벨 + featured(오늘)는 무라벨 **대비** 스크린샷 → 대안(내일 경로) 선택 → 홈 카드 "내일 HH:mm 출발" 스크린샷. 알람 등록은 하지 않는다(라벨 검수 전용 경로).
⑥ **다시 검색하기 실동작**: 도착지 슬롯에 "경로없음" 입력 → 데모 장소 선택 → "오늘 막차가 끊겼어요"(빈 목록 정규화) 화면 → "다시 검색하기" AXPress → 최근 검색 복귀 + **도착지 슬롯이 비워지고 활성**(재검색 즉시 가능) 스크린샷.
⑦ **최근 검색 스와이프 삭제**: 최근 검색 행 스와이프 시도 — 불가 시 기존 X 버튼 삭제로 갈음(같은 `didDeleteRecent` 경로) + 실제 스와이프는 실기기 잔여 이관. 삭제 후 목록 갱신(마지막 1건 삭제 시 ①의 빈 상태 표출) 스크린샷.
⑧ **위치 거부 분기 + 회귀**: 재설치 직후 위치 권한 팝업 "허용 안 함" AXPress → "위치 권한이 꺼져 있어요"+설정 이동 토스트 증적(denied 분기). 이후 권한 허용 재설치 상태에서 데모 경로 알람 등록 → **배너+스탬프+arrivalField 동시 표출** 정상(Phase 16 표면 회귀 없음) 스크린샷.
전역 위치 OFF는 설정 앱 AX 조작이 성립할 때만 시도(플레이키하면 "자동화 불가" 기록 후 실기기 잔여) — restricted는 시뮬레이터 재현 불가(스크린타임 제약)로 항상 실기기 잔여, 매핑은 `AtchaV2Tests`가 담보한다.

**실기기 잔여**: 엣지 스와이프 백·셀 스와이프 삭제의 실제 제스처 감각(자동화 불가 판명 시). restricted(스크린타임 제약) 실측. 전역 위치 서비스 OFF 실측(설정 조작 자동화 불가 시). 사일런트 푸시 실수신(기존 항상-잔여 항목 — 이 Phase 무관 승계).

> **검수 결과 기록 (2026-08-24 실측)**: Mac 화면 잠금으로 AX 조작이 전면 불가한 상황에서 [규약의 잠금 시 대체 경로](atcha-v2-auto-verification.md)(XCUITest 하니스)로 ①~⑧ 전 시나리오 자동 검수 완료 — **스와이프 백(엣지 드래그)·셀 스와이프 삭제 제스처 자동화가 XCUITest로 성립**해 ④·⑦의 불가 시 분기가 필요 없었다. 검수 중 발견·수정 1건: 타이핑 중 빈 상태 문구가 키보드에 가림 → 빈 상태·스피너를 `keyboardLayoutGuide` 위 가시 영역 중앙으로 이동. 실기기 잔여로 남은 것은 restricted(스크린타임)·전역 위치 OFF 실측(설정 앱 조작 미시도 — `classify` 매핑은 AtchaV2Tests 담보)과 제스처 실감각뿐.

---

## 진행 프로토콜

[마스터 프롬프트의 진행 프로토콜](atcha-v2-master-prompt.md#진행-프로토콜) 1~6을 그대로 상속한다. 추가 규칙:

1. 이 문서는 **Phase 17 단일** — 내부 병렬 없음. Phase 16 완료 커밋 위에서 진행한다.
2. ["이 문서가 다시 정의하지 않는 것"](#이-문서가-다시-정의하지-않는-것-중복-금지) 표의 계약을 바꾸고 싶어지면 멈추고 사용자에게 물을 것.
3. **Phase 18 산출물을 선취하지 않는다** — [로드맵](../planning/atcha-v2-post12-roadmap.md)의 몫.
4. 검수는 [자동 검수 규약](atcha-v2-auto-verification.md)을 따른다 — "자동 검수 (블로킹)"는 에이전트가 computer use로 수행·증적 보고를 마쳐야 하고, "실기기 잔여"만 사용자에게 이관한다. **acceptance 전부 실행·보고 + 자동 검수 증적 보고 후 정지** — 다음 Phase로 진행하지 않는다.
5. 제스처 자동화 불가가 확정되면 결과를 **이 문서 자동 검수 절에 기록**하고 명시된 대체 경로로 검수를 완료한다.

## 미확정 입력 (참조)

이 문서는 새 미확정 입력을 만들지 않는다. 관련 기존 항목의 취급:

| # | 항목 | 이 문서에서의 취급 |
|---|---|---|
| 3 | "막차 종료"/"경로 없음"의 서버 표현 (responseCode 실측값) | **미해소 유지** — "다시 검색하기"는 표출 이후의 회복 동작만 실동작으로 바꾼다. 빈 목록 = serviceEnded 가정·TODO 그대로. 검수 훅 ②는 이 가정 위에서 serviceEnded 표면을 재료로 쓴다 |
| 11 | 서버의 "등록된 알람 없음" 표현 | 이 문서 밖 — 알람 경로 무변경 |
| 원장 전체 | [Post-12 로드맵](../planning/atcha-v2-post12-roadmap.md)의 "미확정 입력 원장" 절 참조 | |
