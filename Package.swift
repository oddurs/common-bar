// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CommonBar",
    platforms: [.macOS(.v14)],
    targets: [
        // Keeps its pre-rename name: the bundle's executable and login item match it.
        .executableTarget(
            name: "Reasonal",
            linkerSettings: [.linkedFramework("ServiceManagement")]
        ),
        .testTarget(name: "CommonBarTests"),
    ]
)
