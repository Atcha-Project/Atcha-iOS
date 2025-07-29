//
//  DetailRouteViewController.swift
//  Atcha-iOS
//
//  Created by geonhui Yu on 7/29/25.
//

import UIKit
import CoreLocation
import TMapSDK
import VSMSDK

final class DetailRouteViewController: BaseViewController<DetailRouteViewModel>,
                                       TMapWrapperDelegate {
    private let mapContainerView: TMapContainerView = TMapContainerView()
    private let loactionButton: UIButton = UIButton()
    private let backButton: UIButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        bindView()
    }
    
    private func setupUI() {
        view.addSubViews(mapContainerView, backButton)
        mapContainerView.delegate = self
        
        backButton.setImage(UIImage.chevronLeft, for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = .black
        backButton.clipsToBounds = true
        backButton.setCornerRadius(18)
    }
    
    private func setupAutoLayout() {
        mapContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.verticalEdges.equalToSuperview()
        }
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(12)
            make.width.height.equalTo(36)
        }
    }
    
    private func bindView() {
        
    }
}

extension DetailRouteViewController {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {}
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {}
    
    func didFinishLoadingMap(_ mapView: TMapWrapper) {
        
    }
}
