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

protocol MapViewControllerDelegate: AnyObject {
    /// 위치 이동 감지 시 호출
    func mapViewController(_ controller: MapViewController,
                           didUpdateLocation coordinate: CLLocationCoordinate2D)

    /// 지도 탭으로 위치 선택 시 호출
    func mapViewController(_ controller: MapViewController,
                           didSelectLocation coordinate: CLLocationCoordinate2D)
    
//    func mapViewController(_ controller: MapViewController, didRequestCenterCoordinate coordinate: CLLocationCoordinate2D)
}

final class MapViewController: BaseViewController<MapViewModel> {
    private var mapView: TMapView = TMapView(frame: UIScreen.main.bounds)
    
    weak var delegate: MapViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupMapView()
        setupMarkerView()
        
        bindViewModel()
        viewModel.requestPermissionAndStartTracking()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        mapView.vsmMapView?.viewWillDisappear()
    }
    
    private func setupMapView() {
        view.addSubview(mapView)
        
        mapView.setApiKey(Bundle.main.tMapKey)
        mapView.delegate = self
        mapView.isShowCompass = false
        
        
    }

    
    private func setupMarkerView(coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.62965537, longitude: 127.04519683)) {
        
        mapView.setCenter(coordinate)
        let marker = TMapMarker(position: coordinate)
        marker.title = "현재 위치"
        marker.icon = UIImage.currentLocationMark // ← 이미지 꼭 존재해야 함
        marker.map = mapView
    }

    private func bindViewModel() {
        viewModel.$currentLocation
            .receive(on: DispatchQueue.main)
            .compactMap { $0?.coordinate }
            .sink { [weak self] location in
                guard let self else { return }
                delegate?.mapViewController(self, didUpdateLocation: location)
            }
            .store(in: &cancellables)
    }
}

extension MapViewController: TMapViewDelegate {
    func mapViewDidFinishLoadingMap() {
        mapView.setMapType(.Night)
        mapView.setZoom(50)
        
        setupMarkerView()
    }
    
    func mapView (_ mapView:TMapView, singleTapOnMapWithoutTMapShape position: CLLocationCoordinate2D) {
        delegate?.mapViewController(self, didSelectLocation: position)
        setupMarkerView(coordinate: position)
    }
}

extension MapViewController: TmapViewLocationDelegate, CLLocationManagerDelegate {
    func didUpdateHeading(_ heading: CLHeading) {
        
        guard let position = viewModel.currentLocation?.coordinate else { return }
        let marker = TMapMarker(position: position)
        
        marker.position = position
        marker.map = nil
        marker.icon = UIImage.currentLocationMark.rotated(by: CGFloat(heading.trueHeading))
        marker.map = self.mapView
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        print("newHeading : \(newHeading)")
    }
}

// TODO: - 길찾기 경로 추가 예정
extension MapViewController {
    
}

// 마커 추가 (가운데로 이동) 기존 마커 제거
// 기본 디폴트 이미지들 숨기기 처리
// 헤딩 처리하기
// 설정 이미지 표시하기
// 해당 ViewController 생성, 최초 값 주입해서 넣기 (UserDefaults)




