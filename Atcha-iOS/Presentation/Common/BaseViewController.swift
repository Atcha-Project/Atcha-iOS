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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        navigationController?.interactivePopGestureRecognizer?.delegate = self as? any UIGestureRecognizerDelegate
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
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
        viewModel.$isLoading
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                guard let self else { return }
                if isLoading {
                    showLoading()
                } else {
                    hideLoading()
                }
            }
            .store(in: &cancellables)
        
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
        loading.startOnce()
        loading.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(loading)
        
        NSLayoutConstraint.activate([
            loading.topAnchor.constraint(equalTo: view.topAnchor),
            loading.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loading.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loading.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        loadingView?.layer.zPosition = 100
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self, weak loading] in
            loading?.stop()
            loading?.removeFromSuperview()

            if self?.loadingView === loading {
                self?.loadingView = nil
            }
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
}

extension BaseViewController {
    func ensureLocationPermissionOrShowToast() -> Bool {
        let status = CLLocationManager.authorizationStatus()

        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            activePermissionToast?.hideImmediately()
            activePermissionToast = nil
            return true

        case .denied, .restricted, .notDetermined:
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

            return true
        @unknown default:
            return true
        }
    }
}

extension BaseViewController {
    func ensureAlarmPermissionOrShowToast() -> Bool {
        let center = UNUserNotificationCenter.current()
        var isAuthorized = false
        let semaphore = DispatchSemaphore(value: 0)

        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                isAuthorized = true
            default:
                isAuthorized = false
            }
            semaphore.signal()
        }

        semaphore.wait()

        if isAuthorized {
            activeAlarmPermissionToast?.hideImmediately()
            activeAlarmPermissionToast = nil
            return true
        }

        // 권한 없으면: 토스트는 띄우되 진행은 막지 않음
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

        return true
    }
}
