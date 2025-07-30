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
    private var activityIndicator: UIActivityIndicatorView?
    private lazy var bottomSheet: DetailRouteInfoBottomView = DetailRouteInfoBottomView(frame: CGRect(
        x: 0,
        y: view.frame.height * (1 - 0.45),
        width: view.frame.width,
        height: view.frame.height * 0.8
    ))
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.setLoading(true)
        setupUI()
        setupAutoLayout()
        bindView()
    }
    
    private func setupUI() {
        view.addSubViews(mapContainerView, bottomSheet, backButton)
        mapContainerView.delegate = self
        
        backButton.setImage(UIImage.chevronLeft, for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = .black
        backButton.clipsToBounds = true
        backButton.setCornerRadius(18)
        backButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
    }
    
    private func setupAutoLayout() {
        mapContainerView.snp.makeConstraints { make in
            make.horizontalEdges.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalToSuperview().multipliedBy(0.65)
        }
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.width.height.equalTo(36)
        }
    }
    
    private func bindView() {
        viewModel.$legtPathInfo
            .filter { !$0.isEmpty }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.addRouteLine(infos: $0) }
            .store(in: &cancellables)
    }
    
    @objc private func didTapClose() {
        navigationController?.popViewController(animated: true)
    }
    
    private func addRouteLine(infos: [LegPathInfo]) {
        var shapeStrings: [String] = []
        var colors: [UIColor] = []
        var images: [UIImage] = []
        var allCoordinates: [CLLocationCoordinate2D] = []  // ✅ 전체 좌표 수집

        infos.forEach { info in
            switch info.mode {
            case .bus, .subway:
                if let shape = info.passShape, !shape.isEmpty {
                    shapeStrings.append(shape)
                    colors.append(info.mode?.getColor(for: info.type ?? "") ?? .magenta)
                    if let icon = info.mode?.icon {
                        images.append(icon)
                    }
                    allCoordinates.append(contentsOf: convertShapeToCoords(shape))
                }

            case .walk:
                let walkShapes = info.step?.compactMap { $0.linestring }.filter { !$0.isEmpty } ?? []
                let merged = walkShapes.joined(separator: " ")
                if !merged.isEmpty {
                    shapeStrings.append(merged)
                    colors.append(.gray200)
                    if let icon = info.mode?.icon {
                        images.append(icon)
                    }
                    allCoordinates.append(contentsOf: convertShapeToCoords(merged))
                }

            default: break
            }
        }

        for (index, (shape, color, image)) in zip3(shapeStrings, colors, images).enumerated() {
            let isFirst = index == 0
            let isLast = index == shapeStrings.count - 1
            mapContainerView.addTrafficLine(passShape: shape, color: color, markerImage: image, isFirst: isFirst, isLast: isLast)
        }
        
        mapContainerView.adjustMapToFit(coordinates: allCoordinates)
    }
    
    private func convertShapeToCoords(_ shape: String) -> [CLLocationCoordinate2D] {
        shape.split(separator: " ").compactMap { pair in
            let parts = pair.split(separator: ",")
            guard parts.count == 2,
                  let lon = Double(parts[0]),
                  let lat = Double(parts[1]) else { return nil }
            return CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }
    
    private func zip3<A, B, C>(_ a: [A], _ b: [B], _ c: [C]) -> [(A, B, C)] {
        let count = min(a.count, b.count, c.count)
        return (0..<count).map { (a[$0], b[$0], c[$0]) }
    }
    
    deinit {
        mapContainerView.deinitMapView()
    }
}

extension DetailRouteViewController {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {}
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {}
    
    func didFinishLoadingMap(_ mapView: TMapWrapper) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.hideLoading()
        }
    }
}
