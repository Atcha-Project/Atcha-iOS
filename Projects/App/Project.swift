import ProjectDescription
import ProjectDescriptionHelpers

let appTarget = Target.target(
    name: "AtchaV2",
    destinations: Atcha.destinations,
    product: .app,
    bundleId: Atcha.v2BundleID,
    deploymentTargets: Atcha.v2Deployment,
    infoPlist: .extendingDefault(with: [
        "CFBundleDisplayName": "앗차",
        "UILaunchScreen": [:],
        "NSAlarmKitUsageDescription": "막차 시간에 맞춰 알람을 울리기 위해 권한이 필요합니다.",
        "NSLocationWhenInUseUsageDescription": "현재 위치를 출발지로 사용하기 위해 위치 정보 접근 권한이 필요합니다.",
        // 사일런트 푸시(content-available=1) 수신용 — 사용자 알림 권한과 무관.
        "UIBackgroundModes": ["remote-notification"],
        "NSSupportsLiveActivities": true,
        "UIApplicationSceneManifest": [
            "UIApplicationSupportsMultipleScenes": false,
            "UISceneConfigurations": [
                "UIWindowSceneSessionRoleApplication": [
                    [
                        "UISceneConfigurationName": "Default",
                        "UISceneDelegateClassName": "$(PRODUCT_MODULE_NAME).SceneDelegate",
                    ],
                ],
            ],
        ],
        "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
        "ITSAppUsesNonExemptEncryption": false,
    ]),
    sources: ["Sources/**"],
    resources: ["Resources/**"],
    // APNs 등록에 필수 (없으면 didFailToRegister: "aps-environment 없음").
    // 배포 서명 시 프로비저닝이 production으로 치환한다.
    entitlements: .dictionary([
        "aps-environment": "development",
        // 폴백 노티의 .timeSensitive interruptionLevel용(Phase 15) — 집중 모드 관통.
        "com.apple.developer.usernotifications.time-sensitive": true,
    ]),
    dependencies: [
        .target(name: "AtchaWidget"),
        .project(target: "HomeFeature", path: "../Feature/Home"),
        .project(target: "HomeFeatureInterface", path: "../Feature/Home"),
        .project(target: "SearchFeature", path: "../Feature/Search"),
        .project(target: "SearchFeatureInterface", path: "../Feature/Search"),
        .project(target: "Domain", path: "../Domain"),
        .project(target: "AtchaData", path: "../Data"),
        .project(target: "CoreNetwork", path: "../Core/Network"),
        .project(target: "CoreStorage", path: "../Core/Storage"),
        .project(target: "CoreAuth", path: "../Core/Auth"),
        .project(target: "CoreAlarm", path: "../Core/Alarm"),
        .project(target: "CoreCoordinator", path: "../Core/Coordinator"),
        .project(target: "CoreLiveActivity", path: "../Core/LiveActivity"),
        .project(target: "DesignSystem", path: "../DesignSystem"),
        .external(name: "FirebaseCore"),
        .external(name: "FirebaseCrashlytics"),
        .external(name: "FirebaseMessaging"),
    ],
    settings: .atchaV2(base: [
        // Firebase static libraries under XcodeProj-based integration need
        // -ObjC so their ObjC categories are loaded (Xcode's native SPM
        // integration adds the equivalent implicitly).
        "OTHER_LDFLAGS": ["$(inherited)", "-ObjC"],
    ])
)

// App 타겟 테스트 타겟(Phase 16) — host app 방식: 앱 타겟 의존으로 internal 심볼을
// @testable 접근한다. AlarmSyncService(판정·폴백·만료 분기)의 회귀 방어가 목적.
let testTarget = Target.target(
    name: "AtchaV2Tests",
    destinations: Atcha.destinations,
    product: .unitTests,
    bundleId: "\(Atcha.v2BundleID).tests",
    deploymentTargets: Atcha.v2Deployment,
    infoPlist: .default,
    sources: ["Tests/**"],
    dependencies: [.target(name: "AtchaV2")],
    settings: .atchaV2()
)

let widgetTarget = Target.widgetExtension(
    name: "AtchaWidget",
    bundleId: "\(Atcha.v2BundleID).widget",
    sources: ["Widget/Sources/**"],
    entitlements: .dictionary(["aps-environment": "development"]),
    dependencies: [
        .project(target: "CoreLiveActivity", path: "../Core/LiveActivity"),
        .project(target: "DesignSystem", path: "../DesignSystem"),
    ]
)

let project = Project(
    name: "AtchaV2",
    options: .options(
        automaticSchemesOptions: .disabled,
        defaultKnownRegions: Atcha.knownRegions,
        developmentRegion: Atcha.developmentRegion
    ),
    settings: .atchaV2(),
    targets: [appTarget, widgetTarget, testTarget],
    schemes: [
        .scheme(
            name: "AtchaV2",
            shared: true,
            buildAction: .buildAction(targets: ["AtchaV2"]),
            testAction: .targets(["AtchaV2Tests"]),
            runAction: .runAction(configuration: "Debug", executable: "AtchaV2"),
            archiveAction: .archiveAction(configuration: "Debug"),
            profileAction: .profileAction(configuration: "Debug", executable: "AtchaV2"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        ),
        .scheme(
            name: "AtchaV2-Stage",
            shared: true,
            buildAction: .buildAction(targets: ["AtchaV2"]),
            runAction: .runAction(configuration: "Stage", executable: "AtchaV2"),
            archiveAction: .archiveAction(configuration: "Stage")
        ),
        .scheme(
            name: "AtchaV2-Live",
            shared: true,
            buildAction: .buildAction(targets: ["AtchaV2"]),
            runAction: .runAction(configuration: "Release", executable: "AtchaV2"),
            archiveAction: .archiveAction(configuration: "Release")
        ),
    ]
)
