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
    private var pendingStartWorkItem: DispatchWorkItem?   // ⬅️ startAlarm 예약 취소용

    // MARK: - State
    private var alarmVolume: Float = 1.0
    private var currentSoundFile: String?
    var selectedOption: PushAlarmOption = .onlySound // 기본값

    // MARK: - Init
    private init() {
        loadStoredVolume()
        loadStoredAlarmOption()
        setupAudioSession()
        // 필요 시 묵음 재생 대신 정지 상태로 시작해도 무방
        playLocalMusic(named: "silent", withExtension: "mp3")
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

    // MARK: - Public: Start / Stop
    /// 서버에서 받은 출발 시각 기준으로 1분 전에 반복 푸시/사운드/진동을 시작
    func startAlarm(after departureDateTime: String, title: String, body: String) {
        // 기존 예약(cleanup)
        stopAlarm()
        pendingStartWorkItem?.cancel()
        pendingStartWorkItem = nil
        
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
            startRepeatingPush(title: title, body: body)
        } else {
            print("⌛ \(Int(delay))초 후 푸시 반복 시작 (1분 일찍 전송)")
            let work = DispatchWorkItem { [weak self] in
                self?.startRepeatingPush(title: title, body: body)
            }
            pendingStartWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
        }
    }

    /// 완전 정지: 예약/타이머/진동/알림/오디오 모두 끊기
    func stopAlarm() {
        // 1) 예약된 시작 작업 취소
        pendingStartWorkItem?.cancel()
        pendingStartWorkItem = nil

        // 2) 반복 타이머 취소
        timerCancellable?.cancel()
        timerCancellable = nil

        // 3) 진동 타이머 취소
        stopRepeatingVibration()

        // 4) 로컬 알림 전체 정리 (대기/표시)
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()

        // 5) 오디오 완전 정지
        audioPlayer?.stop()
        audioPlayer = nil
        currentSoundFile = nil

        print("🛑 알람 완전 종료")
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
                print("❌ 푸시 전송 실패: \(error.localizedDescription)")
            } else {
                print("✅ 푸시 전송됨: \(title) - \(body)")
            }
        }
    }
}

// MARK: - Private: Session / Storage
private extension AlarmManager {
    func loadStoredVolume() {
        let storedVolume = UserDefaultsWrapper.shared.float(forKey: UserDefaultsWrapper.Key.alarmVolume.rawValue) ?? 1.0
        alarmVolume = storedVolume
        print("🔊 저장된 볼륨: \(storedVolume)")
    }

    func loadStoredAlarmOption() {
        if let option: PushAlarmOption = UserDefaultsWrapper.shared.object(
            forKey: UserDefaultsWrapper.Key.alarmOption.rawValue,
            of: PushAlarmOption.self
        ) {
            selectedOption = option
            print("✅ 알람 타입 불러오기: \(option)")
        } else {
            selectedOption = .onlySound
            print("ℹ️ 알람 타입 기본값 사용: onlySound")
        }
    }

    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            print("🎧 AVAudioSession 설정 완료")
        } catch {
            print("AVAudioSession 설정 오류: \(error.localizedDescription)")
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
                    self.setVolume(self.alarmVolume)
                    self.playLocalMusic(named: "siren", withExtension: "mp3")

                case .onlyVibration:
                    self.startRepeatingVibration()

                case .both:
                    self.setVolume(self.alarmVolume)
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
                print("❌ 푸시 전송 실패: \(error.localizedDescription)")
            } else {
                print("✅ 푸시 전송됨: \(title) - \(body)")
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
                print("⏸ 음악 일시 정지됨.")
            } else {
                print("ℹ️ 현재 재생 중인 음악이 없습니다.")
            }
        }
    }

    func playLocalMusic(named fileName: String, withExtension fileExtension: String) {
        // 같은 파일이 이미 재생 중이면 무시
        if let player = audioPlayer,
           player.isPlaying,
           currentSoundFile == fileName {
            print("🎵 같은 노래가 이미 재생 중: \(fileName).\(fileExtension) → 재생 생략")
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


