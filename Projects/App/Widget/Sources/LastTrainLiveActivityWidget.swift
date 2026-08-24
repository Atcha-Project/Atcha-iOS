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
                attributes: context.attributes,
                state: context.state,
                isStale: context.isStale
            )
            // 시스템 변형(항상 켜진 화면·밝기 감소·알림 센터 스택)에서도
            // 무난하도록 배경/시스템 액션 색을 DS 토큰으로 고정.
            .activityBackgroundTint(Color(ds: DSColor.Background.base))
            .activitySystemActionForegroundColor(Color(ds: DSColor.Text.primary))
        } dynamicIsland: { context in
            let state = context.state
            let isStale = context.isStale
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: DSSpacing.xs) {
                        Image(systemName: context.attributes.transportSymbolName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(state.glanceColor)
                        Text(context.attributes.routeName)
                            .font(.pretendard(.semiBold, size: 15))
                            .foregroundStyle(Color(ds: DSColor.Text.primary))
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("\(LastTrainTimeFormat.hhmm(state.departureTime)) 출발")
                        .font(.pretendard(.regular, size: 13))
                        .foregroundStyle(Color(ds: DSColor.Text.secondary))
                        .lineLimit(1)
                }
                // expanded .center는 의도적 미사용 — 센서 하우징 좌우 클램프 탓에
                // 와이드 타이머가 잘리거나 축소되고, 전폭을 쓸 수 있는 영역은
                // bottom뿐이다. leading/trailing이 채워진 구성에선 center가
                // 세로 밴드만 더해 160pt 확장 캡을 압박한다.
                DynamicIslandExpandedRegion(.bottom) {
                    // 잠금화면 히어로 슬롯의 축약판. 도보 안내 축약도 이 영역 몫이지만
                    // ContentState에 도보 필드가 없어 생략 — 아래
                    // LastTrainLockScreenView.departureRow 주석 참고.
                    switch state.status {
                    case .active where isStale:
                        // 갱신이 끊긴 채 staleDate(=출발 시각)가 지났다 — 얼어붙은
                        // 카운트다운 대신 최신성 경고 (Phase 13, 앱 깨움 없는 마지막 방어선).
                        Text(LastTrainStaleCopy.message)
                            .font(.pretendard(.semiBold, size: 15))
                            .foregroundStyle(Color(ds: DSColor.Text.secondary))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    case .active:
                        VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                            Text("출발까지")
                                .font(.pretendard(.medium, size: 12))
                                .foregroundStyle(Color(ds: DSColor.Text.secondary))
                            Text(timerInterval: state.countdownRange, countsDown: true)
                                .font(.pretendard(.bold, size: 28))
                                .monospacedDigit()
                                .foregroundStyle(state.urgencyColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.6)
                                .multilineTextAlignment(.leading)
                        }
                    case .departed, .missed, .serviceEnded:
                        Text(state.finalStatusMessage ?? "")
                            .font(.pretendard(.semiBold, size: 17))
                            .foregroundStyle(state.glanceColor)
                    }
                }
            } compactLeading: {
                // 수단 필드(Phase 14) 기준 지하철/버스 아이콘 분기 — 구버전 LA(필드 없음)는 버스 폴백.
                Image(systemName: context.attributes.transportSymbolName)
                    .foregroundStyle(state.glanceColor)
            } compactTrailing: {
                switch state.status {
                case .active where isStale:
                    Text("지남")
                        .font(.pretendard(.semiBold, size: 12))
                        .foregroundStyle(Color(ds: DSColor.Text.secondary))
                case .active:
                    Text(timerInterval: state.countdownRange, countsDown: true)
                        .font(.pretendard(.semiBold, size: 12))
                        .monospacedDigit()
                        .foregroundStyle(state.urgencyColor)
                        .multilineTextAlignment(.trailing)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        // Text(timerInterval:)는 가용 폭을 전부 차지하려 하므로
                        // 컴팩트 영역에서는 폭을 제한한다.
                        .frame(maxWidth: 56)
                case .departed:
                    Text("출발")
                        .font(.pretendard(.semiBold, size: 12))
                        .foregroundStyle(state.glanceColor)
                case .missed:
                    Text("놓침")
                        .font(.pretendard(.semiBold, size: 12))
                        .foregroundStyle(state.glanceColor)
                case .serviceEnded:
                    Text("종료")
                        .font(.pretendard(.semiBold, size: 12))
                        .foregroundStyle(state.glanceColor)
                }
            } minimal: {
                Image(systemName: context.attributes.transportSymbolName)
                    .foregroundStyle(state.glanceColor)
            }
            .keylineTint(Color(ds: DSColor.Accent.default))
        }
    }
}

