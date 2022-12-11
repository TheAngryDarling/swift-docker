//
//  Docker.swift
//  SwiftDockerCoreLib
//
//  Created by Tyler Anger on 2022-03-30.
//

import Foundation
import SwiftPatches
import Dispatch
import CLICapture

/// Namespace for calling Docker CLI commands
public enum Docker {
    public enum DockerError: Error {
        case processTimedOut
        case noOutputFromCommand
        case failedToConvertDataToString(data: Data, encoding: String.Encoding)
    }
    public struct VolumeMapping: LosslessStringConvertible, ExpressibleByStringLiteral {
        public let realPath: String
        public let virtualPath: String
        public let options: String?
        
        public var description: String {
            var rtn = self.realPath + ":" + self.virtualPath
            if let o = self.options {
                rtn += ":" + o
            }
            return rtn
        }
        
        public init(physicalPath: String,
                    virtualPath: String,
                    options: String? = nil) {
            self.realPath = physicalPath
            self.virtualPath = virtualPath
            self.options = options
        }
        
        public init?(_ description: String) {
            let items = description.split(separator: ":").map(String.init)
            guard items.count >= 2 && items.count <= 3 else {
                return nil
            }
            self.realPath = items[0]
            self.virtualPath = items[1]
            if items.count == 3 {
                self.options = items[2]
            } else {
                self.options = nil
            }
        }
        
        public init(stringLiteral value: String) {
            guard let obj = VolumeMapping(value) else {
                preconditionFailure("Invalid Volume Mapping value '\(value)'")
            }
            self = obj
        }
        
    }
    
    public struct MountMapping: LosslessStringConvertible, ExpressibleByStringLiteral {
        let type: String
        let source: String
        let target: String
        let attributes: [String]
        
        public var description: String {
            var rtn = "type=\(self.type),source=\(self.source),target=\(self.target)"
            for attrib in self.attributes {
                rtn += ",\(attrib)"
            }
            
            return rtn
        }
        
        public init?(_ description: String) {
            var typ: String? = nil
            var src: String? = nil
            var tgt: String? = nil
            var attribs: [String] = []
            
            let items = description.split(separator: ",").map(String.init)
            for var item in items {
                if item.hasPrefix("type=") {
                    item.removeFirst(5)
                    typ = item
                } else if item.hasPrefix("source=") {
                    item.removeFirst(7)
                    src = item
                } else if item.hasPrefix("target=") {
                    item.removeFirst(7)
                    tgt = item
                } else {
                    attribs.append(item)
                }
            }
            
			guard let t = typ,
                  let s = src,
                  let g = tgt else {
                      return nil
            }
            self.type = t
            self.source = s
            self.target = g
            self.attributes = attribs
        }
        
        public init(stringLiteral value: String) {
            guard let obj = MountMapping(value) else {
                preconditionFailure("Invalid Mount Mapping value '\(value)'")
            }
            self = obj
        }
        
    }
    public static let DefaultDockerPath: String = "/usr/local/bin/docker"
    
    public static func capture(dockerPath: String = Docker.DefaultDockerPath,
                                arguments: [String],
                               attachInput: Bool = false,
                               showCommand: Bool = false,
                               callbackQueue: DispatchQueue = DispatchQueue(label: "Docker.capture.async"),
                               processWroteToItsSTDOutput: ((Process, CLICapture.STDOutputStream) -> Void)? = nil,
                               callback: @escaping (_ terminationStatus: Int32, _ data: Data) -> Void) throws -> Process {
        
        let capturer = CLICapture(executable: URL(fileURLWithPath: dockerPath))
        if showCommand {
            let args = arguments.reduce("") {
                if $1.contains(" ") {
                    return $0 + " " + "\"\($1)\""
                } else {
                    return $0 + " \($1)"
                }
            }
            print("-------------------------------------------------")
            print(dockerPath + args)
            print("-------------------------------------------------")
        }
        
        return try capturer.captureDataResponse(arguments: arguments,
                                                standardInput: (attachInput ? FileHandle.standardInput : nil),
                                                outputOptions: .captureAll,
                                                runningCallbackHandlerOn: callbackQueue,
                                                processWroteToItsSTDOutput: processWroteToItsSTDOutput,
                                                //eventHandler: ?
                                                withDataType: Data.self) { sender, response, err in
            callback(response?.exitStatusCode ?? sender.terminationStatus,
                     response?.output ?? Data() )
        }
        
    }
    
