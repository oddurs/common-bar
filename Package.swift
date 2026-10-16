// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommonBar",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "BarKit"),
        // Keeps its pre-rename name: the bundle's executable and login item match it.
        .executableTarget(
            name: "Reasonal",
            dependencies: ["BarKit"],
            linkerSettings: [.linkedFramework("ServiceManagement")]
        ),
        .testTarget(name: "BarKitTests", dependencies: ["BarKit"]),
        .testTarget(name: "CommonBarTests"),
    ]
)
