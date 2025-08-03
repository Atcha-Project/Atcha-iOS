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

class AlarmManager {
    static let shared: AlarmManager = .init()
    
    private var isFirstPushSent = false
    
    private var audioPlayer: AVAudioPlayer?
    private var timerCancellable: AnyCancellable?
    
    private init() {
        setupAudioSession()
        playLocalMusic(named: "silent", withExtension: "mp3")
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
    
    func playLocalMusic(named fileName: String, withExtension fileExtension: String) {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: fileExtension) else {
            print("파일을 찾을 수 없습니다.")
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.play()
            print("🎵 음악 재생 시작: \(fileName).\(fileExtension)")
        } catch {
            print("오디오 재생 오류: \(error.localizedDescription)")
        }
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
        
        let delay = targetDate.timeIntervalSinceNow
        if delay <= 0 {
            print("🕒 이미 지난 시간이므로 즉시 시작합니다.")
//            startRepeatingPush(title: title, body: body)
        } else {
            print("⌛ \(Int(delay))초 후 푸시 반복 시작")
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                self.startRepeatingPush(title: title, body: body)
            }
        }
    }
    
    private func startRepeatingPush(title: String,
                                    body: String) {
        isFirstPushSent = false // 시작 전 초기화
        
        timerCancellable = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if !self.isFirstPushSent {
                    self.playLocalMusic(named: "siren", withExtension: "mp3")
                    self.isFirstPushSent = true
                }
                self.sendLocalPush(title: title, body: body)
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
    
    func stopAlarm() {
        AlarmManager.shared.playLocalMusic(named: "silent", withExtension: "mp3")
        timerCancellable?.cancel()
        print("🛑 푸시 타이머 중지됨")
    }
}


//playLocalMusic(named: "siren", withExtension: "mp3")

// 사용자가 등록한 알람 시간 등록
// 사용자 알람 설정 시간 조회
// 알람 시간이 지난 이후 푸시 발송 로직


// iOS는 무한 push로 발송되는데 10분, 5분 설정한 경우 10분 부터 계속 오는 방식
// 잠금화면에 진입했을 때 다음 알람 받기 같은 flow가 필요합니다.
// 더 늦은 경로를 찾았을 때, 알람 시간이 된 경우 어떻게 처리가되는걸까요 ?!
// 알람 사운드는 어떤걸로 지정을 해야하나요...
//