    public static func capture(dockerPath: String = Docker.DefaultDockerPath,
                               arguments: [String],
                               attachInput: Bool = false,
                               showCommand: Bool = false,
                               timeout: DispatchTime = .distantFuture) throws -> (terminationStatus: Int32, output: String) {
        
       
        let semaphore = DispatchSemaphore(value: 0)
        var terminationStatus: Int32 = 0
        var data: Data = Data()
        
        var hasCompleted: Bool = false
        
        func resetTimer(_ sender: Process, _ event: CLICapture.STDOutputStream) {
            // Signals the wait so it can hit the while loop
            semaphore.signal()
        }
    
        let process = try self.capture(dockerPath: dockerPath,
                                       arguments: arguments,
                                       showCommand: showCommand,
                                       processWroteToItsSTDOutput: resetTimer) {
            (_ exitCode: Int32, _ d: Data) -> Void in
         
            terminationStatus = exitCode
            data = d
            hasCompleted = true
            semaphore.signal()
        }
       
        
        
        while !hasCompleted {
            // we will continue waiting while completion handler
            // has not been executed
            guard semaphore.wait(timeout: timeout) == .success else {
                // we kill the process
                process.terminate()
                throw DockerError.processTimedOut
            }
        }
        
        if data.count > 0 {
            if data[data.endIndex - 1] == 10 {
                // Remove \n
                data.remove(at: data.endIndex - 1)
                if data[data.endIndex - 1] == 13 {
                    // remove \r
                    data.remove(at: data.endIndex - 1)
                }
            }
        }
        guard let out = String(data: data, encoding: .utf8) else {
            throw DockerError.failedToConvertDataToString(data: data,
                                                           encoding: .utf8)
        }
        
        
        
        return (terminationStatus: terminationStatus, output: out)
        
    }
    
    public static func captureSeparate(dockerPath: String = Docker.DefaultDockerPath,
                                       arguments: [String],
                                       showCommand: Bool = false,
                                       callbackQueue: DispatchQueue = DispatchQueue(label: "Docker.capture.async"),
                                       processWroteToItsSTDOutput: ((Process, CLICapture.STDOutputStream) -> Void)? = nil,
                                       callback: @escaping (_ terminationStatus: Int32,
                                                            _ outData: Data,
                                                            _ errData: Data) -> Void) throws -> Process {
        
        let capturer = CLICapture(executable: URL(fileURLWithPath: dockerPath))
        if showCommand {
            let args = arguments.reduce("") {
                if $1.contains(" ") {
                    return $0 + " " + "\"\($1)\""
                } else {
                    return $0 + " \($1)"
                }
            }
            print("-------------------------------------------------")
            print(dockerPath + args)
            print("-------------------------------------------------")
        }
        
        return try capturer.captureDataResponse(arguments: arguments,
                                                standardInput: nil,
                                                outputOptions: .captureAll,
                                                runningCallbackHandlerOn: callbackQueue,
                                                processWroteToItsSTDOutput: processWroteToItsSTDOutput,
                                                //eventHandler: ?
                                                withDataType: Data.self) { sender, response, err in
            callback(response?.exitStatusCode ?? sender.terminationStatus,
                     response?.out ?? Data(),
                     response?.err ?? Data())
        }
    }
    
    
    public static func captureSeparate(dockerPath: String = Docker.DefaultDockerPath,
                                       arguments: [String],
                                       showCommand: Bool = false,
                                       timeout: DispatchTime = .distantFuture) throws -> (terminationStatus: Int32, out: String, err: String) {
        
        let semaphore = DispatchSemaphore(value: 0)
        var terminationStatus: Int32 = 0
        var hasCompleted: Bool = false
        func resetTimer(_ sender: Process, _ event: CLICapture.STDOutputStream) {
            // Signals the wait so it can hit the while loop
            semaphore.signal()
        }
        
        
        var out: Data = Data()
        var err: Data = Data()
        let process = try self.captureSeparate(dockerPath: dockerPath,
                                               arguments: arguments,
                                               showCommand: showCommand,
                                               processWroteToItsSTDOutput: resetTimer) {
            (_ exitCode: Int32, _ outD: Data, _ errD: Data) -> Void in
         
            terminationStatus = exitCode
            out = outD
            err = errD
            hasCompleted = true
            semaphore.signal()
        }
        
        while !hasCompleted {
            // we will continue waiting while completion handler
            // has not been executed
            guard semaphore.wait(timeout: timeout) == .success else {
                // we kill the process
                process.terminate()
                throw DockerError.processTimedOut
            }
        }
        
        if out.count > 0 {
            if out[out.endIndex - 1] == 10 {
                // Remove \n
                out.remove(at: out.endIndex - 1)
                if out[out.endIndex - 1] == 13 {
                    // remove \r
                    out.remove(at: out.endIndex - 1)
                }
            }
        }
        
        guard let sOut = String(data: out, encoding: .utf8) else {
            throw DockerError.failedToConvertDataToString(data: out,
                                                           encoding: .utf8)
        }
        
        if err.count > 0 {
            if err[err.endIndex - 1] == 10 {
                // Remove \n
                err.remove(at: err.endIndex - 1)
                if err[err.endIndex - 1] == 13 {
                    // remove \r
                    err.remove(at: err.endIndex - 1)
                }
            }
        }
        
        guard let sErr = String(data: err, encoding: .utf8) else {
            throw DockerError.failedToConvertDataToString(data: err,
                                                           encoding: .utf8)
        }
        
        
        
        return (terminationStatus: terminationStatus, out: sOut, err: sErr)
    }
    
