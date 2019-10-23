//
//  Generator-Rest.swift
//  SwiftProtobuf
//
//  Created by 0 on 26.08.19.
//

import Foundation
import SwiftProtobuf
import SwiftProtobufPluginLibrary

extension Generator {
    enum HTTPMethod: Int {
        case get = 2
        case post = 4
        case delete = 5
        
        var string: String {
            switch self {
            case .get:
                return ".get"
            case .post:
                return ".post"
            case .delete:
                return ".delete"
            }
        }
    }
    
    func printRest(_ service: ServiceDescriptor) {
        println("final class Rest\(service.name)Connection: \(connectionProtocolName(service)) {")
        indent()
        println("private let lndRest: LNDRest")
        println()
        println("init(lndRest: LNDRest) {")
        indent()
        println("self.lndRest = lndRest")
        outdent()
        println("}")
        println()
        
        for method in service.methods {
            let debugString = method.proto.options.textFormatString()
            
            printMethodName(method, hasBody: true)
            indent()
            
            if let line = debugString.components(separatedBy: .newlines).first(where: { $0.contains("v1") }),
                case let components = line.trimmingCharacters(in: .whitespaces).components(separatedBy: ": "),
                let rawHttpMethod = Int(components[0]),
                let httpMethod = HTTPMethod.init(rawValue: rawHttpMethod) {
                var path = components[1]
                path = path.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                
                var pathArgumens = [String]()
                
                var pathComponents = path.components(separatedBy: "/")
                for (index, comp) in pathComponents.enumerated() {
                    if comp.starts(with: "{") {
                        let comp = comp.trimmingCharacters(in: CharacterSet(charactersIn: "{}"))
                            .components(separatedBy: ".")
                            .map { NamingUtils.toLowerCamelCase($0) }
                            .joined(separator: ".")
                        
                        pathComponents[index] = "\\(request.\(comp))"
                        pathArgumens.append(comp)
                    }
                }
                let url = pathComponents.joined(separator: "/")
                
                let hasBody = debugString.components(separatedBy: .newlines).contains(where: { $0.contains("7: \"*\"") })

                if hasBody {
                    println("guard let json = try? request.jsonString() else { return }")
                    println("lndRest.run(method: \(httpMethod.string), path: \"\(url)\", data: json, completion: completion)")
                } else {
                    println("lndRest.run(method: \(httpMethod.string), path: \"\(url)\", data: nil, completion: completion)")
                }
            } else {
                println("Logger.error(\"\(method.name) not implemented\", customPrefix: \"📺\")")
            }
            outdent()
            println("}")
            println()
        }
        outdent()
        println("}")
    }

}
