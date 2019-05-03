// swift-tools-version:4.2
import PackageDescription
import Foundation

var packageDependencies: [Package.Dependency] = [
  // Official SwiftProtobuf library, for [de]serializing data to send on the wire.
  .package(url: "https://github.com/apple/swift-protobuf.git", .upToNextMajor(from: "1.5.0")),
]

let package = Package(
  name: "protoc-gen-zap",
  products: [
    .library(name: "protoc-gen-zap", targets: ["protoc-gen-zap"]),
  ],
  dependencies: packageDependencies,
  targets: [
    .target(name: "protoc-gen-zap",
            dependencies: [
              "SwiftProtobuf",
              "SwiftProtobufPluginLibrary",
              "protoc-gen-swift"]),
  ],
  swiftLanguageVersions: [.v4, .v4_2, .version("5")],
  cLanguageStandard: .gnu11,
  cxxLanguageStandard: .cxx11)
