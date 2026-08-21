import ProjectDescription
import ProjectDescriptionHelpers

// Wraps the legacy app (sources referenced in place from //Atcha-iOS) as one
// Tuist target. Values mirror the committed Atcha-iOS.xcodeproj; scheme names
// (Atcha-Dev/Stage/Live) are preserved for fastlane/CI compatibility.

let infoPlistKeys: SettingsDictionary = [
    "GENERATE_INFOPLIST_FILE": "YES",
    "INFOPLIST_KEY_CFBundleDisplayName": "앗차",
    "INFOPLIST_KEY_LSApplicationCategoryType": "public.app-category.navigation",
    "INFOPLIST_KEY_NSLocationAlwaysAndWhenInUseUsageDescription": "정확한 막차 경로를 제공하기 위해 권한이 필요합니다",
    "INFOPLIST_KEY_NSLocationWhenInUseUsageDescription": "정확한 막차 경로를 제공하기 위해 권한이 필요합니다",
    "INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents": "YES",
    "INFOPLIST_KEY_UILaunchStoryboardName": "LaunchScreen",
    "INFOPLIST_KEY_UIMainStoryboardFile": "Main",
    "INFOPLIST_KEY_UISupportedInterfaceOrientations": "UIInterfaceOrientationPortrait",
]

let legacyBase: SettingsDictionary = infoPlistKeys.merging([
    "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
    "ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS": "YES",
    "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor",
    "CURRENT_PROJECT_VERSION": "14",
    "MARKETING_VERSION": "1.9.7",
    "SWIFT_VERSION": "5.0",
    "TARGETED_DEVICE_FAMILY": "1",
    "SWIFT_EMIT_LOC_STRINGS": "YES",
    "SUPPORTS_MACCATALYST": "NO",
    "SUPPORTS_MAC_DESIGNED_FOR_IPHONE_IPAD": "NO",
    "SUPPORTS_XR_DESIGNED_FOR_IPHONE_IPAD": "NO",
    "LD_RUNPATH_SEARCH_PATHS": ["$(inherited)", "@executable_path/Frameworks"],
    // Vendored frameworks live inside the legacy source folder.
    "FRAMEWORK_SEARCH_PATHS": ["$(inherited)", "$(SRCROOT)/../../Atcha-iOS"],
    // Firebase/Kakao static libs under XcodeProj-based integration need -ObjC
    // (native Xcode SPM added the equivalent implicitly).
    "OTHER_LDFLAGS": ["$(inherited)", "-ObjC"],
]) { _, new in new }

let debugSigning: SettingsDictionary = [
    "CODE_SIGN_STYLE": "Automatic",
    "CODE_SIGN_IDENTITY": "Apple Development",
    "DEVELOPMENT_TEAM": "23SCTLK482",
]

let distributionSigning: SettingsDictionary = [
    "CODE_SIGN_STYLE": "Manual",
    "CODE_SIGN_IDENTITY": "Apple Development",
    "CODE_SIGN_IDENTITY[sdk=iphoneos*]": "iPhone Distribution",
    "DEVELOPMENT_TEAM": "",
    "DEVELOPMENT_TEAM[sdk=iphoneos*]": "23SCTLK482",
    "PROVISIONING_PROFILE_SPECIFIER": "",
    "PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]": "match AppStore com.atcha.iOS",
]

