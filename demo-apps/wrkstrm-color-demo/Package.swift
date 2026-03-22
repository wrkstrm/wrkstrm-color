// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "WrkstrmColorDemo",
  platforms: [ .macOS(.v15) ],
  products: [ .executable(name: "WrkstrmColorDemo", targets: ["WrkstrmColorDemo"]) ],
  dependencies: [
    .package(path: "../../../../../../todo3/private/code/spm/kit/variant-kit"),
    .package(name: "WrkstrmColor", path: "../.."),
    .package(
      name: "WrkstrmSharedAppShell",
      path: "../../../../wrkstrm-app-shell/shared/spm/wrkstrm-shared-app-shell"
    ),
  ],
  targets: [
    .executableTarget(
      name: "WrkstrmColorDemo",
      dependencies: [
        .product(name: "VariantKit", package: "variant-kit"),
        .product(name: "WrkstrmColor", package: "WrkstrmColor"),
        .product(name: "WrkstrmSharedAppShell", package: "WrkstrmSharedAppShell"),
      ]
    )
  ]
)
