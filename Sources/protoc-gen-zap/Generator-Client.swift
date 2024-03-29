import Foundation
import SwiftProtobuf
import SwiftProtobufPluginLibrary

extension Generator {    
    internal func printClient(_ service: ServiceDescriptor) {
        println()
        println("// MARK: - \(service.name)")
        printConnectionProtocol(service)
        println()
        printStreamingConnection(service)
        println()
        printRpcConnection(service)
        println()
        printRest(service)
        println()
        printMockConnection(service)
    }
    
    private func printMockConnection(_ service: ServiceDescriptor) {
        println("final class Mock\(service.name)Connection: \(connectionProtocolName(service)) {")
        indent()
        for method in service.methods {
            switch streamingType(method) {
            case .unary, .serverStreaming:
                println("private let \(methodFunctionName(method)): \(methodOutputName(method))?")
            case .clientStreaming, .bidirectionalStreaming:
                printSkippedComment(method)
            }
        }
        println()
        println("init(")
        indent()
        for (index, method) in service.methods.enumerated() {
            switch streamingType(method) {
            case .unary, .serverStreaming:
                let trailing = index == service.methods.count - 1 ? "" : ","
                println("\(methodFunctionName(method)): \(methodOutputName(method))? = nil\(trailing)")
            case .clientStreaming, .bidirectionalStreaming:
                printSkippedComment(method)
            }
        }
        outdent()
        println(") {")
        indent()
        for method in service.methods {
            switch streamingType(method) {
            case .unary, .serverStreaming:
                println("self.\(methodFunctionName(method)) = \(methodFunctionName(method))")
            case .clientStreaming, .bidirectionalStreaming:
                printSkippedComment(method)
            }
        }
        outdent()
        println("}")
        for method in service.methods {
            switch streamingType(method) {
            case .unary, .serverStreaming:
                printMethodName(method, hasBody: true)
                indent()
                println("completion(Result(value: \(methodFunctionName(method)), error: LndApiError.unknownError))")
                outdent()
                println("}")
                println()
            case .clientStreaming, .bidirectionalStreaming:
                printSkippedComment(method)
            }
        }
        outdent()
        println("}")
    }
    
    private func printConnectionProtocol(_ service: ServiceDescriptor) {
        println("protocol \(connectionProtocolName(service)) {")
        indent()
        for method in service.methods {
            switch streamingType(method) {
            case .unary, .serverStreaming:
                printMethodName(method, hasBody: false)
            case .clientStreaming, .bidirectionalStreaming:
                printSkippedComment(method)
            }
        }
        outdent()
        println("}")
    }

    private func printStreamingConnection(_ service: ServiceDescriptor) {
        println("#if !REMOTEONLY")
        println("final class Streaming\(service.name)Connection: \(connectionProtocolName(service)) {")
        indent()
        for method in service.methods {
            switch streamingType(method) {
            case .unary, .serverStreaming:
                printMethodName(method, hasBody: true)
                indent()
                println("Lndmobile\(prefixName(service))\(method.name)(try? request.serializedData(), LndCallback(completion))")
                outdent()
                println("}")
                println()
            case .clientStreaming, .bidirectionalStreaming:
                printSkippedComment(method)
            }
        }
        outdent()
        println("}")
        println("#endif")
    }
    
    private func printRpcConnection(_ service: ServiceDescriptor) {
        println("final class RPC\(service.name)Connection: \(connectionProtocolName(service)) {")
        indent()
        println("""
        let service: \(serviceClassName(service))
            
        public init(configuration: RPCCredentials) {
            service = \(serviceClassName(service))Client(configuration: configuration)
        }
        """)
        println()
        for method in service.methods {
            switch streamingType(method) {
            case .unary:
                printMethodName(method, hasBody: true)
                indent()
                println("_ = try? service.\(methodFunctionName(method))(request, completion: createHandler(completion))")
                outdent()
                println("}")
            case .serverStreaming:
                printMethodName(method, hasBody: true)
                indent()
                let updateMethodName = "receive\(method.name)Update"
                println("""
                do {
                    let call = try service.\(methodFunctionName(method))(request) { Logger.error($0) }
                    try \(updateMethodName)(call: call, completion: completion)
                } catch {
                    Logger.error(error)
                }
                """)
                outdent()
                println("}")
                println()
                
                let callName = nameForPackageServiceMethod(service, method) + "Call"
                
                println("""
                private func \(updateMethodName)(call: \(callName), completion: @escaping ApiCompletion<\(methodOutputName(method))>) throws {
                    try call.receive { [weak self] in
                        do {
                            try handleStreamResult($0, completion: completion)
                            try self?.\(updateMethodName)(call: call, completion: completion)
                        } catch {}
                    }
                }
                """)
            case .clientStreaming, .bidirectionalStreaming:
                printSkippedComment(method)
            }
            println()
        }
        outdent()
        println("}")
    }
    
    private func printSkippedComment(_ method: MethodDescriptor) {
        println("// skipped: \(methodFunctionName(method))")
    }
}