// MARK: - Lock screen

/// 잠금화면 뷰 — 타이머 히어로 목업(UX 정본):
/// ```
/// ┌────────────────────────────┐
/// │ 🚌 5518 막차      [⚠ 당겨짐] │
/// │ 출발까지                     │
/// │ 21:34                      │  ← 히어로 카운트다운, 여유도에 따라 색 변경
/// │ 23:25 출발 · 정류장 도보 8분   │
/// └────────────────────────────┘
/// ```
/// glance는 0.5초 — 숫자보다 색·상태가 먼저 읽히도록 카운트다운 숫자에
/// 긴급도 색을 상시 적용한다. 타이머 아이콘은 히어로 스케일에서 숫자와
/// 경합해 제거 — 아이콘 앵커는 헤더의 수단 심벌이 담당한다.
private struct LastTrainLockScreenView: View {
    let attributes: LastTrainActivityAttributes
    let state: LastTrainActivityAttributes.ContentState
    /// staleDate(=출발 시각)가 지나도록 갱신이 없었다 — 강제 종료·고아 케이스의 UI 완충
    /// (Phase 13). 근본 해소는 Phase 14 재부착 — 이 분기는 최후 방어선으로 유지.
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: DSSpacing.sm) {
            headerRow
            heroSlot
            departureRow
        }
        .padding(DSSpacing.md)
    }

    /// 1행: 노선명 + "⚠ 당겨짐" 배지 슬롯.
    private var headerRow: some View {
        HStack(spacing: DSSpacing.xs) {
            Image(systemName: attributes.transportSymbolName)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(ds: DSColor.Icon.default))
            Text("\(attributes.routeName) 막차")
                .font(.pretendard(.semiBold, size: 14))
                .foregroundStyle(Color(ds: DSColor.Text.primary))
                .lineLimit(1)
            Spacer(minLength: DSSpacing.sm)
            if state.showsChangeBadge {
                ChangeBadge()
            }
        }
    }

    /// 2행(히어로 슬롯): active면 오버라인 + 대형 카운트다운(긴급도 색), stale이면
    /// 최신성 경고, final state면 상태 문구가 히어로 자리를 차지한다.
    @ViewBuilder
    private var heroSlot: some View {
        switch state.status {
        case .active where isStale:
            // 갱신이 끊긴 채 staleDate(=출발 시각) 경과 — 얼어붙은 카운트다운을
            // 신선한 정보처럼 보여주지 않는다 (Phase 13 마지막 방어선).
            heroMessage(
                LastTrainStaleCopy.message,
                font: .pretendard(.bold, size: 20),
                color: Color(ds: DSColor.Text.secondary),
                lineLimit: 2
            )
        case .active:
            VStack(alignment: .leading, spacing: DSSpacing.xxs) {
                Text("출발까지")
                    .font(.pretendard(.medium, size: 12))
                    .foregroundStyle(Color(ds: DSColor.Text.secondary))
                // 알람 발화 시각(alarmTime = 출발 기준시각 − 버퍼) 기준 —
                // 정책: "출발까지 N분"은 버퍼 포함 알람 시각 기준으로 통일.
                // h:mm:ss 최악 8글리프도 38pt에서 폭 여유가 있지만
                // lineLimit+minScale을 벨트로 유지한다.
                Text(timerInterval: state.countdownRange, countsDown: true)
                    .font(.pretendard(.bold, size: 38))
                    .monospacedDigit()
                    .foregroundStyle(state.urgencyColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .multilineTextAlignment(.leading)
            }
        case .departed, .missed, .serviceEnded:
            heroMessage(
                state.finalStatusMessage ?? "",
                font: .pretendard(.bold, size: 22),
                color: state.glanceColor,
                lineLimit: 1
            )
        }
    }

    /// stale·final 공용 — 히어로 자리를 차지하는 상태 문구.
    private func heroMessage(
        _ text: String, font: Font, color: Color, lineLimit: Int
    ) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(color)
            .lineLimit(lineLimit)
    }

    /// 3행: 출발 시각 + 정류장 도보 소요 (Phase 14 — 미확정 #7 클라 임시안으로 목업 공석 해소).
    /// 도보 데이터가 없는 세션(구버전 LA·도보 없는 경로)은 출발 시각만 표시한다.
    private var departureRow: some View {
        Text(departureRowText)
            .font(.pretendard(.regular, size: 13))
            .foregroundStyle(Color(ds: DSColor.Text.secondary))
            .lineLimit(1)
    }

    private var departureRowText: String {
        let departureText = "\(LastTrainTimeFormat.hhmm(state.departureTime)) 출발"
        guard let walkSeconds = attributes.firstWalkSeconds, walkSeconds > 0 else {
            return departureText
        }
        // 올림 표기 — 변경 분 표기와 같은 방향(.up), "0분 도보"는 존재하지 않는다.
        let walkMinutes = max(1, Int((Double(walkSeconds) / 60).rounded(.up)))
        return "\(departureText) · 정류장 도보 \(walkMinutes)분"
    }
}

