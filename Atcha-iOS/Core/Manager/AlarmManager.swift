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

class AlarmManager {
    static let shared: AlarmManager = .init()
    private var audioPlayer: AVAudioPlayer?
    private var timerCancellable: AnyCancellable?
    private var alarmVolume: Float = 1.0
    private var currentSoundFile: String?
    
    private var repeatingVibrationTimer: Timer?
    
    var selectedOption: PushAlarmOption = .onlySound // 기본값
    
    private init() {
        loadStoredVolume()
        loadStoredAlarmOption()
        setupAudioSession()
        playLocalMusic(named: "silent", withExtension: "mp3")
    }
    
    func updateVolume(to value: Float) {
        alarmVolume = value
        UserDefaultsWrapper.shared.set(value, forKey: UserDefaultsWrapper.Key.alarmVolume.rawValue)
        audioPlayer?.volume = value
    }
    
    func startAlarm(after departureDateTime: String,
                    title: String,
                    body: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = .current
        
        guard let targetDate = formatter.date(from: departureDateTime) else {
            print("❌ 날짜 문자열 변환 실패: \(departureDateTime)")
            return
        }
        
        let delay = targetDate.timeIntervalSinceNow - 60
        if delay <= 0 {
            print("🕒 이미 지난 시간이므로 즉시 시작합니다.")
            // startRepeatingPush(title: title, body: body)
        } else {
            print("⌛ \(Int(delay))초 후 푸시 반복 시작 (1분 일찍 전송)")
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.startRepeatingPush(title: title, body: body)
            }
        }
    }
    
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
                print("❌ 푸시 전송 실패: \(error.localizedDescription)")
            } else {
                print("✅ 푸시 전송됨: \(title) - \(body)")
            }
        }
    }
    
    func stopAlarm() {
        playLocalMusic(named: "silent", withExtension: "mp3")
        timerCancellable?.cancel()
        timerCancellable = nil
        stopRepeatingVibration()
        print("🛑 푸시 타이머 중지됨")
    }
}

extension AlarmManager {
    private func loadStoredVolume() {
        let storedVolume = UserDefaultsWrapper.shared.float(forKey: UserDefaultsWrapper.Key.alarmVolume.rawValue) ?? 1.0
        print(storedVolume)
        alarmVolume = storedVolume
    }
    
    private func loadStoredAlarmOption() {
        if let option: PushAlarmOption = UserDefaultsWrapper.shared.object(forKey: UserDefaultsWrapper.Key.alarmOption.rawValue, of: PushAlarmOption.self) {
            self.selectedOption = option
            print("✅ 알람 타입 불러오기: \(option)")
        } else {
            self.selectedOption = .onlySound
            print("ℹ️ 알람 타입 기본값 사용: onlySound")
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("AVAudioSession 설정 완료")
        } catch {
            print("AVAudioSession 설정 오류: \(error.localizedDescription)")
        }
    }
    
    private func playLocalMusic(named fileName: String, withExtension fileExtension: String) {
        // 같은 노래가 이미 재생 중이면 재생하지 않음
        
        if let player = self.audioPlayer,
           player.isPlaying,
           self.currentSoundFile == fileName {
            print("🎵 같은 노래가 이미 재생 중이므로 재생 무시: \(fileName).\(fileExtension)")
            return
        }
        
        self.currentSoundFile = fileName
        
        DispatchQueue.main.async {
            // 기존 재생 중인 음악 정지
            if let player = self.audioPlayer, player.isPlaying {
                player.stop()
            }
            self.audioPlayer = nil
            
            // 리소스 경로 확인
            guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
                print("❌ 파일을 찾을 수 없습니다: \(fileName).\(fileExtension)")
                return
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1 // 무한 반복
                player.volume = self.alarmVolume
                player.prepareToPlay()
                player.play()
                self.audioPlayer = player
                print("🎵 음악 재생 시작: \(fileName).\(fileExtension)")
            } catch {
                print("❌ 오디오 재생 오류: \(error.localizedDescription)")
            }
        }
    }
    
    private func startRepeatingPush(title: String, body: String) {
        timerCancellable = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                switch self.selectedOption {
                case .onlySound:
                    setVolume(alarmVolume)
                    playLocalMusic(named: "siren", withExtension: "mp3")
                case .onlyVibration:
                    startRepeatingVibration()
                case .both:
                    playLocalMusic(named: "siren", withExtension: "mp3")
                    startRepeatingVibration()
                }
                
                sendLocalPush(title: title, body: body)
            }
    }
    
    private func sendLocalPush(title: String,
                               body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = nil
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 푸시 전송 실패: \(error.localizedDescription)")
            } else {
                print("✅ 푸시 전송됨: \(title) - \(body)")
            }
        }
    }
    
    func setAlarmOption(_ option: PushAlarmOption) {
        self.selectedOption = option
        UserDefaultsWrapper.shared.set(option, forKey: UserDefaultsWrapper.Key.alarmOption.rawValue)
    }
    
    func setAlarmVolume(_ volume: Float) {
        self.alarmVolume = volume
        UserDefaultsWrapper.shared.set(volume, forKey: UserDefaultsWrapper.Key.alarmVolume.rawValue)
    }
    
    private func startRepeatingVibration() {
        stopRepeatingVibration()
        vibrate()
        repeatingVibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.vibrate()
        }
    }
    
    private func stopRepeatingVibration() {
        repeatingVibrationTimer?.invalidate()
        repeatingVibrationTimer = nil
    }
    
    private func vibrate() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.prepare()
        impact.impactOccurred()
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}

// MARK: System
extension AlarmManager {
    private func setVolume(_ volume: Float) {
        let clampedVolume = max(volume, 0.1) // 최소 볼륨 제한
        
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

// MARK: Preview
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
            self.startRepeatingVibration()
            print("진동 미리듣기")
            
        case .both:
            if currentSoundFile == "siren", let player = audioPlayer, player.isPlaying {
                player.volume = volume
                print("사운드+진동 볼륨만 조정: \(volume)")
            } else {
                playLocalMusic(named: "siren", withExtension: "mp3")
                print("사운드+진동 미리듣기 시작 (볼륨: \(volume))")
            }
            self.startRepeatingVibration()
        }
    }
    
    func stopPreview() {
        audioPlayer?.stop()
        audioPlayer = nil
        stopRepeatingVibration()
        print("미리듣기 완전 종료")
    }
}

