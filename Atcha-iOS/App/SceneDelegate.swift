//
//  SceneDelegate.swift
//  Atcha-iOS
//
//  Created by wodnd on 6/15/25.
//

import UIKit
import KakaoSDKAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
    var appFlowCoordinator: AppFlowCoordinator?
    let diContainer = AppDIContainer.shared
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        let window = UIWindow(windowScene: windowScene)
        var launchType: LaunchType = .main
        
        appFlowCoordinator = AppFlowCoordinator(window: window, container: diContainer)
        appFlowCoordinator?.startApp(launchType: launchType)
        
        self.window = window
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        if let url = URLContexts.first?.url {
            if (AuthApi.isKakaoTalkLoginUrl(url)) {
                _ = AuthController.handleOpenUrl(url: url)
            }
        }
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
        // This occurs shortly after the scene enters the background, or when its session is discarded.
        // Release any resources associated with this scene that can be re-created the next time the scene connects.
        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
        
        let wrapper = UserDefaultsWrapper.shared
        
        if let _: LegInfo = wrapper.object(forKey: UserDefaultsWrapper.Key.legInfo.rawValue, of: LegInfo.self) {
            let didFire = wrapper.bool(forKey: UserDefaultsWrapper.Key.departureAlarmDidFire.rawValue) ?? false
            
            if didFire {
                AlarmManager.shared.sendBackgroundPush(
                    title: "앗차를 다시 켜주세요",
                    body: "목적지까지 안내할 수 있도록 앱을 다시 실행해 주세요"
                )
            } else {
                AlarmManager.shared.sendBackgroundPush(
                    title: "앗차를 다시 켜주세요",
                    body: "제 시간에 출발 시간을 알려드릴 수 있도록 앱을 다시 실행해 주세요."
                )
            }
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
        
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from an active state to an inactive state.
        // This may occur due to temporary interruptions (ex. an incoming phone call).
        
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
        // Use this method to undo the changes made on entering the background.
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
        // Use this method to save data, release shared resources, and store enough scene-specific state information
        // to restore the scene back to its current state.
        
    }
}

