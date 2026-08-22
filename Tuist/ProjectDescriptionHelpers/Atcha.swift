import ProjectDescription

public enum Atcha {
    public static let teamID = "23SCTLK482"
    public static let v2BundleID = "com.atcha.iOS.v2"
    public static let destinations: Destinations = [.iPhone]
    public static let v2Deployment: DeploymentTargets = .iOS("26.0")
    public static let legacyDeployment: DeploymentTargets = .iOS("16.1")
    public static let knownRegions = ["ko", "Base"]
    public static let developmentRegion = "ko"
}
