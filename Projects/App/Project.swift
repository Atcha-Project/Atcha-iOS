import ProjectDescription
import ProjectDescriptionHelpers

// 카카오 네이티브 앱 키 — xcconfig 금지 규약(AtchaV2) 하에서 env(TUIST_KAKAO_APP_KEY)로
// 주입한다(mise [env] 또는 CI secret). 미주입이면 빈 문자열: generate/빌드는 통과하고
// 카카오 로그인만 런타임 비활성(providerUnavailable → 실패 토스트)이다.
let kakaoAppKey = Environment.kakaoAppKey.getString(default: "")

var appInfoPlist: [String: Plist.Value] = [
    "CFBundleDisplayName": "앗차",
    "UILaunchStoryboardName": "LaunchScreen",
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
    // 카카오톡 로그인 앱 전환 조회용(레거시 Info.plist 실측).
    "LSApplicationQueriesSchemes": ["kakaokompassauth", "kakaolink"],
    // 런타임(KakaoConfig)이 읽는 키 — 빈 값이면 KakaoSDK.initSDK를 건너뛴다.
    "KAKAO_APP_KEY": .string(kakaoAppKey),
]
// 키 미주입 시 무의미한 `kakao` 빈 스킴이 등록되지 않도록 조건 분기.
if !kakaoAppKey.isEmpty {
    appInfoPlist["CFBundleURLTypes"] = [
        ["CFBundleURLSchemes": ["kakao\(kakaoAppKey)"]],
    ]
}

let appTarget = Target.target(
    name: "AtchaV2",
    destinations: Atcha.destinations,
    product: .app,
    bundleId: Atcha.v2BundleID,
    deploymentTargets: Atcha.v2Deployment,
    infoPlist: .extendingDefault(with: appInfoPlist),
    sources: ["Sources/**"],
    resources: ["Resources/**"],
    // APNs 등록에 필수 (없으면 didFailToRegister: "aps-environment 없음").
    // 배포 서명 시 프로비저닝이 production으로 치환한다.
    entitlements: .dictionary([
        "aps-environment": "development",
        // 폴백 노티의 .timeSensitive interruptionLevel용(Phase 15) — 집중 모드 관통.
        "com.apple.developer.usernotifications.time-sensitive": true,
        // 소셜 로그인(Apple) — App ID capability 활성 + 프로비저닝 갱신 필요(콘솔 작업).
        "com.apple.developer.applesignin": ["Default"],
    ]),
    dependencies: [
        .target(name: "AtchaWidget"),
        .project(target: "AuthFeature", path: "../Feature/Auth"),
        .project(target: "AuthFeatureInterface", path: "../Feature/Auth"),
        .project(target: "HomeFeature", path: "../Feature/Home"),
        .project(target: "HomeFeatureInterface", path: "../Feature/Home"),
        .project(target: "SearchFeature", path: "../Feature/Search"),
        .project(target: "SearchFeatureInterface", path: "../Feature/Search"),
        .project(target: "SettingsFeature", path: "../Feature/Settings"),
        .project(target: "SettingsFeatureInterface", path: "../Feature/Settings"),
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
        // 소셜 SDK는 앱 타겟에서만 링크(내부 모듈 static framework 중복 심볼 방지 규약)
        // — import 지점은 SocialLoginAdapter·AppDelegate·SceneDelegate뿐.
        .external(name: "KakaoSDKCommon"),
        .external(name: "KakaoSDKAuth"),
        .external(name: "KakaoSDKUser"),
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
