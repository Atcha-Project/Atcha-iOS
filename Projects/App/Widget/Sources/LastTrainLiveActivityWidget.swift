import ActivityKit
import CoreLiveActivity
import DesignSystem
import SwiftUI
import WidgetKit

// MARK: - Widget

/// 막차 세션 Live Activity — 잠금화면 + 다이나믹 아일랜드 (Phase 10).
///
/// 렌더링 한계 (LA는 예약(스케줄) 업데이트가 불가능하다):
/// - 카운트다운은 `Text(timerInterval:)` 시스템 타이머 뷰로 렌더 고정을
///   우회한다. 그래서 표기는 목업의 "22분" 같은 정적 문자열이 아니라
///   시스템 타이머 형식(예: 21:34)이다 — 정적 "N분"은 다음 갱신까지
///   얼어붙기 때문에 의도적으로 쓰지 않는다.
/// - 긴급도 색(여유/주의/임박)과 "⚠ 당겨짐" 배지 노출 여부는 마지막
///   콘텐츠 갱신 시점의 스냅샷이다. 여유→주의 같은 색 전환은 앱 깨움
///   (BG refresh·푸시·재실행) 시점의 재평가로 근사되며, 그 사이에는
///   이전 단계의 색·배지가 그대로 남는다.
struct LastTrainLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LastTrainActivityAttributes.self) { context in
            LastTrainLockScreenView(
                routeName: context.attributes.routeName,
                state: context.state
            )
            // 시스템 변형(항상 켜진 화면·밝기 감소·알림 센터 스택)에서도
            // 무난하도록 배경/시스템 액션 색을 DS 토큰으로 고정.
            .activityBackgroundTint(Color(ds: DSColor.Background.base))
            .activitySystemActionForegroundColor(Color(ds: DSColor.Text.primary))
        } dynamicIsland: { context in
            let state = context.state
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: DSSpacing.xs) {
                        Image(systemName: "bus.fill")
                            .font(.subheadline)
                            .foregroundStyle(state.glanceColor)
                        Text(context.attributes.routeName)
                            .font(.headline)
                            .foregroundStyle(Color(ds: DSColor.Text.primary))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(LastTrainTimeFormat.hhmm(state.departureTime)) 출발")
                        .font(.subheadline)
                        .foregroundStyle(Color(ds: DSColor.Text.secondary))
                        .lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    // 잠금화면 2행의 축약판. 도보 안내 축약도 이 영역 몫이지만
                    // ContentState에 도보 필드가 없어 생략 — 아래
                    // LastTrainLockScreenView.departureRow 주석 참고.
                    switch state.status {
                    case .active:
                        HStack(alignment: .firstTextBaseline, spacing: DSSpacing.sm) {
                            Text("출발까지")
                                .font(.subheadline)
                                .foregroundStyle(Color(ds: DSColor.Text.secondary))
                            HStack(spacing: DSSpacing.xs) {
                                Image(systemName: "timer")
                                    .font(.body.weight(.semibold))
                                Text(timerInterval: state.countdownRange, countsDown: true)
                                    .font(.title2.weight(.bold))
                                    .monospacedDigit()
                                    .multilineTextAlignment(.leading)
                            }
                            .foregroundStyle(state.urgencyColor)
                        }
                    case .missed, .serviceEnded:
                        Text(state.finalStatusMessage ?? "")
                            .font(.headline)
                            .foregroundStyle(state.glanceColor)
                    }
                }
            } compactLeading: {
                // 노선 수단(버스/지하철) 구분 필드가 계약에 없어 버스 아이콘 고정.
                Image(systemName: "bus.fill")
                    .foregroundStyle(state.glanceColor)
            } compactTrailing: {
                switch state.status {
                case .active:
                    Text(timerInterval: state.countdownRange, countsDown: true)
                        .font(.caption2.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(state.urgencyColor)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        // Text(timerInterval:)는 가용 폭을 전부 차지하려 하므로
                        // 컴팩트 영역에서는 폭을 제한한다.
                        .frame(maxWidth: 56)
                case .missed:
                    Text("놓침")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(state.glanceColor)
                case .serviceEnded:
                    Text("종료")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(state.glanceColor)
                }
            } minimal: {
                Image(systemName: "bus.fill")
                    .foregroundStyle(state.glanceColor)
            }
            .keylineTint(Color(ds: DSColor.Accent.default))
        }
    }
}

// MARK: - Lock screen

