//
//  BaseViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/20/25.
//

import UIKit
import Combine
import CoreLocation

class BaseViewController<VM: BaseViewModel>: UIViewController {
    var activePermissionToast: AtchaActionToast?
    var activeAlarmPermissionToast: AtchaActionToast?
    
    let viewModel: VM
    var cancellables = Set<AnyCancellable>()
    
    private var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    private var reconnectView: NetworkReconnectView?
    var onNetworkReconnect: (() -> Void)?
    
    open var usesViewModelLoadingBinding: Bool { true }
    private var loadingView: LoadingView?
    
    // MARK: - Init
    init(viewModel: VM) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        setupBindings()
        setupKeyboardDismiss()
        observeNetwork()
        setupErrorObserver()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self as? any UIGestureRecognizerDelegate
    }
    
    @objc func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return navigationController?.viewControllers.count ?? 0 > 1
    }
    
    private func setupLayout() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .gray950
        
        // Loading Indicator 추가
        view.addSubview(loadingIndicator)
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        if usesViewModelLoadingBinding {
            viewModel.$isLoading
                .receive(on: DispatchQueue.main)
                .sink { [weak self] isLoading in
                    guard let self else { return }
                    if isLoading {
                        self.showLoading()
                    } else {
                        self.hideLoading()
                    }
                }
                .store(in: &cancellables)
        }
        
        viewModel.$errorMessage
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                guard let self else { return }
                showAlert(message: message)
            }
            .store(in: &cancellables)
    }
    
    private func setupKeyboardDismiss() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc private func hideKeyboard() {
        view.endEditing(true)
    }
    
    func showAlert(title: String = "알람", message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let ok = UIAlertAction(title: "확인", style: .default, handler: nil)
        alert.addAction(ok)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - 로딩 뷰 보여주기
    func showLoading() {
        if loadingView != nil { return }
        
        let loading = LoadingView(frame: view.bounds)
        loading.start()
        loading.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loading)
        
        NSLayoutConstraint.activate([
            loading.topAnchor.constraint(equalTo: view.topAnchor),
            loading.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loading.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loading.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        loadingView = loading
        loadingView?.layer.zPosition = 100
    }
    
    func showLoadingOnce() {
        hideLoading()
        
        let loading = LoadingView(frame: view.bounds)
        loading.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loading)
        
        NSLayoutConstraint.activate([
            loading.topAnchor.constraint(equalTo: view.topAnchor),
            loading.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loading.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loading.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        loading.layer.zPosition = 100
        loadingView = loading
        loading.startOnce()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.hideLoading()
        }
    }
    
    // MARK: - 로딩 뷰 숨기기
    func hideLoading() {
        loadingView?.stop()
        loadingView?.removeFromSuperview()
        loadingView = nil
    }
    
    
    func observeNetwork() {
        NetworkPatcher.shared.onStatusChange = { [weak self] isConnected in
            guard let self else { return }
            DispatchQueue.main.async {
                if isConnected {
                    self.hideReconnectView()
                    self.onNetworkReconnect?()
                } else {
                    self.showReconnectView()
                }
            }
        }
    }
    
    func showReconnectView() {
        if reconnectView != nil { return }
        
        let reconnect = NetworkReconnectView()
        reconnect.translatesAutoresizingMaskIntoConstraints = false
        
        reconnect.onRetry = { [weak self] in
            guard let self else { return }
            
            if NetworkPatcher.shared.isConnected {
                self.hideReconnectView()
            } else {
                self.showReconnectView()
            }
        }
        
        view.addSubview(reconnect)
        
        NSLayoutConstraint.activate([
            reconnect.topAnchor.constraint(equalTo: view.topAnchor),
            reconnect.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            reconnect.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            reconnect.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        reconnectView = reconnect
    }
    
    func hideReconnectView() {
        reconnectView?.removeFromSuperview()
        reconnectView = nil
    }
    
    private func setupErrorObserver() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleServerError(_:)),
            name: .apiErrorOccurred,
            object: nil
        )
    }

    @objc private func handleServerError(_ notification: Notification) {
        // 1. 전달된 오브젝트가 APIError인지 확인
        guard let apiError = notification.object as? APIError else { return }
        
        // 2. 에러 케이스와 상태 코드 추출 (APIError가 statusCode를 가지고 있다고 가정)
        if case .serverError(let statusCode) = apiError {
            
            // 3. 500번대 에러인 경우에만 팝업 노출
            if (500...599).contains(statusCode) {
                guard self.presentedViewController == nil else { return }
                
                DispatchQueue.main.async { [weak self] in
                    self?.showAtchaErrorPopup()
                }
            } else {
                // 400번대 등 기타 에러는 팝업을 띄우지 않고 로그만 남기거나 별도 처리
                print("UI 팝업 제외 대상 에러: \(statusCode)")
            }
        }
    }
    
    private func showAtchaErrorPopup() {
        // 이전에 만드신 앗차팝업 호출 (에러 케이스용)
        let popupVM = AtchaPopupViewModel(info: .serverError) // Enum에 .serverError 추가 필요
        let popupVC = AtchaPopupViewController(viewModel: popupVM)
        
        popupVC.confirmButton.addAction(UIAction { [weak popupVC] _ in
            popupVC?.dismiss(animated: false)
        }, for: .touchUpInside)
        
        popupVC.modalPresentationStyle = .overFullScreen
        self.present(popupVC, animated: false)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: .apiErrorOccurred, object: nil)
    }
}