// MARK: - Attributes presentation helpers

private extension LastTrainActivityAttributes {
    /// 수단 → SF Symbol. 필드가 없는 구버전 LA는 버스 폴백(기존 표시 유지).
    var transportSymbolName: String {
        switch transportKind {
        case .subway: "tram.fill"
        case .bus, .other, nil: "bus.fill"
        }
    }
}

/// "⚠ 당겨짐" 배지 — 변경 직후 10분 노출 정책의 표시 슬롯.
/// 취소선 등 변경 흔적의 상시 표시는 하지 않는다(정책).
/// 스타일은 홈 배너 caution 티어(danger 글자 + dangerContainer 채움)와 같은
/// 은은한 채움 — 강한 긴급색은 히어로 숫자가 담당한다.
private struct ChangeBadge: View {
    var body: some View {
        Text("⚠ 당겨짐")
            .font(.pretendard(.semiBold, size: 12))
            .foregroundStyle(Color(ds: DSColor.State.danger))
            .padding(.horizontal, DSSpacing.sm)
            .padding(.vertical, DSSpacing.xxs)
            .background(Color(ds: DSColor.State.dangerContainer), in: Capsule())
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

    /// glance용 대표 색: active면 긴급도 색, departed는 imminent와 동일 척도(정책 —
    /// "지금 출발"은 가장 긴박한 행동 신호), missed는 긴급 색(놓침 경고),
    /// serviceEnded는 보조 색(더 이상 행동 불가 — 시각적 소음 억제).
    var glanceColor: Color {
        switch status {
        case .active: urgencyColor
        case .departed, .missed: Color(ds: DSColor.State.urgent)
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
        case .departed: "지금 출발하세요"
        case .missed: "막차가 지나갔어요"
        case .serviceEnded: "오늘 운행이 끝났어요"
        }
    }
}

/// isStale 최신성 경고 문구 — 잠금화면·DI가 같은 카피를 쓴다.
private enum LastTrainStaleCopy {
    static let message = "시간이 지났어요 — 앱에서 확인하세요"
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

// MARK: - Previews (렌더 검증 픽스처 — 계약·정책과 무관한 표시 확인용)

private extension LastTrainActivityAttributes {
    static let previewSubway = LastTrainActivityAttributes(
        routeId: "preview.subway",
        routeName: "9호선 급행",
        transportKind: .subway,
        firstWalkSeconds: 300
    )

