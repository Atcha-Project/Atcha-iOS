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
    private let loactionButton: UIButton = UIButton()
    private let exitButton: UIButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
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
                         loactionButton)
        mapContainerView.delegate = self
        flagImageView.image = UIImage.settingLocationMark
    }
    
    private func bindViewModel() {
        bottomView.actionPublisher
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                navigationController?.popViewController(animated: true)
            }
            .store(in: &cancellables)
        
        viewModel.$address
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] address in
                guard let self else { return }
                bottomView.setupaddressLabel(address: address)
            }
            .store(in: &cancellables)
        
        viewModel.$buildingName
            .removeDuplicates()
            .receive(on: RunLoop.main)
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
        
        flagImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalTo(mapContainerView.snp.centerY)
            make.height.equalTo(65)
            make.width.equalTo(48)
        }
        
        bottomView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.bottom.equalToSuperview()
            make.height.equalTo(210)
        }
    }
}

// MARK: - Delegate
extension HomeFindViewController {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocationSubject.send(coordinate)
    }
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {
        viewModel.currentLocationSubject.send(coordinate)
    }
}

