// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "FirestoreTest",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "10.0.0"))
    ],
    targets: [
        .executableTarget(
            name: "FirestoreTest",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk")
            ],
            path: ".",
            sources: ["test_firestore.swift"]
        )
    ]
)