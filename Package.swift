// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


let package = Package(
    name: "swift-docker",
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    products: [
        .executable(
            name: "swift-docker-build",
            targets: ["swift-docker-build"]),
        .executable(
            name: "swift-docker-test",
            targets: ["swift-docker-test"]),
        .executable(
            name: "swift-docker-run",
            targets: ["swift-docker-run"]),
        .executable(
            name: "swift-docker-execute",
            targets: ["swift-docker-execute"]),
        .executable(
            name: "docker-hub-list",
            targets: ["docker-hub-list"]),
        .executable(
            name: "swift-docker-join",
            targets: ["swift-docker-join"]),
        .executable(
            name: "swift-docker",
            targets: ["swift-docker"]),
        .executable(
            name: "swift-docker-range",
            targets: ["swift-docker-range"]),
        .executable(
            name: "swift-docker-build-range",
            targets: ["swift-docker-build-range"]),
        .executable(
            name: "swift-docker-test-range",
            targets: ["swift-docker-test-range"]),
        .executable(
            name: "swift-docker-run-range",
            targets: ["swift-docker-run-range"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/TheAngryDarling/SwiftPatches.git",
                 from: "2.0.9"),
        .package(url: "https://github.com/TheAngryDarling/SwiftRegEx.git",
                 from: "1.0.0"),
        .package(url: "https://github.com/TheAngryDarling/SwiftUnitTestingHelper.git",
                 from: "1.0.5"),
        .package(url: "https://github.com/TheAngryDarling/SwiftWebRequest.git",
                 from: "2.1.3"),
        .package(url: "https://github.com/TheAngryDarling/SwiftCLICapture.git",
                         from: "3.0.1"),
    ],
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package
    // depends on.
    targets: [
        .target(name: "SwiftDockerCoreLib",
                dependencies: ["SwiftPatches",
                              "RegEx",
                              "WebRequest",
                               "CLICapture"]),
        .target(name: "SwiftDockerExecLib",
                dependencies: ["SwiftPatches",
                               "RegEx",
                              "SwiftDockerCoreLib"]),
        .target(name: "swift-docker-build",
                dependencies: ["RegEx",
                               "SwiftPatches",
                               "SwiftDockerCoreLib",
                              "SwiftDockerExecLib"]),
        .target(name: "swift-docker-test",
                dependencies: ["SwiftDockerCoreLib",
                               "SwiftDockerExecLib"]),
        .target(name: "swift-docker-run",
                dependencies: ["SwiftDockerCoreLib",
                               "SwiftDockerExecLib"]),
        .target(name: "swift-docker-execute",
                dependencies: ["SwiftDockerCoreLib",
                               "SwiftDockerExecLib"]),
        .target(name: "docker-hub-list",
                dependencies: ["SwiftDockerCoreLib",
                               "SwiftDockerExecLib",
                               "RegEx"]),
        .target(name: "swift-docker-join",
                dependencies: ["SwiftDockerExecLib"]),
        .target(name: "swift-docker",
                dependencies: ["SwiftDockerExecLib"]),
        .testTarget(name: "swift-docker-tests",
                    dependencies: ["SwiftDockerCoreLib",
                                   "UnitTestingHelper"]),
        .target(name: "swift-docker-range",
                dependencies: ["SwiftDockerExecLib"]),
        .target(name: "swift-docker-build-range",
                dependencies: ["SwiftDockerCoreLib",
                              "SwiftDockerExecLib"]),
        .target(name: "swift-docker-test-range",
                dependencies: ["SwiftDockerCoreLib",
                               "SwiftDockerExecLib"]),
        .target(name: "swift-docker-run-range",
                dependencies: ["SwiftDockerCoreLib",
                               "SwiftDockerExecLib"])
    ]
)
