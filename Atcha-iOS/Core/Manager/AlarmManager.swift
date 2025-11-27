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
    private var repeatingVibrationTimer: Timer?
    
    // MARK: - State
    private var alarmVolume: Float = 1.0
    private var currentSoundFile: String?
    var selectedOption: PushAlarmOption = .onlySound // 기본값
    
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
    
    
    /// 완전 정지: 예약/타이머/진동/알림/오디오 모두 끊기
    func stopAlarm() {
        
        // 진동 타이머 취소
        stopRepeatingVibration()
        
        // 로컬 알림 전체 정리 (대기/표시)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        
        // 오디오 완전 정지
        audioPlayer?.stop()
        audioPlayer = nil
        currentSoundFile = nil
        
        print("알람 완전 종료")
    }
    
    // MARK: - Public: Background Push (선택적)
    func sendBackgroundPush(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
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
private extension AlarmManager {
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
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("AVAudioSession 설정 완료")
        } catch {
            print("AVAudioSession 설정 오류: \(error.localizedDescription)")
        }
    }
}

// MARK: - 알람 예약
extension AlarmManager {
    func startAlarm1MinuteBefore(
        departureDateTime: String,
        title: String,
        body: String
    ) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: ["DEPARTURE_ALARM"])
        
        if let didFire = UserDefaultsWrapper.shared.bool(forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue) {
            if didFire {
                print("이미 출발 알람이 울린 상태라 재예약하지 않습니다.")
                return
            }
        }
                
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        
        guard let departure = formatter.date(from: departureDateTime) else { return }
        
        // 출발 분 -1, 초 = 0
        let hour = Calendar.current.component(.hour, from: departure)
        let minute = Calendar.current.component(.minute, from: departure)
        
        var fireDate: Date!
        if let adjusted = Calendar.current.date(bySettingHour: hour,
                                                minute: minute - 1,
                                                second: 0,
                                                of: departure) {
            fireDate = adjusted
        } else {
            fireDate = departure.addingTimeInterval(-60)
        }
        
        // 이미 지난 경우 처리
        let now = Date()
        if fireDate <= now {
            let startFromNow = now.addingTimeInterval(1)
            scheduleRepeatedPushes(title: title,
                                   body: body,
                                   start: startFromNow,
                                   duration: 60)
            return
        }
        
        scheduleRepeatedPushes(title: title,
                               body: body,
                               start: fireDate,
                               duration: 60)
    }
    
    func scheduleRepeatedPushes(
        title: String,
        body: String,
        start: Date,
        duration: TimeInterval = 60  // 1분간 반복
    ) {
        let center = UNUserNotificationCenter.current()
        var requests: [UNNotificationRequest] = []
        
        let end = start.addingTimeInterval(duration)
        var current = start
        
        let firstGap: TimeInterval = 8
        let nextGap: TimeInterval = 7
        var isFirstStep = true
        
        while current <= end {
            let comps = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute, .second],
                from: current
            )
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = UNNotificationSound(
                named: UNNotificationSoundName("siren.mp3")
            )
            content.userInfo = ["alarmType": "DEPARTURE_ALARM"]
            
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: comps,
                repeats: false
            )
            
            let request = UNNotificationRequest(
                identifier: "REPEATED_PUSH_\(current.timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            requests.append(request)
            
            let gap = isFirstStep ? firstGap : nextGap
            isFirstStep = false
            current = current.addingTimeInterval(gap)
        }
        
        requests.forEach { req in
            center.add(req) { error in
                if let error = error {
                    print("반복 알람 등록 실패:", error.localizedDescription)
                }
            }
        }
        
        print("\(requests.count)개의 반복 알림 예약 완료")
    }
    
    func startImmediateAlarm() {
        
        UserDefaultsWrapper.shared.set(
            true,
            forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue
        )
        
        
        NotificationCenter.default.post(
            name: .alarmPushTapped,
            object: nil,
            userInfo: nil
        )
        
        setVolume(alarmVolume)
        
        
        
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
        
        switch selectedOption {
        case .onlySound:
            playLocalMusic(named: "siren", withExtension: "mp3")
            
        case .onlyVibration:
            startRepeatingVibration()
            
        case .both:
            playLocalMusic(named: "siren", withExtension: "mp3")
            startRepeatingVibration()
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
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(true)
        } catch {
            print("오디오 세션 재활성화 실패: \(error.localizedDescription)")
        }
        
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


