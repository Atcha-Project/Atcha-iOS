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
    private lazy var bottomSheet: DetailRouteInfoBottomView = DetailRouteInfoBottomView()
    private let relaodButton: UIButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.setLoading(true)
        setupUI()
        setupAutoLayout()
        bindView()
    }
    
    private func setupUI() {
        view.addSubViews(mapContainerView, bottomSheet, backButton, relaodButton)
        mapContainerView.delegate = self
        
        backButton.setImage(UIImage.chevronLeft, for: .normal)
        backButton.tintColor = .white
        backButton.backgroundColor = .black
        backButton.clipsToBounds = true
        backButton.setCornerRadius(18)
        backButton.addTarget(self, action: #selector(didTapClose), for: .touchUpInside)
        
        relaodButton.setImage(UIImage.refreshOutlined, for: .normal)
        relaodButton.tintColor = .white
        relaodButton.backgroundColor = .gray600
        relaodButton.clipsToBounds = true
        relaodButton.setCornerRadius(24)
        relaodButton.addTarget(self, action: #selector(didTapReload), for: .touchUpInside)
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
        bottomSheet.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(view.frame.height * 0.5)
        }
        relaodButton.snp.makeConstraints { make in
            make.size.equalTo(48)
            make.trailing.equalToSuperview().inset(16)
            make.bottom.equalTo(view.snp.bottom).inset(40)
        }
    }
    
    private func bindView() {
        viewModel.$legTrafficInfo
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] infos in self?.bottomSheet.setupRouteInfo(infos) }
            .store(in: &cancellables)
        
        viewModel.$busRealTimeInfos
            .filter { $0.count > 0 }
            .receive(on: RunLoop.main)
            .sink { [weak self] info in self?.bottomSheet.setupBusTimerLabel(info) }
            .store(in: &cancellables)
        
        viewModel.$address
            .receive(on: RunLoop.main)
            .compactMap { $0 }
            .sink { [weak self] address in self?.bottomSheet.setupStartAddress(address) }
            .store(in: &cancellables)
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
                    if let icon = info.mode?.getBorderIcon(for: info.type ?? "") {
                        images.append(icon)
                    }
                    allCoordinates.append(contentsOf: convertShapeToCoords(shape))
                }
            case .walk:
                if let steps = info.step, !steps.isEmpty {
                    let walkShapes = steps.compactMap { $0.linestring }.filter { !$0.isEmpty }
                    let merged = walkShapes.joined(separator: " ")
                    if !merged.isEmpty {
                        shapeStrings.append(merged)
                        colors.append(.gray200)
                        images.append(UIImage.routeCircleLineWalk)
                        allCoordinates.append(contentsOf: convertShapeToCoords(merged))
                    }
                } else if let shape = info.passShape, !shape.isEmpty {
                    shapeStrings.append(shape)
                    colors.append(.gray200)
                    images.append(UIImage.routeCircleLineWalk)
                    allCoordinates.append(contentsOf: convertShapeToCoords(shape))
                }
                
            default:
                break
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

// MARK: - Touch Event
extension DetailRouteViewController {
    @objc private func didTapClose() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func didTapReload() {
        viewModel.fetchInfo()
    }
}

// MARK: - Map Delegate
extension DetailRouteViewController {
    func mapView(_ mapView: TMapWrapper, didUpdateLocation coordinate: CLLocationCoordinate2D) {}
    
    func mapView(_ mapView: TMapWrapper, didSelectLocation coordinate: CLLocationCoordinate2D) {}
    
    func didFinishLoadingMap(_ mapView: TMapWrapper) {
        viewModel.$legtPathInfo
            .filter { !$0.isEmpty }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.addRouteLine(infos: $0) }
            .store(in: &cancellables)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.hideLoading()
        }
    }
}
