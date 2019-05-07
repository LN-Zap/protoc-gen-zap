import SwiftProtobufPluginLibrary

class Generator {
    private var printer: CodePrinter
    
    internal let file: FileDescriptor
    
    init(_ file: FileDescriptor) {
        self.file = file
        self.printer = CodePrinter()
        printMain()
    }
    
    public var code: String {
        return printer.content
    }
    
    internal func println(_ text: String = "") {
        printer.print(text)
        printer.print("\n")
    }
    
    internal func indent() {
        printer.indent()
    }
    
    internal func outdent() {
        printer.outdent()
    }
    
    private func printMain() {
        println("""
            //
            // DO NOT EDIT.
            //
            // Generated by `protoc-gen-zap`.
            // Source: \(file.name)
            //\n
            """)
        
        println("""
        #if !REMOTEONLY
        import Lndmobile
        #endif
        """)
        
        let frameworks = ["Logger"]
        for framework in frameworks {
            println("import \(framework)")
        }
        
        for service in file.services {
            printClient(service)
        }
    }
}
