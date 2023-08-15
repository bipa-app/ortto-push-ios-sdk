// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OrttoSDK",
    platforms: [
        .iOS(.v13),
        .macOS(.v10_14)
    ],
    products: [
        .library(name: "OrttoPushSDKCore", targets: ["OrttoPushSDKCore"]),
        .library(name: "OrttoPushMessagingFCM", targets: ["OrttoPushMessagingFCM"]),
        .library(name: "OrttoPushMessagingAPNS", targets: ["OrttoPushMessagingAPNS"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.6.1")),
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.13.0")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        // Push SDK
        .target(
            name: "OrttoPushSDKCore",
            dependencies: [.product(name: "Alamofire", package: "Alamofire")],
            path: "Sources/PushSDKCore"
        ),
        // FCM
        .target(
            name: "OrttoPushMessagingFCM",
            dependencies: ["OrttoPushSDKCore", .product(name: "FirebaseMessaging", package: "firebase-ios-sdk")],
            path: "Sources/PushMessagingFCM"
        ),
        // PNS
        .target(
            name: "OrttoPushMessagingAPNS",
            dependencies: ["OrttoPushSDKCore"],
            path: "Sources/PushMessagingAPNS"
        ),
        // Tests
        .testTarget(
            name: "ap3-push-ios-sdkTests",
            dependencies: ["OrttoPushSDKCore"]
        ),
    ]
)

