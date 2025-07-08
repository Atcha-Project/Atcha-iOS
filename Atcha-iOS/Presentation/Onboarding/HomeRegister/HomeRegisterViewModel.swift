//
//  HomeRegisterViewModel.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/23/25.
//

import Combine
import CoreLocation

// 장소 상태 Enum
enum LocationSelectionState {
    case none
    case selected(name: String, address: String)
}

final class HomeRegisterViewModel: BaseViewModel {
    var findLocationSubeject = PassthroughSubject<Void, Never>()
    var searchAddressSubject = PassthroughSubject<Void, Never>()
    
    private let searchAddressUseCase: SearchAddressUseCase

    // 장소 선택/미선택 상태 변수
//    @Published private(set) var locationState: LocationSelectionState = .none
//    var onFinish: ((Bool) -> Void)?
//    var selectedLocation: SelectedLocation? = nil
    
    init(searchAddressUseCase: SearchAddressUseCase) {
        self.searchAddressUseCase = searchAddressUseCase
    }
    
    func findLocationTapped() {
        findLocationSubeject.send(())
    }
    
    func searchAddressTapped() {
        searchAddressSubject.send(())
    }
}
