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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupAutoLayout()
        bindView()
        viewModel.setLoading(true)
    }
    
    private func setupUI() {
        let bottomSheet = BottomSheetView(frame: CGRect(
            x: 0,
            y: view.frame.height * (1 - 0.45), // 최초 45% 높이로 진입
            width: view.frame.width,
            height: view.frame.height * 0.8   // 최대 90%까지 확장 가능
        ))
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
            make.verticalEdges.equalToSuperview()
        }
        
        backButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(12)
            make.width.height.equalTo(36)
        }
    }
    
    private func bindView() {
    }
    
    @objc private func didTapClose() {
        navigationController?.popViewController(animated: true)
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

final class BottomSheetView: UIView {
    private let minHeightRatio: CGFloat = 0.45
    private let maxHeightRatio: CGFloat = 0.78
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var currentState: SheetState = .collapsed
    
    enum SheetState {
        case expanded
        case collapsed
    }
    
    private var parentViewHeight: CGFloat {
        return superview?.frame.height ?? UIScreen.main.bounds.height
    }
    
    private var collapsedHeight: CGFloat {
        return parentViewHeight * minHeightRatio
    }
    
    private var expandedHeight: CGFloat {
        return parentViewHeight * maxHeightRatio
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        setupPanGesture()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
        setupPanGesture()
    }
    
    private func setupView() {
        backgroundColor = .gray950
        layer.cornerRadius = 20
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    private func setupPanGesture() {
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
        guard let superview = self.superview else { return }
        let translation = recognizer.translation(in: superview)
        
        switch recognizer.state {
        case .changed:
            let newY = max(parentViewHeight - expandedHeight,
                           min(self.frame.origin.y + translation.y, parentViewHeight - collapsedHeight))
            self.frame.origin.y = newY
            recognizer.setTranslation(.zero, in: superview)
            
        case .ended:
            let velocity = recognizer.velocity(in: superview).y
            let shouldExpand = velocity < 0
            animateTransition(shouldExpand: shouldExpand)
            
        default:
            break
        }
    }
    
    private func animateTransition(shouldExpand: Bool) {
        guard let superview = self.superview else { return }
        
        let targetY = shouldExpand ? (parentViewHeight - expandedHeight) : (parentViewHeight - collapsedHeight)
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 1.0, options: [.curveEaseInOut], animations: {
            self.frame.origin.y = targetY
        }, completion: { _ in
            self.currentState = shouldExpand ? .expanded : .collapsed
        })
    }
}