let legacyTarget = Target.target(
    name: "Atcha-iOS",
    destinations: [.iPhone],
    product: .app,
    productName: "Atcha-iOS",
    bundleId: "com.atcha.iOS",
    deploymentTargets: Atcha.legacyDeployment,
    infoPlist: .file(path: "../../Atcha-iOS/Info.plist"),
    sources: [
        .glob("../../Atcha-iOS/**/*.swift", excluding: [
            "../../Atcha-iOS/TMapSDK.framework/**",
            "../../Atcha-iOS/VSMSDK.xcframework/**",
            // Dead file on disk — the committed pbxproj never compiled it and
            // it redeclares AppDIContainer.
            "../../Atcha-iOS/App/DIContainer/DIContainer.swift",
        ]),
    ],
    resources: [
        "../../Atcha-iOS/DesignSource/Assets.xcassets",
        "../../Atcha-iOS/DesignSource/AtchaColor/Colors.xcassets",
        "../../Atcha-iOS/DesignSource/AtchaImage/Icon.xcassets",
        "../../Atcha-iOS/DesignSource/AtchaFont/*.otf",
        "../../Atcha-iOS/DesignSource/AtchaLottie/*.json",
        "../../Atcha-iOS/Base.lproj/**",
        "../../Atcha-iOS/GoogleService-Info.plist",
        "../../Atcha-iOS/silent.mp3",
        "../../Atcha-iOS/siren.mp3",
        // NOTE: the old project also copied the four *.xcconfig files into the
        // app bundle (secrets!). Deliberately not reproduced — AppConfig.swift
        // reads Info.plist keys only.
    ],
    entitlements: "../../Atcha-iOS/Atcha-iOS.entitlements",
    dependencies: [
        .framework(path: "../../Atcha-iOS/TMapSDK.framework"),
        .xcframework(path: "../../Atcha-iOS/VSMSDK.xcframework"),
        .external(name: "SnapKit"),
        // KakaoSDK is the umbrella product — it already contains
        // KakaoSDKAuth/KakaoSDKCommon (listing them too duplicates the links).
        .external(name: "KakaoSDK"),
        .external(name: "FirebaseAuth"),
        .external(name: "FirebaseCore"),
        .external(name: "FirebaseCrashlytics"),
        .external(name: "FirebaseMessaging"),
        .external(name: "Lottie"),
        .external(name: "AmplitudeSwift"),
    ],
    settings: .settings(
        base: legacyBase,
        configurations: [
            .debug(name: "Debug", settings: debugSigning, xcconfig: "../../DevConfig.xcconfig"),
            .release(name: "Stage", settings: distributionSigning, xcconfig: "../../StageConfig.xcconfig"),
            .release(name: "Release", settings: distributionSigning, xcconfig: "../../LiveConfig.xcconfig"),
        ],
        defaultSettings: .recommended
    )
)

let project = Project(
    name: "AtchaLegacy",
    options: .options(
        automaticSchemesOptions: .disabled,
        defaultKnownRegions: ["ko", "Base"],
        developmentRegion: "ko",
        disableBundleAccessors: true,
        disableSynthesizedResourceAccessors: true
    ),
    settings: .settings(configurations: [
        .debug(name: "Debug", xcconfig: "../../DevConfig.xcconfig"),
        .release(name: "Stage", xcconfig: "../../StageConfig.xcconfig"),
        .release(name: "Release", xcconfig: "../../LiveConfig.xcconfig"),
    ]),
    targets: [legacyTarget],
    schemes: [
        .scheme(
            name: "Atcha-Dev",
            shared: true,
            buildAction: .buildAction(targets: ["Atcha-iOS"]),
            runAction: .runAction(configuration: "Debug", executable: "Atcha-iOS"),
            archiveAction: .archiveAction(configuration: "Debug"),
            profileAction: .profileAction(configuration: "Debug", executable: "Atcha-iOS"),
            analyzeAction: .analyzeAction(configuration: "Debug")
        ),
        .scheme(
            name: "Atcha-Stage",
            shared: true,
            buildAction: .buildAction(targets: ["Atcha-iOS"]),
            runAction: .runAction(configuration: "Stage", executable: "Atcha-iOS"),
            archiveAction: .archiveAction(configuration: "Stage"),
            profileAction: .profileAction(configuration: "Stage", executable: "Atcha-iOS"),
            analyzeAction: .analyzeAction(configuration: "Stage")
        ),
        .scheme(
            name: "Atcha-Live",
            shared: true,
            buildAction: .buildAction(targets: ["Atcha-iOS"]),
            runAction: .runAction(configuration: "Release", executable: "Atcha-iOS"),
            archiveAction: .archiveAction(configuration: "Release"),
            profileAction: .profileAction(configuration: "Release", executable: "Atcha-iOS"),
            analyzeAction: .analyzeAction(configuration: "Release")
        ),
    ]
)
