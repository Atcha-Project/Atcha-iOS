import Foundation

// 알람 세션이 경로에서 취하는 파생값 — 등록(스냅샷 저장)·LA 어댑터·홈이 같은 계산을
// 봐야 하므로 Domain 순수 계산으로 둔다(이중 계산 금지, 미확정 #7 클라 임시안).
public extension LastRoute {
    /// 알람 기준 시각에 반영하는 첫 도보 구간 시간(초) — legs의 **첫 `.walk` leg**의
    /// sectionTime. 도보 구간이 없으면 nil(호출자는 버퍼만 적용으로 폴백).
    var firstWalkSectionSeconds: Int? {
        legs.first(where: { $0.mode == .walk })?.sectionTime
    }

    /// 막차 탑승 구간 — departureTime이 있는 첫 대중교통 구간, 없으면 첫 대중교통 구간.
    var boardingLeg: TransportLeg? {
        let transitLegs = legs.filter { $0.mode == .bus || $0.mode == .subway }
        return transitLegs.first(where: { $0.departureTime != nil }) ?? transitLegs.first
    }

    /// 노선 표시명 — LA 타이틀·스냅샷(재실행 복원)용.
    /// 버스 routeName은 "타입:번호"(예: "간선:472") → "472번 버스", 지하철은 노선명
    /// 그대로(급행이면 " 급행"). 탑승 구간이 없으면 "막차".
    var sessionDisplayName: String {
        guard let leg = boardingLeg else { return "막차" }
        switch leg.mode {
        case .subway:
            guard let name = leg.routeName else { return "지하철" }
            return leg.isExpressSubway ? "\(name) 급행" : name
        case .bus:
            guard let routeName = leg.routeName else { return "버스" }
            guard let colonIndex = routeName.firstIndex(of: ":") else {
                return "\(routeName)번 버스"
            }
            let number = String(routeName[routeName.index(after: colonIndex)...])
            return "\(number)번 버스"
        case .walk, .unknown:
            return "막차"
        }
    }
}
