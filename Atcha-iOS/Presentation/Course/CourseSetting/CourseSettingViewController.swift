//
//  CourseSettingViewController.swift
//  Atcha-iOS
//
//  Created by wodnd on 7/18/25.
//

import UIKit
import SnapKit
import CoreLocation
import TMapSDK

final class CourseSettingViewController: BaseViewController<CourseSettingViewModel>, TMapWrapperDelegate {
    
    private let mapContainerView: TMapContainerView = TMapContainerView()
    private let settingBottomView: OriginSettingBottomView = OriginSettingBottomView()
    private let flagImageView: UIImageView = UIImageView()
    private let currentLoactionButton: UIButton = UIButton()
    
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
            currentLoactionButton,
            settingBottomView
        )
        
        mapContainerView.delegate = self
        flagImageView.image = UIImage.settingLocationMark
        flagImageView.isUserInteractionEnabled = false
        configureButton(currentLoactionButton, imageName: "mylocation-filled", action: #selector(didTapLocationButton))
    }
    
    private func configureButton(_ button: UIButton, imageName: String, action: Selector) {
        button.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    private func bindView() {
        settingBottomView.actionPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .settingTapped:
                    viewModel.userDidTapSettingButton()
                }
            }
            .store(in: &cancellables)
        
        viewModel.$locationInfo
            .receive(on: RunLoop.main)
            .sink { [weak self] location in
                guard let self else { return }
                settingBottomView.setupLocationTitle(location.name, location.address)
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
    }
    
    private func setupAutoLayout() {
        flagImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(mapContainerView.snp.centerY)
            make.height.equalTo(63)
            make.width.equalTo(48)
        }
        
        currentLoactionButton.snp.makeConstraints { make in
            make.bottom.equalTo(settingBottomView.snp.top).inset(-16)
            make.trailing.equalToSuperview().inset(16)
            make.size.equalTo(40)
        }
        
        settingBottomView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(170)
        }
        
        mapContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalToSuperview()
            make.bottom.equalTo(settingBottomView.snp.top).inset(30)
        }
    }
}

extension CourseSettingViewController {
    func didFinishLoadingMap(_ mapView: TMapWrapper) {
        mapView.mapView.isZoomEnable = true
        viewModel.setupInitialLocation()
    }
    
    @objc private func didTapLocationButton() {
        viewModel.setupLocation()
    }
}

// MARK: - Delegate
extension CourseSettingViewController {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocation = coordinate
    }
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocation = coordinate
    }
}
