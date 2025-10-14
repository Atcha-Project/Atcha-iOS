//
//  BaseViewModel.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import Foundation
import Combine
import AVFoundation

class BaseViewModel {
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String? = nil
    @Published private(set) var showAlert: Bool = false
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRefreshNotification(_:)),
            name: .fcmDidReceiveRefresh,
            object: nil
        )
    }
    
    func setLoading(_ loading: Bool) {
        isLoading = loading
    }
    
    func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        showAlert = true
    }
    
    @objc func handleRefreshNotification(_ notification: Notification) {}
    @objc func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let interruptionTypeRaw = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let interruptionType = AVAudioSession.InterruptionType(rawValue: interruptionTypeRaw) else { return }
        
        switch interruptionType {
        case .began:
            // 다른 앱에서 음악 재생 등으로 인해 인터럽션이 발생한 경우
            print("오디오 인터럽션 시작됨: 다른 앱에서 오디오가 재생되었을 수 있음.")
            AlarmManager.shared.pauseMusic()
        case .ended:
            print("오디오 인터럽션 종료됨.")
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                AlarmManager.shared.playLocalMusic(named: "silent", withExtension: "mp3")
            }
            
        @unknown default:
            break
        }
    }
}

