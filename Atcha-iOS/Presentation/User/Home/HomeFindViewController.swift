//
//  HomeFindViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/8/25.
//

import UIKit
import Foundation
import CoreLocation
import TMapSDK

final class HomeFindViewController: BaseViewController<HomeFindViewModel>,
                                    TMapWrapperDelegate {
    private let mapContainerView: TMapContainerView = TMapContainerView()
    private let bottomView: HomeRegisterBottomView = HomeRegisterBottomView()
    private let flagImageView: UIImageView = UIImageView()
    private let backButton: UIButton = UIButton()
    private let loactionButton: UIButton = UIButton()
    private let exitButton: UIButton = UIButton()
    
    var routeHandler: ((HomeRouter) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        setupBackButton()
        bindViewModel()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        mapContainerView.deinitMapView()
    }
    
    private func setupUI() {
        view.addSubViews(mapContainerView,
                         flagImageView,
                         bottomView,
                         loactionButton,
                         backButton)
        
        mapContainerView.delegate = self
        flagImageView.image = UIImage.settingLocationMark
        backButton.setImage(UIImage.chevronLeft, for: .normal)
        backButton.tintColor = .gray300
        
        configureButton(loactionButton,
                        imageName: "mylocation-filled",
                        action: #selector(didTapLocationButton))
    }
    
    private func bindViewModel() {
        bottomView.actionPublisher
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                viewModel.saveCurrentLoaction()
                navigationController?.popToViewController(ofType: HomeRegisterViewController.self)
            }
            .store(in: &cancellables)
        
        viewModel.$currentLocation
//            .removeDuplicates()
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] location in
                guard let self else { return }
                mapContainerView.setupCenter(location: location)
            }
            .store(in: &cancellables)
        
        viewModel.$address
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] address in
                guard let self else { return }
                bottomView.setupaddressLabel(address: address)
            }
            .store(in: &cancellables)
        
        viewModel.$buildingName
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                guard let self else { return }
                bottomView.setupNameLabel(name: name)
            }
            .store(in: &cancellables)
    }
    
    private func configureButton(_ button: UIButton, imageName: String, action: Selector) {
        button.setImage(UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal), for: .normal)
        button.contentHorizontalAlignment = .fill
        button.contentVerticalAlignment = .fill
        button.addTarget(self, action: action, for: .touchUpInside)
    }
    
    private func setupAutoLayout() {
        mapContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.verticalEdges.equalToSuperview()
        }
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).inset(18)
            make.size.equalTo(24)
        }
        
        flagImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(mapContainerView.snp.centerY)
            make.height.equalTo(65)
            make.width.equalTo(48)
        }
        
        loactionButton.snp.makeConstraints { make in
            make.bottom.equalTo(bottomView.snp.top).inset(-16)
            make.trailing.equalToSuperview().inset(16)
            make.width.height.equalTo(36)
        }
        
        bottomView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(210)
        }
    }
}

// MARK: - Action
extension HomeFindViewController {
    private func setupBackButton() {
        backButton.addTarget(self,
                             action: #selector(backButtonTapped),
                             for: .touchUpInside)
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func didTapLocationButton() {
        viewModel.setupLocation()
    }
}

// MARK: - Delegate
extension HomeFindViewController {
    func didFinishLoadingMap(_ mapView: TMapWrapper) {
        viewModel.setupLocation()
    }
    
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocation = coordinate
    }
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocation = coordinate
    }
}

