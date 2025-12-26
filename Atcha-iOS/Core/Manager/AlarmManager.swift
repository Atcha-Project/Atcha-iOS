//
//  AlarmManager.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 8/3/25.
//

import Foundation
import AVFAudio
import Combine
import UserNotifications
import AudioToolbox
import UIKit
import MediaPlayer

final class AlarmManager {
    static let shared = AlarmManager()
    
    // MARK: - Audio / Timer
    private var audioPlayer: AVAudioPlayer?
    private var timerCancellable: AnyCancellable?
    private var repeatingVibrationTimer: Timer?
    private var pendingStartWorkItem: DispatchWorkItem?
    
    // MARK: - State
    private var alarmVolume: Float = 1.0
    private var currentSoundFile: String?
    var selectedOption: PushAlarmOption = .onlySound
    
    // MARK: - Init
    private init() {
        loadStoredVolume()
        loadStoredAlarmOption()
        setupAudioSession()
    }
    
    // MARK: - Public: Volume / Option
    func updateVolume(to value: Float) {
        alarmVolume = value
        UserDefaultsWrapper.shared.set(value, forKey: UserDefaultsWrapper.Key.alarmVolume.rawValue)
        audioPlayer?.volume = value
    }
    
    func setAlarmOption(_ option: PushAlarmOption) {
        selectedOption = option
        UserDefaultsWrapper.shared.set(option, forKey: UserDefaultsWrapper.Key.alarmOption.rawValue)
    }
    
    func setAlarmVolume(_ volume: Float) {
        alarmVolume = volume
        UserDefaultsWrapper.shared.set(volume, forKey: UserDefaultsWrapper.Key.alarmVolume.rawValue)
        audioPlayer?.volume = volume
    }
    
    func ensureBackgroundSilentRunning() {
        if currentSoundFile != "silent" {
            playLocalMusic(named: "silent", withExtension: "mp3")
        }
    }
    
    // MARK: - Public: Start / Stop
    /// 서버에서 받은 출발 시각 기준으로 1분 전에 반복 푸시/사운드/진동을 시작
    func startAlarm(title: String, body: String) {
        // 기존 알람 상태만 정리 (silent는 유지 or 다시 켜기)
        stopAlarm(keepSilent: true)
        ensureBackgroundSilentRunning()
        applySavedVolumeForAlarmStart()
        startRepeatingPush(title: title, body: body)
    }
    
    func removeAllAlarmNotificationsExceptAutoStop() {
        let center = UNUserNotificationCenter.current()
        
        center.getPendingNotificationRequests { requests in
            let idsToRemove = requests
                .map { $0.identifier }
                .filter { $0 != AlarmNotificationID.autoStopInfo }
            
            center.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
        
        center.getDeliveredNotifications { notifications in
            let idsToRemove = notifications
                .map { $0.request.identifier }
                .filter { $0 != AlarmNotificationID.autoStopInfo }
            
            center.removeDeliveredNotifications(withIdentifiers: idsToRemove)
        }
    }
    
    /// 완전 정지: 예약/타이머/진동/알림/오디오 모두 끊기
    func stopAlarm(keepSilent: Bool = false) {
        pendingStartWorkItem?.cancel()
        pendingStartWorkItem = nil
        
        timerCancellable?.cancel()
        timerCancellable = nil
        
        stopRepeatingVibration()
        removeAllAlarmNotificationsExceptAutoStop()
        
        if keepSilent {
            // siren 재생 중이면 silent로 되돌리기
            if currentSoundFile != "silent" {
                playLocalMusic(named: "silent", withExtension: "mp3")
            }
        } else {
            audioPlayer?.stop()
            audioPlayer = nil
            currentSoundFile = nil
        }
        
        print("알람 종료 (keepSilent = \(keepSilent))")
    }
    
    func alarmInit() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    // MARK: - Public: Background Push (선택적)
    func sendBackgroundPush(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: AlarmNotificationID.autoStopInfo,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("푸시 전송 실패: \(error.localizedDescription)")
            } else {
                print("푸시 전송됨: \(title) - \(body)")
            }
        }
    }
}

// MARK: - Private: Session / Storage
extension AlarmManager {
    func loadStoredVolume() {
        let storedVolume = UserDefaultsWrapper.shared.float(forKey: UserDefaultsWrapper.Key.alarmVolume.rawValue) ?? 1.0
        alarmVolume = storedVolume
        print("저장된 볼륨: \(storedVolume)")
    }
    
    func loadStoredAlarmOption() {
        if let option: PushAlarmOption = UserDefaultsWrapper.shared.object(
            forKey: UserDefaultsWrapper.Key.alarmOption.rawValue,
            of: PushAlarmOption.self
        ) {
            selectedOption = option
            print("알람 타입 불러오기: \(option)")
        } else {
            selectedOption = .onlySound
            print("알람 타입 기본값 사용: onlySound")
        }
    }
    
    func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
            print("AVAudioSession 설정 완료")
        } catch let error as NSError {
            print("AVAudioSession 설정 오류: \(error.localizedDescription), code: \(error.code)")
        }
    }
}

