//
//  MainViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import UIKit
import Foundation
import CoreLocation
import TMapSDK
import VSMSDK

final class MainViewController: BaseViewController<MainViewModel>,
                                TMapWrapperDelegate {
    
    private let mapContainerView: TMapContainerView = TMapContainerView()
    private let lastTrainView: LastTrainSearchBottomView = LastTrainSearchBottomView()
    private let lastTrainDepartView: LastTrainDepartBottomView = LastTrainDepartBottomView()
    private let flagImageView: UIImageView = UIImageView()
    private let myPageButton: UIButton = UIButton()
    private let loactionButton: UIButton = UIButton()
    private let atchaImageView: UIImageView = UIImageView()
    private let ballonView: AtchaBallon = AtchaBallon()
    
    private var firstAddress: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        bindView()
    }
    
    private func setupUI() {
        view.addSubViews(
            mapContainerView,
            flagImageView,
            atchaImageView,
            lastTrainView,
            myPageButton,
            loactionButton,
            lastTrainDepartView,
            ballonView
        )
        
        mapContainerView.delegate = self
        
        configureButton(myPageButton, imageName: "mypage-filled", action: #selector(didTapMyPageButton))
        configureButton(loactionButton, imageName: "mylocation-filled", action: #selector(didTapLocationButton))
        flagImageView.image = UIImage.settingLocationMark
        atchaImageView.image = UIImage.atcha
        ballonView.setupTitle(bottomMessage: "여기서 막차 놓치면 택시비")
    }
    
    private func configureButton(_ button: UIButton, imageName: String, action: Selector) {
        button.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    private func bindView() {
        lastTrainView.actionPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .currentTapped:
                    viewModel.handleRoute(route: .changeCourse)
                case .searchTapped:
                    viewModel.handleRoute(route: .courseSearch(startLat: "",
                                                               startLon: "",
                                                               startAddress: ""))
                }
            }
            .store(in: &cancellables)
        
        viewModel.$address
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] address in
                guard let self else { return }
                
                if firstAddress == nil {
                    firstAddress = address
                }
                
                if address == firstAddress {
                    lastTrainView.setupCurrentLocationTitle("현위치 : \(address)")
                } else {
                    lastTrainView.setupCurrentLocationTitle(address)
                }
            }
            .store(in: &cancellables)
        
        viewModel.$currentLocation
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self else { return }
                mapContainerView.setupCenter(location: location)
            }
            .store(in: &cancellables)
        
        // 선택한 location
        viewModel.$selectedLocation
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                guard let self else { return }
                mapContainerView.updateUserMarker(location: location)
            }
            .store(in: &cancellables)
        
        viewModel.$taxiFare
            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] fare in
                guard let self else { return }
                let fareStr = String(format: "%.0f", fare)
                ballonView.setupTitle(bottomMessage: "여기서 막차 놓치면 택시비 : 약 \(fareStr)원")
            }
            .store(in: &cancellables)
    }
    
    private func setupAutoLayout() {
        flagImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(mapContainerView.snp.centerY).offset(-63)
            make.height.equalTo(63)
            make.width.equalTo(48)
        }
        lastTrainView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
//            make.height.equalTo(224)
        }
//        lastTrainDepartView.snp.makeConstraints { make in
//            make.horizontalEdges.equalToSuperview()
//            make.bottom.equalToSuperview()
//        }
        myPageButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
        loactionButton.snp.makeConstraints { make in
            make.bottom.equalTo(lastTrainView.snp.top).inset(-16)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(40)
        }
        ballonView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(8)
            make.bottom.equalTo(lastTrainView.snp.top).inset(-45)
        }
        atchaImageView.snp.makeConstraints { make in
            make.width.height.equalTo(64)
            make.leading.equalToSuperview().inset(8)
            make.bottom.equalTo(lastTrainView.snp.top).inset(24)
        }
        mapContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(lastTrainView.snp.top).inset(30)
        }
    }
}

extension MainViewController {
    func didFinishLoadingMap(_ mapView: TMapWrapper) {
        viewModel.setupLocation()
        
        let passShape = "127.025347,37.637628 127.025619,37.637881 127.026825,37.638997 127.027403,37.639531 127.028386,37.638886 127.031444,37.636886 127.032253,37.636358 127.033556,37.635517 127.033622,37.635489 127.033839,37.635386 127.034283,37.635272 127.034531,37.635169 127.035389,37.634658 127.035700,37.634483 127.035917,37.634406 127.036078,37.634367 127.036086,37.634367 127.036769,37.634194 127.037456,37.634025 127.037678,37.633950 127.037931,37.633797 127.038625,37.632883 127.038728,37.632750 127.039133,37.632214 127.039147,37.632194 127.039272,37.632053 127.039544,37.631814 127.040014,37.631500 127.040017,37.631497"
        mapContainerView.addTrafficLine(passShape: passShape)
    }
    
    @objc private func didTapMyPageButton() {
        viewModel.handleRoute(route: .myPage)
    }
    
    @objc private func didTapLocationButton() {
        viewModel.setupLocation()
    }
}

// MARK: - Delegate
extension MainViewController {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocation = coordinate
    }
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocation = coordinate
    }
}
