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
import CoreHaptics

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
    var selectedOption: PushAlarmOption = .onlyVibration
    
    private var interruptionObserver: NSObjectProtocol?
    private var silenceHintObserver: NSObjectProtocol?
    private var shouldKeepBackgroundAudio = false
    private var isPreviewing = false
    private var hapticEngine: CHHapticEngine?
    
    // MARK: - Init
    private init() {
        loadStoredVolume()
        loadStoredAlarmOption()
        setupAudioSession()
        startObservingAudioSession()
        preloadPreviewSound()
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
        if currentSoundFile != "silent" || audioPlayer?.isPlaying != true {
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
        shouldKeepBackgroundAudio = false
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
    
    private func preloadPreviewSound() {
        guard let url = Bundle.main.url(forResource: "siren", withExtension: "mp3") else { return }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            print("알람음 프리로드 실패")
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
            selectedOption = .onlyVibration
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
extension AlarmManager {
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
    
    func scheduleLocalNotification(from dateString: String, title: String, body: String) {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        
        guard let targetDate = formatter.date(from: dateString) else { return }
        guard let tenMinutesBefore = Calendar.current.date(byAdding: .minute, value: -10, to: targetDate) else { return }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second],
                                                          from: tenMinutesBefore)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let center = UNUserNotificationCenter.current()
        
        center.removePendingNotificationRequests(withIdentifiers: [AlarmNotificationID.tenMinutesBefore])
        center.removeDeliveredNotifications(withIdentifiers: [AlarmNotificationID.tenMinutesBefore])
        
        let request = UNNotificationRequest(
            identifier: AlarmNotificationID.tenMinutesBefore,
            content: content,
            trigger: trigger
        )
        
        center.add(request) { error in
            if let error = error {
                print("알림 등록 실패: \(error.localizedDescription)")
            } else {
                print("10분 전 로컬 알림 재예약 완료: \(tenMinutesBefore)")
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
        playHaptic()
        repeatingVibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.playHaptic()
        }
    }
    
    func stopRepeatingVibration() {
        repeatingVibrationTimer?.invalidate()
        repeatingVibrationTimer = nil
    }
    
    private func playHaptic() {
        guard let engine = hapticEngine else {
            // 햅틱 엔진이 없으면 기존 방식 사용
            vibrateLegacy()
            return
        }
        
        do {
            // 강한 연속 진동 패턴 생성
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: 0,
                duration: 0.3 // 0.3초 지속
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            
        } catch {
            print("햅틱 재생 실패: \(error.localizedDescription)")
            vibrateLegacy() // 실패하면 기존 방식으로 폴백
        }
    }
    
    private func vibrateLegacy() {
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
    func setAlarmArmed(_ armed: Bool) {
        shouldKeepBackgroundAudio = armed
        if armed { ensureBackgroundSilentRunning() }
    }
}



extension AlarmManager {
    func applySavedVolumeForAlarmStart() {
        // 1) UserDefaults에서 값 다시 읽기
        let savedVolume = UserDefaultsWrapper.shared.float(
            forKey: UserDefaultsWrapper.Key.alarmVolume.rawValue
        ) ?? 0.3
        
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
    static let tenMinutesBefore = "atcha.alarm.tenMinutesBefore"
}

extension AlarmManager {
    private func startObservingAudioSession() {
        
        interruptionObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] noti in
            self?.handleAudioSessionInterruption(noti)
        }
        
        silenceHintObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.silenceSecondaryAudioHintNotification,
            object: nil,
            queue: .main
        ) { [weak self] noti in
            self?.handleSilenceSecondaryAudioHint(noti)
        }        }
    
    private func handleAudioSessionInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let raw = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        
        switch type {
        case .began:
            print("오디오 Interruption 시작")
            pauseMusic()
            
        case .ended:
            print("오디오 Interruption 종료")
            setupAudioSession()
            ensureBackgroundSilentRunning()
        @unknown default:
            break
        }
    }
    
    private func handleSilenceSecondaryAudioHint(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let raw = userInfo[AVAudioSessionSilenceSecondaryAudioHintTypeKey] as? UInt,
              let type = AVAudioSession.SilenceSecondaryAudioHintType(rawValue: raw) else { return }
        
        switch type {
        case .begin:
            print("오디오 Silence 시작")
            pauseMusic()
        case .end:
            print("오디오 Silence 종료")
            ensureBackgroundSilentRunning()
        @unknown default:
            break
        }
    }
}

extension AlarmManager{
    private func setupHapticEngine() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("기기가 햅틱을 지원하지 않습니다")
            return
        }
        
        do {
            hapticEngine = try CHHapticEngine()
            try hapticEngine?.start()
            print("햅틱 엔진 초기화 완료")
            
            // 엔진이 중단되면 자동 재시작
            hapticEngine?.stoppedHandler = { [weak self] reason in
                print("햅틱 엔진 중단: \(reason)")
                self?.restartHapticEngine()
            }
            
            hapticEngine?.resetHandler = { [weak self] in
                print("햅틱 엔진 리셋")
                self?.restartHapticEngine()
            }
        } catch {
            print("햅틱 엔진 생성 실패: \(error.localizedDescription)")
        }
    }
    
    private func restartHapticEngine() {
        do {
            try hapticEngine?.start()
            print("햅틱 엔진 재시작 완료")
        } catch {
            print("햅틱 엔진 재시작 실패: \(error.localizedDescription)")
        }
    }
}


extension AlarmManager {
    func previewAlarmVolume(_ volume: Float) {
        isPreviewing = true
        alarmVolume = volume
        
        stopRepeatingVibration()
        
        // 햅틱 엔진이 중단되어 있으면 재시작
        if selectedOption == .onlyVibration || selectedOption == .both {
            restartHapticEngine()
        }
        
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
            audioPlayer?.stop()
            audioPlayer = nil
            currentSoundFile = nil
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
        isPreviewing = false
        stopRepeatingVibration()
        
        if shouldKeepBackgroundAudio {
            ensureBackgroundSilentRunning()
        } else {
            audioPlayer?.stop()
            audioPlayer = nil
            currentSoundFile = nil
        }
        
        print("미리듣기 종료 (keep=\(shouldKeepBackgroundAudio))")
    }
}
