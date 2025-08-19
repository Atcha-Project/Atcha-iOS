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

class AlarmManager {
    static let shared: AlarmManager = .init()
    
    private var isFirstPushSent = false
    
    private var audioPlayer: AVAudioPlayer?
    private var timerCancellable: AnyCancellable?
    
    var currentVolume: Float {
        return alarmVolume
    }
    private var alarmVolume: Float = 1.0
    private var currentSoundFile: String?
    
    private init() {
        loadStoredVolume()
        setupAudioSession()
        playLocalMusic(named: "silent", withExtension: "mp3")
    }
    
    func updateVolume(to value: Float) {
        alarmVolume = value
        print("🔊 알람 볼륨 설정됨: \(value)")
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
        AlarmManager.shared.playLocalMusic(named: "silent", withExtension: "mp3")
        timerCancellable?.cancel()
        timerCancellable = nil
        print("🛑 푸시 타이머 중지됨")
    }
}

extension AlarmManager {
    private func loadStoredVolume() {
        let storedVolume = UserDefaultsWrapper.shared.float(forKey: UserDefaultsWrapper.Key.alarmVolume.rawValue) ?? 1.0
        print(storedVolume)
        alarmVolume = storedVolume
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
        self.currentSoundFile = fileName
        
        DispatchQueue.main.async {
            if let player = self.audioPlayer, player.isPlaying {
                player.stop()
            }
            self.audioPlayer = nil
            
            guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
                print("파일을 찾을 수 없습니다: \(fileName).\(fileExtension)")
                return
            }
            
            do {
                let player = try AVAudioPlayer(contentsOf: url)
                player.numberOfLoops = -1
                player.volume = self.alarmVolume
                player.prepareToPlay()
                player.play()
                self.audioPlayer = player
                print("🎵 음악 재생 시작(교체됨): \(fileName).\(fileExtension)")
            } catch {
                print("오디오 재생 오류: \(error.localizedDescription)")
            }
        }
    }
    
    private func startRepeatingPush(title: String,
                                    body: String) {
        isFirstPushSent = false // 시작 전 초기화
        
        // 타이머 시작
        timerCancellable = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if !self.isFirstPushSent {
                    self.playLocalMusic(named: "siren", withExtension: "mp3")
                    self.isFirstPushSent = true
                }
                self.sendLocalPush(title: title, body: body)
            }
        
        // 2분(120초) 후 타이머 종료
        DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
            self.playLocalMusic(named: "silent", withExtension: "mp3")
            self.timerCancellable?.cancel()
            self.timerCancellable = nil
            print("⏹ 푸시 반복이 종료되었습니다. (2분 경과)")
        }
    }
    
    private func sendLocalPush(title: String,
                               body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
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
    
    func previewAlarmVolume(_ volume: Float) {
        alarmVolume = volume

        if currentSoundFile == "siren", let player = audioPlayer, player.isPlaying {
            player.volume = volume
            print("🔁 미리듣기 볼륨만 조정: \(volume)")
        } else {
            playLocalMusic(named: "siren", withExtension: "mp3")
            print("▶️ 미리듣기 시작 (볼륨: \(volume))")
        }
    }

    
    func stopPreview() {
        audioPlayer?.stop()
        audioPlayer = nil
        print(" 미리듣기 완전 종료")
    }
}


//    private func vibrate() {
//        let impact = UIImpactFeedbackGenerator(style: .heavy)
//        impact.impactOccurred()
//        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
//    }
