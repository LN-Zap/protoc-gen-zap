import Foundation
import SwiftProtobuf
import SwiftProtobufPluginLibrary

extension Generator {
    func serviceClassName(_ service: ServiceDescriptor) -> String {
        return nameForPackageService(service) + "Service"
    }
    
    func connectionProtocolName(_ service: ServiceDescriptor) -> String {
        return service.name + "Connection"
    }
    
    func prefixName(_ service: ServiceDescriptor) -> String {
        switch service.name {
        // don't add prefixes to `WalletUnlocker` and `Lightning` services
        case "WalletUnlocker", "Lightning":
            return ""
        default:
            return service.name
        }
    }
    
    func methodFunctionName(_ method: MethodDescriptor) -> String {
        let name = method.name
        return name.prefix(1).lowercased() + name.dropFirst()
    }
    
    func methodOutputName(_ method: MethodDescriptor) -> String {
        return protoMessageName(method.outputType)
    }
    
    // Transform .some.package_name.FooBarRequest -> Some_PackageName_FooBarRequest
    func protoMessageName(_ descriptor: SwiftProtobufPluginLibrary.Descriptor) -> String {
        return SwiftProtobufNamer().fullName(message: descriptor)
    }
   
    func nameForPackageServiceMethod(_ service: ServiceDescriptor, _ method: MethodDescriptor) -> String {
        return nameForPackageService(service) + method.name
    }
    
    private func nameForPackageService(_ service: ServiceDescriptor) -> String {
        if !file.package.isEmpty {
            return SwiftProtobufNamer().typePrefix(forFile: file) + service.name
        } else {
            return service.name
        }
    }
}