    static let previewBusNoWalk = LastTrainActivityAttributes(
        routeId: "preview.bus",
        routeName: "5518",
        transportKind: .bus,
        firstWalkSeconds: nil
    )
}

private extension LastTrainActivityAttributes.ContentState {
    /// alarm이 N초 후, 출발은 alarm+3분 — 미래 시각 기반이라 프리뷰 타이머가 실제로 틱한다.
    static func preview(
        alarmIn seconds: TimeInterval,
        urgency: LastTrainUrgency,
        badge: Bool = false,
        status: LastTrainSessionStatus = .active
    ) -> Self {
        let alarm = Date.now.addingTimeInterval(seconds)
        return .init(
            departureTime: alarm.addingTimeInterval(180),
            alarmTime: alarm,
            urgency: urgency,
            changeBadgeExpiry: badge ? Date.now.addingTimeInterval(600) : nil,
            status: status
        )
    }
}

#Preview("lock-active-relaxed", as: .content, using: LastTrainActivityAttributes.previewSubway) {
    LastTrainLiveActivityWidget()
} contentStates: {
    LastTrainActivityAttributes.ContentState.preview(alarmIn: 22 * 60, urgency: .relaxed)
}

#Preview(
    "lock-active-caution-badge", as: .content, using: LastTrainActivityAttributes.previewSubway
) {
    LastTrainLiveActivityWidget()
} contentStates: {
    LastTrainActivityAttributes.ContentState.preview(alarmIn: 7 * 60, urgency: .caution, badge: true)
}

#Preview(
    "lock-active-imminent", as: .content, using: LastTrainActivityAttributes.previewBusNoWalk
) {
    LastTrainLiveActivityWidget()
} contentStates: {
    LastTrainActivityAttributes.ContentState.preview(alarmIn: 45, urgency: .imminent)
}

#Preview("lock-final-states", as: .content, using: LastTrainActivityAttributes.previewSubway) {
    LastTrainLiveActivityWidget()
} contentStates: {
    LastTrainActivityAttributes.ContentState
        .preview(alarmIn: -60, urgency: .imminent, status: .departed)
    LastTrainActivityAttributes.ContentState
        .preview(alarmIn: -300, urgency: .imminent, status: .missed)
    LastTrainActivityAttributes.ContentState
        .preview(alarmIn: -300, urgency: .relaxed, status: .serviceEnded)
}

#Preview(
    "di-expanded", as: .dynamicIsland(.expanded),
    using: LastTrainActivityAttributes.previewSubway
) {
    LastTrainLiveActivityWidget()
} contentStates: {
    LastTrainActivityAttributes.ContentState.preview(alarmIn: 22 * 60, urgency: .relaxed)
    LastTrainActivityAttributes.ContentState.preview(alarmIn: 45, urgency: .imminent)
    LastTrainActivityAttributes.ContentState
        .preview(alarmIn: -300, urgency: .imminent, status: .missed)
}

#Preview(
    "di-compact", as: .dynamicIsland(.compact),
    using: LastTrainActivityAttributes.previewBusNoWalk
) {
    LastTrainLiveActivityWidget()
} contentStates: {
    LastTrainActivityAttributes.ContentState.preview(alarmIn: 7 * 60, urgency: .caution)
    LastTrainActivityAttributes.ContentState
        .preview(alarmIn: -300, urgency: .imminent, status: .missed)
}

#Preview(
    "di-minimal", as: .dynamicIsland(.minimal),
    using: LastTrainActivityAttributes.previewSubway
) {
    LastTrainLiveActivityWidget()
} contentStates: {
    LastTrainActivityAttributes.ContentState.preview(alarmIn: 22 * 60, urgency: .relaxed)
}

// 프리뷰 매크로는 context.isStale을 주입할 수 없다 — stale 분기는 뷰 직접 렌더로 확인.
#Preview("lock-stale") {
    LastTrainLockScreenView(
        attributes: .previewSubway,
        state: .preview(alarmIn: -300, urgency: .caution),
        isStale: true
    )
    .background(Color(ds: DSColor.Background.base))
}
