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
    dependencies: [
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

let project = Project(
    name: "AtchaV2",
    options: .options(
        automaticSchemesOptions: .disabled,
        defaultKnownRegions: Atcha.knownRegions,
        developmentRegion: Atcha.developmentRegion
    ),
    settings: .atchaV2(),
    targets: [appTarget],
    schemes: [
        .scheme(
            name: "AtchaV2",
            shared: true,
            buildAction: .buildAction(targets: ["AtchaV2"]),
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
