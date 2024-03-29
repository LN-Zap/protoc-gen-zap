import Foundation
import SwiftProtobuf
import SwiftProtobufPluginLibrary

func Log(_ message: String) {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
}

var generatedFiles: [String: Int] = [:]

// from apple/swift-protobuf/Sources/protoc-gen-swift/StringUtils.swift
func splitPath(pathname: String) -> (dir: String, base: String, suffix: String) {
    var dir = ""
    var base = ""
    var suffix = ""
    #if swift(>=3.2)
    let pathnameChars = pathname
    #else
    let pathnameChars = pathname.characters
    #endif
    for c in pathnameChars {
        if c == "/" {
            dir += base + suffix + String(c)
            base = ""
            suffix = ""
        } else if c == "." {
            base += suffix
            suffix = String(c)
        } else {
            suffix += String(c)
        }
    }
    #if swift(>=3.2)
    let validSuffix = suffix.isEmpty || suffix.first == "."
    #else
    let validSuffix = suffix.isEmpty || suffix.characters.first == "."
    #endif
    if !validSuffix {
        base += suffix
        suffix = ""
    }
    return (dir: dir, base: base, suffix: suffix)
}

enum FileNaming: String {
    case FullPath
    case PathToUnderscores
    case DropPath
}

func outputFileName(component: String, fileDescriptor: FileDescriptor, fileNamingOption: FileNaming) -> String {
    let ext = "." + component + ".swift"
    let pathParts = splitPath(pathname: fileDescriptor.name)
    switch fileNamingOption {
    case .FullPath:
        return pathParts.dir + pathParts.base + ext
    case .PathToUnderscores:
        let dirWithUnderscores =
            pathParts.dir.replacingOccurrences(of: "/", with: "_")
        return dirWithUnderscores + pathParts.base + ext
    case .DropPath:
        return pathParts.base + ext
    }
}

func uniqueOutputFileName(component: String, fileDescriptor: FileDescriptor, fileNamingOption: FileNaming) -> String {
    let defaultName = outputFileName(component: component, fileDescriptor: fileDescriptor, fileNamingOption: fileNamingOption)
    if let count = generatedFiles[defaultName] {
        generatedFiles[defaultName] = count + 1
        return outputFileName(component: "\(count)." + component, fileDescriptor: fileDescriptor, fileNamingOption: fileNamingOption)
    } else {
        generatedFiles[defaultName] = 1
        return defaultName
    }
}

func main() throws {
    
    // initialize responses
    var response = Google_Protobuf_Compiler_CodeGeneratorResponse()
    
    // read plugin input
    let rawRequest = FileHandle.standardInput.readDataToEndOfFile()
    let request = try Google_Protobuf_Compiler_CodeGeneratorRequest(serializedData: rawRequest)
    
    // Build the SwiftProtobufPluginLibrary model of the plugin input
    let descriptorSet = DescriptorSet(protos: request.protoFile)
    
    // process each .proto file separately
    for fileDescriptor in descriptorSet.files {
        if fileDescriptor.services.count > 0 {
            let grpcFileName = uniqueOutputFileName(component: "zap", fileDescriptor: fileDescriptor, fileNamingOption: .FullPath)
            let grpcGenerator = Generator(fileDescriptor)
            var grpcFile = Google_Protobuf_Compiler_CodeGeneratorResponse.File()
            grpcFile.name = grpcFileName
            grpcFile.content = grpcGenerator.code
            response.file.append(grpcFile)
        }
    }
    
    // return everything to the caller
    FileHandle.standardOutput.write(try response.serializedData())
}

do {
    try main()
} catch {
    Log("ERROR: \(error)")
}