extension BaseViewController {
    func ensureLocationPermissionOrShowToast() -> Bool {
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            activePermissionToast?.hideImmediately()
            activePermissionToast = nil
            return true
            
        case .denied, .restricted:
            activePermissionToast?.hideImmediately()
            
            let toast = AtchaActionToast(
                message: "위치 권한을 허용해 주세요",
                actionTitle: "설정하기"
            ) {
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            }
            
            activePermissionToast = toast
            toast.show(in: view, duration: 2.0, topOffset: 10)
            return false
            
        case .notDetermined:
            // 💡 아직 권한을 묻기 전이거나 '한 번만 허용' 세션이 만료된 상태입니다.
            // 이때는 토스트를 띄우지 않고 false만 반환하여 시스템 팝업이 뜰 기회를 줍니다.
            return false
            
        @unknown default:
            return false
        }
    }
}


extension BaseViewController {
    
    /// 권한을 확인하고, 없으면 요청하거나(최초) 알럿/토스트를 띄웁니다.
    /// - Parameter completion: 권한이 허용되었을 때 실행할 클로저 (등록 진행)
    func ensureAlarmPermissionAndExecute(completion: @escaping () -> Void) {
        let center = UNUserNotificationCenter.current()
        
        center.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                switch settings.authorizationStatus {
                case .authorized, .provisional:
                    // 1. 이미 허용되어 있음 -> 바로 콜백 실행
                    self.activeAlarmPermissionToast?.hideImmediately()
                    self.activeAlarmPermissionToast = nil
                    completion()
                    
                case .notDetermined:
                    // 2. 최초 요청 -> 권한 묻기 시스템 팝업 띄움
                    center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                        DispatchQueue.main.async {
                            if granted {
                                // 사용자가 '허용'을 누름 -> 콜백 실행
                                completion()
                            } else {
                                // 사용자가 '거절'을 누름 -> 최초 1회 Alert 띄우기
                                self.handleAlarmPermissionDenied()
                            }
                        }
                    }
                    
                case .denied, .ephemeral:
                    // 3. 이미 거절된 상태 -> 토스트 띄우기
                    self.showAlarmPermissionToast()
                    
                @unknown default:
                    break
                }
            }
        }
    }
    
    // MARK: - 거절/토스트 처리 헬퍼 함수
    
    private func handleAlarmPermissionDenied() {
        let hasShownAlert = UserDefaults.standard.bool(forKey: "hasShownAlarmDeniedAlert")
        
        if !hasShownAlert {
            // 최초 거절 시 1회 Alert
            UserDefaults.standard.set(true, forKey: "hasShownAlarmDeniedAlert")
            
            let alert = UIAlertController(
                title: nil,
                message: "알림을 허용하지 않으면\n막차 알람이 울리지 못해요.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "닫기", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "설정하기", style: .default) { _ in
                guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                UIApplication.shared.open(url)
            })
            present(alert, animated: true)
        } else {
            // 그 이후에는 토스트
            showAlarmPermissionToast()
        }
    }
    
    private func showAlarmPermissionToast() {
        activeAlarmPermissionToast?.hideImmediately()
        
        let toast = AtchaActionToast(
            message: "알람 권한을 허용해 주세요",
            actionTitle: "설정하기"
        ) { [weak self] in
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
            self?.activeAlarmPermissionToast = nil
        }
        
        activeAlarmPermissionToast = toast
        toast.show(in: view, duration: 5.0, topOffset: 10)
    }
}
