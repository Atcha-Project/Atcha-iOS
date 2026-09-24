import Domain
import Foundation

/// 칩의 상태. **텍스트 없이 busy일 수 없다** — 예전에는 `recentRouteChipText: String?`과
/// `isChipBusy: Bool`이 따로 있어서 "숨겨진 칩이 진행 중"이라는 조합이 표현 가능했다.
enum HomeChipState: Equatable {
    case hidden
    case ready(text: String)
    /// 원탭 재검색 진행 중 — 칩은 보이되 비활성(더블 탭 방지).
    case busy(text: String)

    var text: String? {
        switch self {
        case .hidden: nil
        case let .ready(text), let .busy(text): text
        }
    }

    var isBusy: Bool {
        if case .busy = self { return true }
        return false
    }

    /// 재조회가 텍스트만 갈아 끼운다 — 진행 중 여부는 탭이 정한 것이라 보존한다.
    func withText(_ text: String?) -> HomeChipState {
        guard let text else { return .hidden }
        return isBusy ? .busy(text: text) : .ready(text: text)
    }

    func busy(_ isBusy: Bool) -> HomeChipState {
        guard let text else { return .hidden }
        return isBusy ? .busy(text: text) : .ready(text: text)
    }
}

/// 알람 세션의 화면 상태. **이 타입이 존재하는 이유는 조합을 줄이는 것이다.**
///
/// 예전에는 `routeCard` / `selectedRouteId` / `registeredRouteId` / `banner` /
/// `syncedAt` / `isAlarmBusy` 여섯 필드가 State에 평평하게 놓여 있었고, 다음이 전부
/// **타입상 표현 가능**했다.
///
/// - 등록이 없는데 배너가 있다
/// - 카드가 없는데 `selectedRouteId`가 있다 (버튼이 "해제"로 남는다)
/// - 등록이 없는데 `syncedAt`이 있다 ("HH:mm 확인 기준"이 떠 있다)
/// - 아무것도 없는데 `isAlarmBusy`가 true다 (버튼이 영영 비활성)
///
/// 그래서 `cancelAlarmTapped`가 다섯 필드를 **한 번에** 고쳐야 했다 — 하나씩 고치면
/// `didSet`이 중간 상태를 VC로 내보내기 때문이다. 이제 전이는 case 하나를 고르는 일이다.
enum HomeSessionState: Equatable {
    /// 카드도 등록도 없다.
    case empty
    /// 카드만 있다 — 등록 전. `busy`는 등록 요청 진행 중.
    case card(Card, busy: Bool)
    /// 유예가 지난 "지난 막차" 카드. 등록 버튼을 두지 않는다 — 누르면 tooLate로 실패할 뿐이다.
    case past(Card)
    /// 서버에 등록된 세션. `card`가 nil일 수 있다(재실행 복원이 상세를 아직 못 받았을 때).
    /// `busy`는 해제 또는 재등록 요청 진행 중.
    case armed(Registration, card: Card?, busy: Bool)

    /// 카드와 그 경로 id는 **절대 갈라질 수 없다.** 예전에는 `selectedRoute`의 `didSet`이
    /// `state.selectedRouteId`를 손으로 맞췄고, 그 사이 `state = newState` 한 줄이 옛 id를
    /// 되살려 지난 막차에 등록 버튼이 남는 버그가 실제로 있었다.
    struct Card: Equatable {
        let routeId: String
        var view: RouteCardViewData
    }

    /// 배너와 확인 시각은 **등록이 있을 때만** 의미가 있다 — 그래서 여기 산다.
    struct Registration: Equatable {
        let routeId: String
        var banner: HomeViewModel.BannerViewData?
        var syncedAt: Date?

        func clearingBanner() -> Registration {
            Registration(routeId: routeId, banner: nil, syncedAt: syncedAt)
        }
    }

    // MARK: - 읽기 표면 (저장하지 않는다)

    var card: Card? {
        switch self {
        case .empty: nil
        case let .card(card, _), let .past(card): card
        case let .armed(_, card, _): card
        }
    }

    var registration: Registration? {
        if case let .armed(registration, _, _) = self { return registration }
        return nil
    }

    var isBusy: Bool {
        switch self {
        case .empty, .past: false
        case let .card(_, busy), let .armed(_, _, busy): busy
        }
    }

    var alarmButton: HomeViewModel.AlarmButtonMode {
        switch self {
        case .empty, .past:
            .hidden
        case .card:
            .register
        case let .armed(registration, card, _):
            // 등록된 채로 다른 경로를 고른 상태 — 그 카드의 알람은 아직 없으니 "등록"이다.
            // 카드가 없으면(복원 중) 해제만 가능하다.
            card.map { $0.routeId == registration.routeId ? .cancel : .register } ?? .cancel
        }
    }

    // MARK: - 전이

    /// 새 경로를 골랐다. 기존 배너는 더 이상 유효하지 않다(재등록 전까지 숨김).
    /// 등록 자체는 살아 있다 — 해제하지 않고 다른 경로를 보는 것은 정상 흐름이다.
    func selecting(_ card: Card) -> HomeSessionState {
        switch self {
        case .empty, .past:
            .card(card, busy: false)
        case let .card(_, busy):
            .card(card, busy: busy)
        case let .armed(registration, _, busy):
            .armed(registration.clearingBanner(), card: card, busy: busy)
        }
    }

    func settingBusy(_ busy: Bool) -> HomeSessionState {
        switch self {
        case .empty, .past: self
        case let .card(card, _): .card(card, busy: busy)
        case let .armed(registration, card, _): .armed(registration, card: card, busy: busy)
        }
    }

    /// 등록이 확정됐다(등록 성공·동기화 수신). 카드는 있으면 유지한다.
    func arming(_ registration: Registration, busy: Bool) -> HomeSessionState {
        .armed(registration, card: card, busy: busy)
    }

    /// 등록이 사라졌다(해제 성공·세션 종료). 카드가 있으면 카드만 남는다.
    func disarmed() -> HomeSessionState {
        guard let card else { return .empty }
        return .card(card, busy: false)
    }

    /// 배너만 갈아 끼운다 — 등록이 없으면 무시된다(배너가 홀로 뜨는 조합을 막는 지점).
    func withBanner(_ banner: HomeViewModel.BannerViewData?) -> HomeSessionState {
        guard case let .armed(registration, card, busy) = self else { return self }
        var updated = registration
        updated.banner = banner
        return .armed(updated, card: card, busy: busy)
    }

    /// 카드를 갈아 끼운다(재실행 복원의 상세 도착).
    func withCard(_ card: Card) -> HomeSessionState {
        switch self {
        case .empty: .card(card, busy: false)
        case let .card(_, busy): .card(card, busy: busy)
        case .past: .past(card)
        case let .armed(registration, _, busy): .armed(registration, card: card, busy: busy)
        }
    }
}
