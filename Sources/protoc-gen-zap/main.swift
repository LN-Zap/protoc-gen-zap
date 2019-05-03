import Foundation
import SwiftProtobuf
import SwiftProtobufPluginLibrary

func Log(_ message: String) {
    FileHandle.standardError.write((message + "\n").data(using: .utf8)!)
}

var generatedFiles: [String: Int] = [:]

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
            let grpcFileName = "rpc.zap.swift"
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
