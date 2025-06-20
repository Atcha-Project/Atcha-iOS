//
//  BaseViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation
import Combine

class BaseViewModel {
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var showAlert: Bool = false
    
    var cancellables = Set<AnyCancellable>()
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showAlert = true
    }
}

