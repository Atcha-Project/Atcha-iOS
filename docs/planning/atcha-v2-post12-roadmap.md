# AtchaV2 Post-12 로드맵 — 갭 분석 정본 + Phase 13~18

> **성격**: Phase 12(폴백·하드닝)로 기존 기획 스코프가 마감된 시점의 **전수 갭 분석 정본**과 후속 로드맵.
> 구현 지시는 이 문서가 아니라 각 Phase의 구현 프롬프트가 한다 — Phase 13·14는 [세션 수명주기 프롬프트](../prompts/atcha-v2-session-lifecycle-prompt.md).
> 충돌 시 **CLAUDE.md > [마스터 프롬프트](../prompts/atcha-v2-master-prompt.md) > [LA 프롬프트](../prompts/atcha-v2-live-activity-prompt.md) > 이 문서** 순.
> 작성일: 2026-08-23. 분석 기준: `feat/v2-phase12-fallback-hardening` (Phase 12 완료 커밋, 당시 Phase 10~12는 `env/dev` 미머지).

---

## 현황 요약

Phase 1~12로 "검색 → 알람 등록 → 변경 인지"의 전반부는 완성됐고, **안전망(마지막 값 기준 AlarmKit 발화)은 성립**해 있다. 전수 조사(화면·상태 / 알람·LA 파이프라인 / 기획 문서·Domain·Data)로 확인된 남은 공백은 세 덩어리다:

1. **실서버에서 앱이 동작하지 않는다** — 익명 인증 미구현 + plist 번들 ID 불일치 + FCM 토큰 미전달. DEV 데모 폴백이 이를 가려 "되는 것처럼 보이는" 상태. → [서버 트랙](#서버-트랙-클라-로드맵과-병렬)
2. **알람이 울린 이후와 시간이 경과한 이후의 세계가 비어 있다** — 발화 감지 0, 알림 탭 라우팅 0, 배너 "출발까지 0분" 무한, 강제 종료 후 고아 LA, 다음날 유령 알람. 지나간 막차를 "탈 수 있다"고 계속 표시하는 것은 "놓치지 않게 깨워주는 앱"의 신뢰를 직접 훼손한다. → **Phase 13·14 (클라 단독 해결, 최우선 확정)**
3. **"간편 그 자체"와의 구조적 간극** — 반복 사용자(매일 같은 귀갓길)에게 홈이 매번 백지(3탭 + 화면 전환 2회 + 대기). → Phase 17·18

확정된 방향 (2026-08-23 논의):

| 항목 | 결정 |
|---|---|
| 최우선 트랙 | **세션 수명주기 완결 (Phase 13·14)** — 서버 협의는 병렬 |
| 알람 이후 UX | **조용한 원상복귀** — 새 화면·버튼 없음. 발화 감지 → LA "지금 출발하세요" → 자동 소멸 → 홈 정리 |
| 홈 간편성 | **최근 경로 원탭 칩** (Phase 18). 집 설정 부활·밤 시간 자동 갱신은 제품 결정 트랙에 후보로만 |
| 산출물 | 이 문서 + Phase 13·14 구현 프롬프트 + CLAUDE.md 미완 상태 절 갱신 |

---

## 서버 트랙 (클라 로드맵과 병렬)

블로킹 해소 순. 클라 코드는 전부 준비돼 있고 스펙·자산만 기다린다.

| # | 항목 | 클라 측 잔여 작업 |
|---|---|---|
| **S1** | **익명 인증 발급 엔드포인트 (#2)** — 전 기능의 전제. 현재 `UnconfiguredAnonymousSessionIssuer` 스텁이 항상 throw하고 `bootstrap()`이 non-fatal로 삼켜 **토큰 없이 홈 진입 → 알람 서버 기능 전부 실서버에서 불가** | 구현체 1개 작성 + `AppDIContainer` 주입 교체 + `DevDemoFallbacks` 제거 (제거 조건이 파일에 명시돼 있음) |
| **S2** | **`com.atcha.iOS.v2`용 GoogleService-Info.plist 재발급 (#6·#10)** — 현재 커밋된 plist는 **레거시 번들 ID(`com.atcha.iOS`)**라 존재 가드만 무력화된 채 사일런트 푸시가 성립하지 않는다. **레거시 plist는 제거 대상.** + **FCM 토큰 전달 API (#5)** — 현재 로깅만 | plist 교체, 토큰 전달 호출 1개 (`AppDelegate` TODO 지점) |
| **S3** | **responseCode 실측 (#3)** — `normalizedResult(code:)`가 빈 매핑이라 `.noRoute`가 도달 불가 상태 (빈 목록 = 무조건 `serviceEnded`). 레거시 단서: `URT_001, LRT_001, LRT_003, REQ_004` (의미 미확인). + **"등록된 알람 없음" 표현 (#11, 신규)** — 미정이면 서버에서 알람이 사라져도 홈의 배너·해제 버튼이 정리되지 않는 유령 알람 잔존 | 매핑 테이블 채우기, `refresh()`가 "없음"을 에러가 아닌 상태로 반환하게 수정 + 홈 정리 이벤트 |
| **S4** | 알람 기준 시각 서버 필드 (#7 — Phase 14의 클라 임시안으로 급함 하락), 단일 알람 규약 (#4), Stage 전용 호스트 (#1 잔여), **"다음 운행 안내" 필드 (#12, 신규)** — 기획서가 "막차 종료 시 다음 운행 안내"를 약속했으나 어떤 DTO에도 필드가 없음, 대안(심야버스) 데이터 (#9) | 각 TODO 지점에 반영 |

### 서버에 전달할 질문 리스트

1. 익명 세션 **발급** 엔드포인트 스펙 (경로·요청·응답 — 레거시엔 소셜 로그인뿐, `/auth/reissue`만 실측됨)
2. FCM 토큰을 익명 체계에서 어떻게 등록하나 (엔드포인트·토큰 로테이션 처리)
3. `GET /routes/last-routes`가 "오늘 막차 종료"와 "경로 없음"을 각각 어떤 responseCode로 주나 (실측값)
4. 등록된 알람이 없을 때 `GET /routes/user-routes/refresh`가 무엇을 반환하나 (에러 코드? 빈 성공?)
5. `POST /routes/user-routes`는 기존 알람이 있으면 교체하나, 클라가 삭제 후 등록해야 하나
6. refresh 응답에 "서버 계산 알람 시각" 또는 "첫 도보 구간 시간" 필드를 추가할 수 있나 (없으면 클라 계산 확정 — Phase 14 임시안이 정식화됨)
7. "다음 운행 안내"(내일 첫차 등) 데이터를 줄 수 있나 / 심야버스 대안 경로는?
8. Stage 전용 호스트 계획 (현재 dev 호스트 공유)
9. (확인용) 익명 세션은 기기 단위인가 — 다중 기기 동시 알람 케이스가 실존하나

---

## 미확정 입력 원장 — 현재 상태 (#1~10) + 신규 (#11·#12)

번호는 마스터 프롬프트 #1~6, LA 프롬프트 #7~10에 이어 **#11부터 이 문서가 잇는다.**

| # | 항목 | 상태 (2026-08-23) |
|---|---|---|
| 1 | 실서버 base URL | **부분 해결** — dev/live 실주소 반영(`AppEnvironment.swift`, 레거시 trust-evaluator에서 복원·사용자 승인). Stage는 dev 호스트 공유 — 전용 호스트만 미정 |
| 2 | 익명 인증 발급 엔드포인트 | **미해결 — 최치명 (S1)** |
| 3 | responseCode 실측 | **미해결 (S3)** — `.noRoute` 도달 불가 상태 |
| 4 | 단일 알람 규약 | 미해결 — 클라 refresh→cancel→register 우회 동작 중 |
| 5 | FCM 토큰 전달 | **미해결 (S2)** — 로깅만 |
| 6·10 | GoogleService-Info.plist | **잘못 해결 (S2)** — 레거시 번들 ID plist가 커밋돼 가드 무력화. 재발급·교체 필요 |
| 7 | 알람 기준 시각 서버 필드 | 미해결·타협(균일 −3분, 도보 미반영) → **Phase 14 클라 임시안이 해소** (등록 시점 walk leg 저장). 서버 필드 확정 시 대체 |
| 8 | 알림 권한 요청 시점 | 임시 동작 유지 (알람 등록 성공 직후) — 확정만 남음 |
| 9 | 대안 제시(심야버스) 데이터 | 미해결 — 실패 문구만 |
| **11** | **서버의 "등록된 알람 없음" 표현** | **신규 (S3)** — `HomeViewModel` TODO로만 존재하던 항목을 원장에 승격. 미정 시 유령 알람 |
| **12** | **"다음 운행 안내" 필드** | **신규 (S4)** — 기획서 약속("오늘 막차 종료 → 다음 운행 안내") 대비 DTO 필드 부재. 명시적 스코프 결정 필요 |

---

## 클라 로드맵 — Phase 13~18

Phase 13·14가 확정 최우선. 15~18은 상호 독립성이 높아 재배열 가능하며, 각각 착수 시점에 구현 프롬프트를 이 스타일로 작성한다. 공수: S ≤ 0.5일 / M 1~2일 / L 3일+.

**검수는 사람 검수 대신 [자동 검수 규약](../prompts/atcha-v2-auto-verification.md)을 따른다** — 실행 에이전트가 computer use로 시뮬레이터 검수를 직접 수행·증적 보고하고, 시뮬레이터 재현이 불가한 항목만 "실기기 잔여"로 사용자에게 이관한다. Phase 15 이후의 신규 프롬프트도 검수 절을 이 규약 기준으로 작성한다.

### Phase 13 — 알람 이후: 세션 수명 완결 (L) · [구현 프롬프트](../prompts/atcha-v2-session-lifecycle-prompt.md)

지나간 막차를 "탈 수 있다"고 표시하는 경로를 전부 제거한다.

- AlarmKit **stopIntent**로 알람 "확인" 탭 감지 (LiveActivityIntent — 앱 프로세스 실행, 백그라운드 깨움. **강제 종료 상태 실행 여부만 실기기 잔여** — 그 외 검수는 자동)
- LA phase **`departed`** 신설("지금 출발하세요") + `end(dismissalPolicy: .after(출발+10분))` — 앱이 다시 깨지 않아도 잠금화면에서 자동 소멸
- `AlarmSyncService.expireLocallyIfNeeded(now:)` — 모든 wake 지점에서 클라 자체 만료 판정 (서버가 미래값을 주면 서버 우선)
- 홈 배너 3단계 전이: "출발까지 N분" → "지금 출발하세요" → 정리 + 카드 "지난 막차" 상태 (기존 60초 틱 재사용)
- 위젯 `context.isStale` 분기 렌더 — 갱신 끊긴 LA의 마지막 방어선

해소하는 갭: 배너 "출발까지 0분" 무한 / LA 0:00 잔존 / 발화 후 상태 정리 전무 / 서버 `sessionEnded`에만 의존하는 종료.

### Phase 14 — 재실행 정합성: 스냅샷 + 고아 LA + 도보 시간 (M~L) · [구현 프롬프트](../prompts/atcha-v2-session-lifecycle-prompt.md)

앱 프로세스 수명과 알람 세션 수명을 분리한다.

- **세션 스냅샷 영속화** (`AlarmSessionSnapshotStore` — Domain 포트 + App 어댑터, `KeyValueStore+Codable` 재사용): AlarmInfo + 첫 도보 초 + 노선 표시명·수단 → `AlarmSyncService.lastInfo` 휘발 해소 (재실행 후 첫 sync가 진짜 diff를 산출)
- **고아 LA 재부착**: 부트스트랩 직후 `Activity.activities` 스캔 — 스냅샷과 일치·미만료면 adopt(+dismiss 관찰 재개), 아니면 즉시 end. 같은 경로로 8시간 한도·시작 실패로 죽은 세션도 sync 시 재시작 (dismiss 기록 없을 때만 — push-to-start 금지 정책과 무관한 로컬 재생성)
- **카드 복원**: 미사용 자산 `RouteEndpoint.detail` / `lastRoute(id:)` 재활용 — "무슨 경로인지 모르는 해제 버튼" 해소
- **도보 시간 클라 반영 (미확정 #7 임시안 실현)**: 등록 시 `route.legs` 첫 walk leg `sectionTime`을 스냅샷에 저장, `AlarmTiming` 확장으로 등록/refresh/LA/배너 4곳 동일 기준
- 소소 정합성 일괄: 등록 시 과거 fireDate 사전 가드(+`AlarmError.tooLate`), "당겨짐" 배지 조기 소멸 수정, 최초 LA 긴급도 기준 통일(alarmTime), 분 반올림 `.up` 통일, DI compact 수단 아이콘(버스 고정 해소)

### Phase 15 — 인지 채널 방어선 (M)

Phase 12 폴백이 실전에서 뚫리는 지점을 막는다.

- 로컬 노티 폴백 조건을 `isDismissedByUser` 단일 → **"LA alert 도달 불가"**(dismissed ∨ 활성 activity 없음 ∨ `areActivitiesEnabled` false)로 확대 — LA 꺼둔 유저의 인지 채널 0 해소
- 폴백 노티에 `.timeSensitive` interruptionLevel + entitlement — **집중 모드(심야에 흔함)에서 억제되는 현재 상태 해소**
- `UNUserNotificationCenterDelegate` 도입 — 노티 탭 → 홈 랜딩, 포그라운드 표시 정책 명시
- 알림 권한 거부 시 1회 안내 토스트("막차 변경 알림을 받으려면 설정에서 허용") — 재요청 스팸 금지는 기존 가드 유지
- 최후통첩 경로의 포그라운드 이중 알림(LA alert 소리 + 인앱 토스트 동시) 제거
- 위치 권한 `didBecomeActive` 재확인 — 설정 다녀오면 출발지 재조회 (현재 viewDidLoad 1회뿐)

### Phase 16 — 갱신 신뢰성 (M)

- 홈 pull-to-refresh + `AlarmSyncService.syncNow` 노출 — 수동 갱신 수단 전무 해소
- Stage/Release URLSession 타임아웃 60초 기본 → 10~15초 + 멱등 GET 1회 재시도
- `NetworkError` 오프라인 구분 + 스플래시 실패 문구 분기 (현재 원인 불문 "네트워크 연결을 확인해주세요" 고정)
- 배너·카드에 "HH:mm 확인 기준" 신선도 스탬프 — sync 무음 실패의 조용한 표면화 (실패 토스트는 소음이라 지양)
- **App 타겟 테스트 타겟 신설** — `AlarmSyncService`(Phase 11·12 오케스트레이션의 심장, 현재 무테스트)의 `UIApplication` 직접 참조를 주입으로 바꿔 판정·폴백 분기 회귀 방어

### Phase 17 — 검색·홈 마찰 팩 (M)

첫 90초의 이탈 요인 제거. 권한 전부 거부한 "조회 전용 사용자"의 최소 동작 보장이기도 하다.

- 검색 결과 0건·최근 검색 0건 → `DSEmptyState` 표시 (현재 완전한 빈 화면) + 장소 검색 로딩 상태
- 홈 `arrivalField` 상태 바인딩 (현재 어떤 상태와도 연결되지 않아 경로 카드 옆에 placeholder 영구 공존)
- 홈 필드 구분 진입 — 도착지 탭 시 도착지 슬롯에서 시작 (`SearchCoordinatorBuildable`에 initialField)
- 스와이프 백 시 `SearchCoordinator` 누수 수정 (`UINavigationControllerDelegate`)
- `LocationError` 세분화 (denied/restricted/전역 OFF — restricted엔 "설정으로 이동"이 무의미)
- **오늘/내일 라벨** — 심야 앱에서 "도착 00:29"의 날짜 모호 해소
- `serviceEnded`/`noRoute`의 "다시 검색하기" 실동작 (현재 최근 검색 화면 복귀만), 최근 검색 스와이프 삭제 (기획서 요구 누락분)

### Phase 18 — 최근 경로 원탭 칩 (M)

"간편 그 자체"를 반복 사용자에게 체감시키는 최소 공수의 구조 개선. 3탭 → 1탭.

- 홈 검색 필드 아래 마지막 도착지 칩 1개("→ 신림동") — 탭 시 현재 위치 기준 즉시 재검색 → 결과 카드를 홈에 바로 표출 (검색 화면 생략)
- `RecentSearchRepository` 재사용 + 홈에 `SearchLastRoutesUseCase` 주입
- **"최근 검색만, 즐겨찾기 없음" 확정 결정과 충돌하지 않는다** — 별도 저장·관리 UI가 없는 최근 검색의 표면 확장이다. 알람 자동 등록은 하지 않는다 (알람은 명시적 의사)

---

## 제품 결정 트랙 (별도 논의 후 착수)

| 항목 | 상태 |
|---|---|
| 홈 위치 기반 자동 막차 (도착지 입력 전 막차 0 — 앱 컨셉과 최대 간극) | 최대 스코프 — Phase 18의 사용 데이터 확인 후 별도 기획 |
| 밤 시간대(21시+) 홈 진입 시 최근 경로 자동 재검색 | v1.1 후보 — 칩(18) 데이터로 검증 후. **알람 자동 등록은 반대 확정** (제안 카드까지만) |
| "집" 배지 승격 (레거시 온보딩 "우리집 설정"의 부활) | 보류 — 칩의 최근 1위 고착률이 입증하면 1슬롯만. 일반 즐겨찾기 N개 관리는 반대 유지 |
| 알람에 "경로 보기" secondaryButton | 보류 — 심야 버튼 2개는 인지 부하. 조용한 원상복귀 원칙 우선 |
| "잘 탔어요?" 세션 회고 / 알람 히스토리 | v1 반대 — 응답 데이터를 쓸 곳이 없음 |
| 홈스크린·잠금화면 위젯 | v1.1 후보 — **"세션 밖 진입 런처"로 역할 한정** (세션 중 카운트다운은 LA 담당, 미니 앱화 반대) |
| 택시비 절약 (레거시 대표 기능) | 누적 통계·상시 표시 반대. **놓침/임박 카피 한 줄만 부활 후보** ("지금 놓치면 택시비 약 N원") |
| 공유 ("나 00:12 막차야") | 여유 시 — 술자리 맥락 바이럴, 공수 하 |
| 온보딩·위치 권한 프라이머 | 후보 — 현재 사전 설명 없이 시스템 팝업 즉발, 거부 시 회복 경로 없음(15가 일부 해소) |
| AlarmKit 거부 시 "조회 전용(LA·배너만)" 모드 | 보류 — 안전망 없는 카운트다운은 앱 사명과 충돌 소지 |
| 접근성 (Dynamic Type·VoiceOver 전무, 긴급도 색상만 구분, 토스트 announce 없음) / i18n (전 문구 하드코딩) | 착수 시점 결정 필요 — 현재 0% |
| **반대 판정 기록** | 지도 SDK 부활 (텍스트 "OO정류장 · 도보 N분"으로 대체 — 같은 효용, 1/20 공수), Apple Watch 전용 앱 (LA alert가 이미 워치 미러링), 게이미피케이션, 탑승 체크인·아침 리포트, Siri/App Intents 선행 투자 (위젯의 부산물로만) |

---

## 신뢰 UX 원칙 (전 Phase 공통)

**"거짓 숫자를 보여주느니 낡았다고 말한다."** 이 앱의 리텐션은 기능이 아니라 신뢰에서 나온다 (알람 실패 1회 = 삭제).

1. **자기모순 제거가 전제**: 카드·배너·LA의 시각은 단일 소스 — 카드만 낡은 값으로 남는 현재 상태(막차 변경 시 한 화면에 두 시각)가 신뢰의 최대 적
2. **자연 만료**: "출발까지 0분" 무한 표시는 "이 앱 숫자는 믿으면 안 된다"의 학습 장치 — Phase 13이 제거
3. **신선도 스탬프**: 갱신 실패를 토스트로 소음화하지 않고 "HH:mm 확인 기준"으로 조용히 정직하게
4. **안전망 약속의 문장화**: 오프라인·서버 다운 시 "지금은 연결이 안 돼요. 알람은 마지막 확인(23:40) 기준으로 유지돼요" — 시스템이 뒤에서 지키는 약속을 사용자에게 말한다
5. **변경의 흔적**: 방향 비대칭·행동 중심 문구·10분 배지는 기존 정책 유지. 취소선 상시 표시 금지

## 수용 리스크 (명시적 결정)

- 알람 확인도, 앱 재진입도 없는 최악 케이스에서 LA가 시스템 수명 한도까지 잔존할 수 있다 — `staleDate` + `isStale` 렌더로 "낡음"이 표시되므로 거짓 정보는 아님 (Phase 13 이후)
- 저전력 모드의 사일런트 푸시 스로틀 — 기존 수용 리스크(알람은 로컬)와 동일 구조. stopIntent가 유일하게 이 영향 밖의 깨움 지점
- 시간대 변경 여행자의 표시 시각 혼란 — 계산은 KST 절대시각이라 안전, 실사용자(서울 심야) 기준 사소함으로 강등
- 등록 후 사용자가 크게 이동한 경우의 도보 시간 어긋남 — v1 수용, "위치 기반 재평가"는 제품 결정 트랙의 논거로만

---

## 부록 — 갭 근거 목록 (분석 시점 검증 완료)

파일 참조는 심볼 기준 (라인 번호는 부패하므로 생략). 전부 소스에서 직접 확인된 사실.

**알람·LA 파이프라인**
- 발화 감지 수단 전무: `AlarmKitEngine`은 schedule/cancel만, `stopIntent`·`UNUserNotificationCenterDelegate`·딥링크·`widgetURL` 0건. 예약 로컬 알림 0건 (즉시 발송 `post()`뿐)
- `HomeViewModel.minutesUntil`의 `max(0,…)` 클램프 + 종료 조건 없는 배너 틱 → "출발까지 0분" 무한. 카운트다운은 알람 시각(출발−3분) 기준이라 실제 출발 3분 전부터 0분
- `LastTrainLiveActivityAdapter.activity` 인메모리 전용 — 재실행 시 update/end 전부 no-op guard (고아 LA). `AlarmSyncService.lastInfo`도 인메모리 (diff 휘발)
- 폴백 분기 조건이 `isDismissedByUser` 단일 — LA 비활성·시작 실패는 미커버. `LocalNotificationAdapter`는 interruptionLevel 미설정, time-sensitive entitlement 없음, 권한 거부 무안내
- `RegisterAlarmUseCase`에 과거 fireDate 가드 없음 (서버 등록 성공 후 로컬 스케줄 실패 → 서버/로컬 불일치. DEV 데모 경로가 이 문제로 출발 시각 3분→8분 조정됨(`18b60f7`) — 근본 가드는 Phase 14)
- 최후통첩 경로가 applicationState 미검사 → 포그라운드 이중 알림 / unchanged·delayed 갱신이 `changeBadgeExpiry: nil` 덮어씀 → 배지 조기 소멸 / 최초 LA 긴급도만 출발 시각 기준(이후는 알람 시각) / 반올림 `.up` vs `.rounded()` 불일치 / DI compact 아이콘 버스 고정 (수단 필드 부재)
- App 타겟 테스트 타겟 부재 — `AlarmSyncService` 전 분기 무테스트. LA 8시간 한도는 주석 인정만

**화면·상태**
- `HomeViewController.render()`는 departureField만 갱신 — arrivalField 미바인딩. `alarmSynced()`는 배너·버튼만 — 카드 시각 영구 미갱신
- `searchFieldTapped()` 필드 구분 없음 (주석으로 의도 명시된 v1 단순화)
- 검색: 결과 0건·최근 0건 빈 화면, 장소 검색 로딩 없음, `.idle` dead state, "다시 검색하기" 미동작, `RouteResultsViewData`가 `entities[0]` 강제 인덱싱 (호출부 가드에만 의존)
- 위치: 권한 회복 경로 없음(viewDidLoad 1회), `LocationError` 2케이스로 denied/restricted/전역 OFF 뭉개짐, reduced accuracy 미처리, 역지오코딩 실패는 무토스트
- 스플래시: 원인 불문 고정 문구, Stage/Release 타임아웃 60초 기본. 스와이프 백 Coordinator 누수. 오늘/내일 라벨 없음. 온보딩·프라이머 0건. 접근성·i18n 0건. `RouteCardViewData`/`RouteViewData`/`TransportBadgeMapper` 중복 구현

**기획·Data**
- `LastRouteSearchResult.noRoute` 도달 불가 (`normalizedResult` 빈 매핑). "다음 운행 안내" 필드 부재 (#12). `RouteEndpoint.detail` 구현만 되고 미사용 (→ Phase 14가 재활용). `AlarmError` 케이스 1개 — 실패 전부 단일 토스트
- 네트워크 회복 정책 전무 (재시도·백오프·도달성 감지·오프라인 전용 에러 없음 — 기획서에도 없던 영역)
- 문서-코드 불일치: CLAUDE.md 미완 상태 절 3건 낡음 (이 로드맵과 함께 갱신), README는 여전히 레거시 1.x 설명