/// 잠금화면 뷰 — UX 정본 목업:
/// ```
/// ┌────────────────────────────┐
/// │ 🚌 5518 막차      [⚠ 당겨짐] │
/// │ 출발까지  ⏱ 22분             │  ← 여유도에 따라 색 변경
/// │ 23:25 출발 · 정류장 도보 8분   │
/// └────────────────────────────┘
/// ```
/// glance는 0.5초 — 숫자보다 색·상태가 먼저 읽히도록 카운트다운
/// 숫자·아이콘에 긴급도 색을 상시 적용한다.
private struct LastTrainLockScreenView: View {
    let routeName: String
    let state: LastTrainActivityAttributes.ContentState

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            headerRow
            mainRow
            departureRow
        }
        .padding(DSSpacing.md)
    }

    /// 1행: 노선명 + "⚠ 당겨짐" 배지 슬롯.
    private var headerRow: some View {
        HStack(spacing: DSSpacing.xs) {
            Image(systemName: "bus.fill")
                .font(.subheadline)
                .foregroundStyle(Color(ds: DSColor.Icon.default))
            Text("\(routeName) 막차")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(ds: DSColor.Text.primary))
                .lineLimit(1)
            Spacer(minLength: DSSpacing.sm)
            if state.showsChangeBadge {
                ChangeBadge()
            }
        }
    }

    /// 2행: glance 핵심. active면 카운트다운(긴급도 색),
    /// final state면 카운트다운을 숨기고 상태 문구만 표시.
    @ViewBuilder
    private var mainRow: some View {
        switch state.status {
        case .active:
            HStack(alignment: .firstTextBaseline, spacing: DSSpacing.sm) {
                Text("출발까지")
                    .font(.body)
                    .foregroundStyle(Color(ds: DSColor.Text.secondary))
                HStack(spacing: DSSpacing.xs) {
                    Image(systemName: "timer")
                        .font(.title3.weight(.semibold))
                    // 알람 발화 시각(alarmTime = 출발 기준시각 − 버퍼) 기준 —
                    // 정책: "출발까지 N분"은 버퍼 포함 알람 시각 기준으로 통일.
                    Text(timerInterval: state.countdownRange, countsDown: true)
                        .font(.title.weight(.bold))
                        .monospacedDigit()
                        .multilineTextAlignment(.leading)
                }
                .foregroundStyle(state.urgencyColor)
            }
        case .missed, .serviceEnded:
            Text(state.finalStatusMessage ?? "")
                .font(.title3.weight(.bold))
                .foregroundStyle(state.glanceColor)
        }
    }

    /// 3행: 출발 시각. 목업의 "정류장 도보 8분" 자리는 비워둔다 —
    /// ContentState에 도보 필드가 없고 Phase 9 wire 계약은 고정이라
    /// attributes/state 확장 금지. Phase 11 미확정 #7(도보 소요 데이터)
    /// 해소 시 "HH:mm 출발 · 정류장 도보 N분" 형태로 재검토.
    private var departureRow: some View {
        Text("\(LastTrainTimeFormat.hhmm(state.departureTime)) 출발")
            .font(.footnote)
            .foregroundStyle(Color(ds: DSColor.Text.secondary))
            .lineLimit(1)
    }
}

/// "⚠ 당겨짐" 배지 — 변경 직후 10분 노출 정책의 표시 슬롯.
/// 취소선 등 변경 흔적의 상시 표시는 하지 않는다(정책).
private struct ChangeBadge: View {
    var body: some View {
        Text("⚠ 당겨짐")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Color(ds: DSColor.Text.primary))
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xxs)
            .background(Color(ds: DSColor.State.danger), in: Capsule())
            .lineLimit(1)
    }
}

// MARK: - ContentState presentation helpers

private extension LastTrainActivityAttributes.ContentState {
    /// 긴급도 3단계 → DesignSystem 토큰 (하드코딩 금지 — DSColor 브리지만 사용).
    /// relaxed=Accent.default(lime) / caution=State.danger(red400) /
    /// imminent=State.urgent(red600).
    var urgencyColor: Color {
        switch urgency {
        case .relaxed: Color(ds: DSColor.Accent.default)
        case .caution: Color(ds: DSColor.State.danger)
        case .imminent: Color(ds: DSColor.State.urgent)
        }
    }

    /// glance용 대표 색: active면 긴급도 색, missed는 긴급 색(놓침 경고),
    /// serviceEnded는 보조 색(더 이상 행동 불가 — 시각적 소음 억제).
    var glanceColor: Color {
        switch status {
        case .active: urgencyColor
        case .missed: Color(ds: DSColor.State.urgent)
        case .serviceEnded: Color(ds: DSColor.Text.secondary)
        }
    }

    /// 카운트다운 범위. alarmTime이 이미 지난 스냅샷을 받아도
    /// lowerBound > upperBound 크래시 없이 0:00으로 렌더되도록 클램프.
    var countdownRange: ClosedRange<Date> {
        min(Date.now, alarmTime)...alarmTime
    }

    /// "⚠ 당겨짐" 배지 노출 여부 — 렌더(스냅샷 아카이브) 시점 기준 판정.
    /// LA 렌더 고정 특성상 만료 시각(changeBadgeExpiry) 경과 후 자동 소멸은
    /// 다음 콘텐츠 갱신 때까지 지연될 수 있다 — 10분 노출 정책은 갱신 시점
    /// 재평가로 근사된다.
    var showsChangeBadge: Bool {
        guard let changeBadgeExpiry else { return false }
        return changeBadgeExpiry > .now
    }

    /// final state 문구. active면 nil (카운트다운 표시).
    var finalStatusMessage: String? {
        switch status {
        case .active: nil
        case .missed: "막차가 지나갔어요"
        case .serviceEnded: "오늘 운행이 끝났어요"
        }
    }
}

// MARK: - Formatting

/// "HH:mm" 출발 시각 포맷. departureTime은 틱하지 않는 값이라
/// 스냅샷 시점 포맷 고정으로 충분하다 (타이머 뷰 불필요).
private enum LastTrainTimeFormat {
    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    static func hhmm(_ date: Date) -> String {
        formatter.string(from: date)
    }
}