// MARK: - Private: Repeating Push / Push builder
private extension AlarmManager {
    /// 2초마다 로컬 푸시 + (사운드/진동) 수행
    func startRepeatingPush(title: String, body: String) {
        // 기존 타이머가 있다면 먼저 취소(중복 방지)
        timerCancellable?.cancel()
        timerCancellable = nil
        
        timerCancellable = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                
                switch self.selectedOption {
                case .onlySound:
                    self.playLocalMusic(named: "siren", withExtension: "mp3")
                    
                case .onlyVibration:
                    self.startRepeatingVibration()
                    
                case .both:
                    self.playLocalMusic(named: "siren", withExtension: "mp3")
                    self.startRepeatingVibration()
                }
                
                self.sendImmediateLocalPush(title: title, body: body)
            }
    }
    
    func sendImmediateLocalPush(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil // 사운드는 직접 재생 중
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // 즉시 표시
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("푸시 전송 실패: \(error.localizedDescription)")
            } else {
                print("푸시 전송됨: \(title) - \(body)")
            }
        }
    }
}

// MARK: - Private: Music / Vibration
extension AlarmManager {
    func pauseMusic() {
        DispatchQueue.main.async {
            if let player = self.audioPlayer, player.isPlaying {
                player.pause()
                print("음악 일시 정지됨.")
            } else {
                print("현재 재생 중인 음악이 없습니다.")
            }
        }
    }
    
    func playLocalMusic(named fileName: String, withExtension fileExtension: String) {
        // 같은 파일이 이미 재생 중이면 무시
        if let player = audioPlayer,
           player.isPlaying,
           currentSoundFile == fileName {
            print("같은 노래가 이미 재생 중: \(fileName).\(fileExtension) → 재생 생략")
            return
        }
        
        currentSoundFile = fileName
        
        DispatchQueue.main.async {
            // 기존 재생 정지
            if let player = self.audioPlayer, player.isPlaying {
                player.stop()
            }
            self.audioPlayer = nil
            
            // 리소스 확인
            guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
                print("파일을 찾을 수 없습니다: \(fileName).\(fileExtension)")
                return
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1 // 무한 반복
                player.volume = self.alarmVolume
                player.prepareToPlay()
                player.play()
                self.audioPlayer = player
                print("음악 재생 시작: \(fileName).\(fileExtension)")
            } catch {
                print("오디오 재생 오류: \(error.localizedDescription)")
            }
        }
    }
    
    func startRepeatingVibration() {
        stopRepeatingVibration()
        vibrate()
        repeatingVibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.vibrate()
        }
    }
    
    func stopRepeatingVibration() {
        repeatingVibrationTimer?.invalidate()
        repeatingVibrationTimer = nil
    }
    
    func vibrate() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.prepare()
        impact.impactOccurred()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

// MARK: - Private: System Volume
private extension AlarmManager {
    func setVolume(_ volume: Float) {
        let clampedVolume = max(volume, 0.1) // 최소 볼륨 제한 (0으로 내려가면 시스템에 막힐 수 있음)
        
        DispatchQueue.main.async {
            let volumeView = MPVolumeView()
            
            guard let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider else {
                print("UISlider를 찾을 수 없습니다.")
                return
            }
            
            let currentVolume = slider.value
            print("현재 시스템 볼륨: \(currentVolume)")
            
            if currentVolume <= 0.1 || currentVolume < clampedVolume {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                    slider.value = clampedVolume
                    print("볼륨이 \(clampedVolume)으로 설정되었습니다.")
                }
            } else {
                print("현재 볼륨이 설정하려는 값보다 높아 변경하지 않습니다.")
            }
        }
    }
}

// MARK: - Public: Preview
extension AlarmManager {
    func previewAlarmVolume(_ volume: Float) {
        alarmVolume = volume
        
        switch selectedOption {
        case .onlySound:
            if currentSoundFile == "siren", let player = audioPlayer, player.isPlaying {
                player.volume = volume
                print("사운드 미리듣기 볼륨만 조정: \(volume)")
            } else {
                playLocalMusic(named: "siren", withExtension: "mp3")
                print("사운드 미리듣기 시작 (볼륨: \(volume))")
            }
            
        case .onlyVibration:
            startRepeatingVibration()
            print("진동 미리듣기")
            
        case .both:
            if currentSoundFile == "siren", let player = audioPlayer, player.isPlaying {
                player.volume = volume
                print("사운드+진동 볼륨만 조정: \(volume)")
            } else {
                playLocalMusic(named: "siren", withExtension: "mp3")
                print("사운드+진동 미리듣기 시작 (볼륨: \(volume))")
            }
            startRepeatingVibration()
        }
    }
    
    func stopPreview() {
        audioPlayer?.stop()
        audioPlayer = nil
        stopRepeatingVibration()
        print("미리듣기 완전 종료")
    }
}



extension AlarmManager {
    func applySavedVolumeForAlarmStart() {
        // 1) UserDefaults에서 값 다시 읽기
        let savedVolume = UserDefaultsWrapper.shared.float(
            forKey: UserDefaultsWrapper.Key.alarmVolume.rawValue
        ) ?? 0.7
        
        // 2) AlarmManager 상태 업데이트
        alarmVolume = savedVolume
        audioPlayer?.volume = savedVolume
        
        // 3) 시스템 볼륨도 최소한 이 값으로 맞추기
        setVolume(savedVolume)
        
        print("알람 시작 시 저장된 볼륨 적용: \(savedVolume)")
    }
}

enum AlarmNotificationID {
    static let autoStopInfo = "atcha.alarm.autostop"
}
