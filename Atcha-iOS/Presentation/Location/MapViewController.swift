//
//  MapViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 6/30/25.
//

import UIKit
import Foundation
import CoreLocation
import TMapSDK

final class MapViewController: BaseViewController<MapViewModel>,
                               TMapWrapperDelegate {
    
    private let mapContainerView: TMapContainerView = TMapContainerView()
    private let lastTrainView: LastTrainSearchBottomView = LastTrainSearchBottomView()
    private let flagImageView: UIImageView = UIImageView()
    private let myPageButton: UIButton = UIButton()
    private let loactionButton: UIButton = UIButton()
    private let atchaImageView: UIImageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        bindView()
        
        viewModel.bindView()
        viewModel.requestPermissionAndStartTracking()
    }
    
    private func setupUI() {
        view.addSubViews(
            mapContainerView,
            flagImageView,
            atchaImageView,
            lastTrainView,
            myPageButton,
            loactionButton
        )

        mapContainerView.delegate = self

        configureButton(myPageButton, imageName: "mypage-filled", action: #selector(didTapMyPageButton))
        configureButton(loactionButton, imageName: "mylocation-filled", action: #selector(didTapLocationButton))
        flagImageView.image = UIImage.settingLocationMark
        atchaImageView.image = UIImage.atcha
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
                    viewModel.routeHandler?(.changeCourse)
                case .searchTapped:
                    viewModel.routeHandler?(.courseSearch)
                }
            }
            .store(in: &cancellables)
    }
    
    private func setupAutoLayout() {
        flagImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(mapContainerView.snp.centerY)
            make.height.equalTo(65)
            make.width.equalTo(48)
        }
        lastTrainView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(224)
        }
        myPageButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(36)
        }
        loactionButton.snp.makeConstraints { make in
            make.bottom.equalTo(lastTrainView.snp.top).inset(-16)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(36)
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

extension MapViewController {
    @objc private func didTapMyPageButton() {
        print("마이페이지 버튼 눌림")
        viewModel.routeHandler?(.myPage)
    }
    
    @objc private func didTapLocationButton() {
        print("내 위치 버튼 눌림")
    }
}

// MARK: - Delegate
extension MapViewController {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {
        print("didUpdateLocation : \(coordinate.latitude)")
        print("didUpdateLocation : \(coordinate.longitude)")
    }
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {
        print("didUpdateLocation : \(coordinate.latitude)")
        print("didUpdateLocation : \(coordinate.longitude)")
    }
}