    public static func execute(dockerPath: String = Docker.DefaultDockerPath,
                               arguments: [String],
                               attachInput: Bool = false,
                               showCommand: Bool = false,
                               hideOutput: Bool = false) throws -> Int32 {
        
        let capturer = CLICapture(executable: URL(fileURLWithPath: dockerPath))
        
        if showCommand {
            let args = arguments.reduce("") {
                if $1.contains(" ") {
                    return $0 + " " + "\"\($1)\""
                } else {
                    return $0 + " \($1)"
                }
            }
            print("-------------------------------------------------")
            print(dockerPath + args)
            print("-------------------------------------------------")
        }
        
        
        return try capturer.executeAndWait(arguments: arguments,
                                           standardInput: (attachInput ? FileHandle.standardInput : nil),
                                           passthrougOptions: (hideOutput ? .none : .all))
    }
    
    private static func buildDockerContainerArguments(image: String,
                                                      containerName: String? = nil,
                                                      dockerArguments: [String] = [],
                                                      autoRemove: Bool = true,
                                                      supportInput: Bool = false,
                                                      detach: Bool = false,
                                                      dockerEnvironment: [String: String] = [:],
                                                      mountMapping: [MountMapping] = [],
                                                      volumeMapping: [VolumeMapping] = [],
                                                      containerWorkingDirectory: String? = nil,
                                                      containerCommand: String?,
                                                      containerArguments: [String] = []) -> [String] {
        var args: [String] = ["run"]
        if autoRemove { args.append("--rm") }
        //args.append("-it")
        if supportInput {
            args.append("-i")
        }
        args.append("-t")
        if detach {
            args.append("-d")
        }
        if let n = containerName?.replacingOccurrences(of: " ", with: "_") {
            args.append("--name")
            args.append(n)
        }
        // disable logging
        args.append(contentsOf: ["--log-driver", "none"])
        args.append(contentsOf: dockerArguments)
        for (k,v) in dockerEnvironment {
            args.append("-e")
            args.append("\(k)=\(v)")
        }
        
        for m in mountMapping {
            args.append("--mount")
            args.append(m.description)
        }
        for m in volumeMapping {
            args.append("-v")
            args.append(m.description)
        }
        
        if let w = containerWorkingDirectory {
            args.append("-w")
            args.append(w)
        }
        
        args.append(image)
        
        if let cmd = containerCommand {
            args.append(cmd)
        }
        
        args.append(contentsOf: containerArguments)
        
        return args
    }
    
