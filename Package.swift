// swift-tools-version:6.1
import Foundation
import PackageDescription

// Remote SwiftPM consumption still expects the manifest at the repo root,
// even though the package sources and tests live under `spm/`.

// MARK: - PackageDescription extensions

Package.Inject.local.dependencies = [
  .package(name: "swift-universal-foundation", path: "../../../../swift-universal/private/universal/domain/system/spm/swift-universal-foundation")
]

Package.Inject.remote.dependencies = [
  .package(url: "https://github.com/swift-universal/swift-universal-foundation.git", from: "3.0.0")
]

let package = Package(
  name: "WrkstrmColor",
  platforms: [
    .iOS(.v13),
    .macOS(.v15),
    .tvOS(.v16),
    .watchOS(.v9),
  ],
  products: [
    .library(name: "WrkstrmColor", targets: ["WrkstrmColor"])
  ],
  dependencies: Package.Inject.shared.dependencies,
  targets: [
    .target(
      name: "WrkstrmColor",
      path: "spm/Sources/WrkstrmColor",
      swiftSettings: Package.Inject.shared.swiftSettings,
    ),
    .testTarget(
      name: "WrkstrmColorTests",
      dependencies: [
        "WrkstrmColor",
        .product(name: "SwiftUniversalFoundation", package: "swift-universal-foundation")
      ],
      path: "spm/Tests/WrkstrmColorTests",
      resources: [.process("Resources")],
      swiftSettings: Package.Inject.shared.swiftSettings,
    ),
  ],
)

// MARK: - Package Service

extension Package {
  @MainActor
  public struct Inject {
    public static let version = "0.0.1"

    public var swiftSettings: [SwiftSetting] = []
    var dependencies: [PackageDescription.Package.Dependency] = []

    public static let shared: Inject = ProcessInfo.useLocalDeps ? .local : .remote

    static var local: Inject = .init(swiftSettings: [.local])
    static var remote: Inject = .init()
  }
}

// MARK: - PackageDescription extensions

extension SwiftSetting {
  public static let local: SwiftSetting = .unsafeFlags([
    "-Xfrontend",
    "-warn-long-expression-type-checking=10",
  ])
}

// MARK: - Foundation extensions

extension ProcessInfo {
  public static var useLocalDeps: Bool {
    ProcessInfo.processInfo.environment["SPM_USE_LOCAL_DEPS"] == "true"
  }
}

// PACKAGE_SERVICE_END_V1