    public static func runContainer(dockerPath: String = Docker.DefaultDockerPath,
                                    image: String,
                                       containerName: String? = nil,
                                       dockerArguments: [String] = [],
                                       autoRemove: Bool = true,
                                    attachInput: Bool = false,
                                    detach: Bool = false,
                                       dockerEnvironment: [String: String] = [:],
                                       mountMapping: [MountMapping] = [],
                                       volumeMapping: [VolumeMapping] = [],
                                       containerWorkingDirectory: String? = nil,
                                       containerCommand: String?,
                                       containerArguments: [String] = [],
                                        showCommand: Bool = false,
                                        hideOutput: Bool) throws -> Int32 {
        
        let args = buildDockerContainerArguments(image: image,
                                        containerName: containerName,
                                        dockerArguments: dockerArguments,
                                        autoRemove: autoRemove,
                                        supportInput: attachInput,
                                        detach: detach,
                                        dockerEnvironment: dockerEnvironment,
                                        mountMapping: mountMapping,
                                        volumeMapping: volumeMapping,
                                        containerWorkingDirectory: containerWorkingDirectory,
                                        containerCommand: containerCommand,
                                        containerArguments: containerArguments)
        
        return try execute(dockerPath: dockerPath,
                           arguments: args,
                           attachInput: attachInput,
                           showCommand: showCommand,
                           hideOutput: hideOutput)
        
    }
    
    public static func runContainer(dockerPath: String = Docker.DefaultDockerPath,
                                    image: String,
                                   containerName: String? = nil,
                                   dockerArguments: [String] = [],
                                   autoRemove: Bool = true,
                                    attachInput: Bool = false,
                                   dockerEnvironment: [String: String] = [:],
                                   mountMapping: [MountMapping] = [],
                                   volumeMapping: [VolumeMapping] = [],
                                   containerWorkingDirectory: String? = nil,
                                   containerCommand: String?,
                                   containerArguments: [String] = [],
                                    showCommand: Bool = false,
                                    timeout: DispatchTime = .distantFuture) throws -> (terminationStatus: Int32,
                                                                                    output: String) {
        let args = buildDockerContainerArguments(image: image,
                                        containerName: containerName,
                                        dockerArguments: dockerArguments,
                                        autoRemove: autoRemove,
                                        supportInput: attachInput,
                                        dockerEnvironment: dockerEnvironment,
                                        mountMapping: mountMapping,
                                        volumeMapping: volumeMapping,
                                        containerWorkingDirectory: containerWorkingDirectory,
                                        containerCommand: containerCommand,
                                        containerArguments: containerArguments)
        
        return try capture(dockerPath: dockerPath,
                           arguments: args,
                           attachInput: attachInput,
                           showCommand: showCommand,
                           timeout: timeout)
    }
    
    public static func genSwiftContName<T>(command: String,
                                           tag: DockerHub.RepositoryTag,
                                           subCommand: String? = nil,
                                           packageName: String,
                                           using generator: inout T,
                                           additionInfo: [String?]) -> String where T: RandomNumberGenerator {
        var rtn: String = "\(command)-\(tag)"
        if let sc = subCommand {
            rtn += "-\(sc.uppercased())"
        }
        rtn += "-\(packageName)"
        for info in additionInfo {
            if let info = info {
                rtn += "-\(info)"
            }
        }
        
        rtn += "-" + String.randomAlphaNumericString(count: 8, using: &generator)
        
        return rtn.replacingOccurrences(of: " ", with: "_")
    }
    
    
    public static func genSwiftContName<T>(command: String,
                                           tag: DockerHub.RepositoryTag,
                                           subCommand: String? = nil,
                                           packageName: String,
                                           using generator: inout T,
                                           additionInfo: String?...) -> String where T: RandomNumberGenerator {
        
        return self.genSwiftContName(command: command,
                                     tag: tag,
                                     subCommand: subCommand,
                                     packageName: packageName,
                                     using: &generator,
                                     additionInfo: additionInfo)
        
    }
    
    public static func genSwiftContName(command: String,
                                        tag: DockerHub.RepositoryTag,
                                        subCommand: String? = nil,
                                        packageName: String,
                                        additionInfo: String?...) -> String {
        var generator = SystemRandomNumberGenerator()
        return self.genSwiftContName(command: command,
                                     tag: tag,
                                     subCommand: subCommand,
                                     packageName: packageName,
                                     using: &generator,
                                     additionInfo: additionInfo)
    }
}
