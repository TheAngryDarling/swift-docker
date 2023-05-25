//
//  ExecuteContainerApp.swift
//  
//
//  Created by Tyler Anger on 2022-04-03.
//

import Foundation
import RegEx
import SwiftPatches
import SwiftDockerCoreLib

public enum DockerContainerApp {
    
    public static let version: String = "1.0.7"
    /// Collection of different actions that are available to perform
    public enum Actions {
        private static let colourRed: Int = 196
        private static let colourYellow: Int = 226
        private static let colourGreen: Int = 118//154
        /// Define the Swift Build Action
        public enum Build: DockerSwiftAction {
            public static let singleActionAppDescription: String? = "Build a Swift Package against a specific Docker Swift Version"
            public static let rangeActionAppDescription: String? = "Build a Swift Package against a range of Docker Swift Version"
            public static let swiftSubCommand: String? = "build"
            public static let action: String = "build"

            public static let primaryActionMessage: String = "Building with %tag%"
            public static let retryingMessage: String = "Retrying build on %tag%"
            public static let errorMessage: String = "\u{1B}[38;5;\(colourRed)mFailed\u{1B}[0m to build on %tag%"
            public static let warningMessage: String = "Built with \u{1B}[38;5;\(colourYellow)mwarnings\u{1B}[0m on %tag%"
            public static let successfulMessage: String = "Built \u{1B}[38;5;\(colourGreen)msuccessfully\u{1B}[0m on %tag%"
            
            public static func postSubCommandArguments(callType: DockerSwiftActionCallType,
                                                       image: DockerRepoContainerApp,
                                                       tag: DockerHub.RepositoryTag,
                                                       userArguments: [String]) -> [String] {
                switch callType {
                    case .singular:
                        return ["-Xswiftc", "-DDOCKER_BUILD"]
                    case .range:
                        return ["-Xswiftc", "-DDOCKER_ALL_BUILD", "-Xswiftc", "-DDOCKER_BUILD"]
                }
            }
        }
        /// Define the Swift Test Action
        public enum Test: DockerSwiftAction {
            public static let singleActionAppDescription: String? = "Test a Swift Package against a specific Docker Swift Version"
            public static let rangeActionAppDescription: String? = "Test a Swift Package against a range of Docker Swift Version"
            public static let swiftSubCommand: String? = "test"
            public static let action: String = "test"

            public static let primaryActionMessage: String = "Testing with %tag%"
            public static let retryingMessage: String = "Retrying test on %tag%"
            public static let errorMessage: String = "Tests \u{1B}[38;5;\(colourRed)mFailed\u{1B}[0m on %tag%"
            public static let warningMessage: String = "Tested with \u{1B}[38;5;\(colourYellow)mwarnings\u{1B}[0m on %tag%"
            public static let successfulMessage: String = "Tested \u{1B}[38;5;\(colourGreen)msuccessfully\u{1B}[0m on %tag%"
            
            public static func postSubCommandArguments(callType: DockerSwiftActionCallType,
                                                       image: DockerRepoContainerApp,
                                                       tag: DockerHub.RepositoryTag,
                                                       userArguments: [String]) -> [String] {
                switch callType {
                    case .singular:
                        return ["-Xswiftc", "-DDOCKER_BUILD"]
                    case .range:
                        return ["-Xswiftc", "-DDOCKER_ALL_BUILD", "-Xswiftc", "-DDOCKER_BUILD"]
                }
            }
        }
        /// Define the Swift Run Action
        public enum Run: DockerSwiftAction {
            public static let singleActionAppDescription: String? = "Run a Swift Package against a specific Docker Swift Version"
            public static let rangeActionAppDescription: String? = "Run a Swift Package against a range of Docker Swift Version"
            public static let swiftSubCommand: String? = "run"
            public static let action: String = "run"

            public static let primaryActionMessage: String = "Running with %tag%"
            public static let retryingMessage: String = "Retrying run on %tag%"
            public static let errorMessage: String = "\u{1B}[38;5;\(colourRed)mFailed\u{1B}[0m to run on %tag%"
            public static let warningMessage: String = "Ran with \u{1B}[38;5;\(colourYellow)mwarnings\u{1B}[0m on %tag%"
            public static let successfulMessage: String = "Ran \u{1B}[38;5;\(colourGreen)msuccessfully\u{1B}[0m on %tag%"
            
            public static func postSubCommandArguments(callType: DockerSwiftActionCallType,
                                                       image: DockerRepoContainerApp,
                                                       tag: DockerHub.RepositoryTag,
                                                       userArguments: [String]) -> [String] {
                switch callType {
                    case .singular:
                        return ["-Xswiftc", "-DDOCKER_BUILD"]
                    case .range:
                        return ["-Xswiftc", "-DDOCKER_ALL_BUILD", "-Xswiftc", "-DDOCKER_BUILD"]
                }
            }
        }
        /// Define the Swift custom action
        public enum Execute: DockerSwiftAction {
            public static let singleActionAppDescription: String? = "Execute a custom command"
            public static let rangeActionAppDescription: String? = nil
            public static let swiftSubCommand: String? = nil
            public static let action: String = "execute"

            public static let primaryActionMessage: String = "Executing with %tag%"
            public static let retryingMessage: String = "Retrying execute on %tag%"
            public static let errorMessage: String = "\u{1B}[38;5;\(colourRed)mFailed\u{1B}[0m to execute on %tag%"
            public static let warningMessage: String = "Executed with \u{1B}[38;5;\(colourYellow)mwarnings\u{1B}[0m on %tag%"
            public static let successfulMessage: String = "Executed \u{1B}[38;5;\(colourGreen)msuccessfully\u{1B}[0m on %tag%"
            
            public static func postSubCommandArguments(callType: DockerSwiftActionCallType,
                                                       image: DockerRepoContainerApp,
                                                       tag: DockerHub.RepositoryTag,
                                                       userArguments: [String]) -> [String] {
                switch callType {
                    case .singular:
                        return ["-Xswiftc", "-DDOCKER_BUILD"]
                    case .range:
                        return ["-Xswiftc", "-DDOCKER_ALL_BUILD", "-Xswiftc", "-DDOCKER_BUILD"]
                }
            }
        }
        
        /// Define the Swift custom action
        public enum Package: DockerSwiftAction {
            public static let singleActionAppDescription: String? = "Package management command"
            public static let rangeActionAppDescription: String? = nil
            public static let swiftSubCommand: String? = "package"
            public static let action: String = "package"

            public static let primaryActionMessage: String = "Package management with %tag%"
            public static let retryingMessage: String = "Retrying Package management on %tag%"
            public static let errorMessage: String = "\u{1B}[38;5;\(colourRed)mFailed\u{1B}[0m to manage package on %tag%"
            public static let warningMessage: String = "Package managed with \u{1B}[38;5;\(colourYellow)mwarnings\u{1B}[0m on %tag%"
            public static let successfulMessage: String = "Package management ran \u{1B}[38;5;\(colourGreen)msuccessfully\u{1B}[0m on %tag%"
            
            public static func postSubCommandArguments(callType: DockerSwiftActionCallType,
                                                       image: DockerRepoContainerApp,
                                                       tag: DockerHub.RepositoryTag,
                                                       userArguments: [String]) -> [String] {
                return []
            }
        }
        
        public static var all: [DockerSwiftAction.Type] {
            return [Actions.Build.self,
                    Actions.Test.self,
                    Actions.Run.self,
                    Actions.Execute.self,
                    Actions.Package.self]
        }
        public static var actions: [String] {
            return all.map({ return $0.action })
        }
    }
    
    /// Collection of aruguments that this CLI Application collects
    public enum Arguments {
        public static let swiftRepoOrderArgument = Argument(short: "sro",
                                                            long: "swiftRepoOrder",
                                                            additionalParamName: "list",
                                                            description: "A ';' separated list of repo:{container cli app} to try and use as the swift image / swift app") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Swift Repo Order List Parameter")
            }
            let sroList = arguments[currentIndex]
            currentIndex += 1
            let components = sroList.split(separator: ";").map(String.init)
            
            var array: [DockerRepoContainerApp]  = (currentValue as? [DockerRepoContainerApp]) ?? []
            for sro in components {
                guard let s = DockerRepoContainerApp(sro) else {
                    return .failedToParse(message: "Invalid Repositor Name / Container App Name '\(sro)'")
                }
                array.append(s)
            }
                                          
            return .parsed(array)
        }
        
        
        
        public static let buildDirArgument = Argument(long: "buildDir",
                                    additionalParamName: "path",
                                    description: "The location where the .build dir is located. (Optional)") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Build Dir")
            }
            
            let path = arguments[currentIndex]
            currentIndex += 1
            return .parsed(path)
        }
        
        public static let tagArgument = Argument(short: "t",
                                                            long: "tag",
                                                            additionalParamName: "string",
                                                            description: "The swift tag of the image to use") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Swift Tag value")
            }
            let sTag = arguments[currentIndex]
            currentIndex += 1
            guard let tag = DockerHub.RepositoryTag(sTag) else {
                return .failedToParse(message: "Invalid Docker Tag '\(sTag)'")
            }
            return .parsed(tag)
        }
        
        public static let envArgument = Argument(long: "env",
                                                 description: "Set environment variables") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Environment Variables Argument")
            }
            let sValue = arguments[currentIndex]
            currentIndex += 1
            var components = sValue.split(separator: "=",
                                          omittingEmptySubsequences: false).map(String.init)
            let key = components[0]
            components.remove(at: 0)
            let value = components.joined(separator: "=")
            
            var dict = (currentValue as? [String: String]) ?? [:]
            dict[key] = value
            
            return .parsed(dict)
            
        }
        
        public static let volumeArgument = Argument(long: "volume",
                                                    additionalParamName: "list",
                                                    description: "Mount volumes from the specified container(s)") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Volume Mapping Argument")
            }
            let sValue = arguments[currentIndex]
            currentIndex += 1
            
            guard let mapping = Docker.VolumeMapping(sValue) else {
                return .failedToParse(message: "Invalid Volume Mapping String '\(sValue)'")
            }
            
            var array = (currentValue as? [Docker.VolumeMapping]) ?? []
            array.append(mapping)
            
            return .parsed(array)
            
        }
        
        public static let mountArgument = Argument(long: "mount",
                                                    additionalParamName: "mount",
                                                    description: "Attach a filesystem mount to the container") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Mount Mapping Argument")
            }
            let sValue = arguments[currentIndex]
            currentIndex += 1
            
            guard let mapping = Docker.MountMapping(sValue) else {
                return .failedToParse(message: "Invalid Mount Mapping String '\(sValue)'")
            }
            
            var array = (currentValue as? [Docker.MountMapping]) ?? []
            array.append(mapping)
            
            return .parsed(array)
            
        }
        
        public static let outputReplacementArgument = Argument(short: "or",
                                                        long: "outputReplacement",
                                                        additionalParamName: "string string",
                                                        description: "Replace text within the output") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Replacement Find Value")
            }
            let find = arguments[currentIndex]
            currentIndex += 1
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Mising Replacement Replace Value")
            }
            let replacement = arguments[currentIndex]
            currentIndex += 1
            
            var replacements : [String: String] = (currentValue as? [String: String]) ?? [:]
            replacements[find] = replacement
            return .parsed(replacements)
            
        }
        
        public static let outputReplacementXArgument = Argument(short: "orx",
                                                        long: "outputReplacementX",
                                                        additionalParamName: "pattern pattern",
                                                        description: "Replace text within the output") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Replacement Find Pattern")
            }
            let find = arguments[currentIndex]
            currentIndex += 1
            
            do {
                let findX = try RegEx(find)
                 
                guard currentIndex < arguments.count else {
                    return .failedToParse(message: "Mising Replacement Replace Pattern")
                }
                let replacement = arguments[currentIndex]
                currentIndex += 1
                
                var replacements : [RegEx: String] = (currentValue as? [RegEx: String]) ?? [:]
                replacements[findX] = replacement
                return .parsed(replacements)
            } catch {
                return .failedToParse(message: "Invalid Replacement Find Pattern '\(find)': \(error)")
            }
            
        }
        
        public static let dockerPathArgument = Argument(long: "dockerPath",
                                                        additionalParamName: "path",
                                                        description: "Specify the path to the docker executable") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Docker path argument")
            }
            let sValue = arguments[currentIndex]
            currentIndex += 1
            
            guard FileManager.default.fileExists(atPath: sValue) else {
                return .failedToParse(message: "Unable to find docker execute at path '\(sValue)'")
            }
            
            guard FileManager.default.isExecutableFile(atPath: sValue) else {
                return .failedToParse(message: "Docker at path '\(sValue)' is not marked as executable")
            }
            
            return .parsed(sValue)
            
        }
        
        public static let all: [Argument] = [swiftRepoOrderArgument,
                                             tagArgument,
                                             buildDirArgument,
                                             envArgument,
                                             mountArgument,
                                             volumeArgument,
                                             outputReplacementArgument,
                                             outputReplacementXArgument,
                                             dockerPathArgument]
        
        public static let noReplacement: [Argument] = [swiftRepoOrderArgument,
                                                       tagArgument,
                                                       buildDirArgument,
                                                       envArgument,
                                                       mountArgument,
                                                       volumeArgument,
                                                       dockerPathArgument]
    }
    
    /// Execute a Swift Docker ACtion
    /// - Parameters:
    ///   - arguments: The CLI Arguments
    ///   - environment: The CLI Environment
    ///   - action: The Action to execute
    /// - Returns: Returns the return code from the process executed within the docker container
    public static func execute(arguments: [String] = ProcessInfo.processInfo.arguments,
                               environment: [String: String] = ProcessInfo.processInfo.environment,
                               action: DockerSwiftAction.Type) -> Int32 {
        
        
        let appUsageDescription = action.singleActionAppDescription
        let swiftSubCommand = action.swiftSubCommand
        let primaryActionMessage = action.primaryActionMessage
        let retryingMessage = action.retryingMessage
        let errorMessage = action.errorMessage
        let warningMessage = action.warningMessage
        let successfulMessage = action.successfulMessage
        
        var arguments = arguments
        let appPath = arguments[0]
        let appName = NSString(string: appPath).lastPathComponent
        //let appFolder = NSString(string: appPath).deletingLastPathComponent

        arguments.remove(at: 0) // Remove the application path argument
        
        // I find that if the current directory is within a symbolic link then
        // using FileManager.currentDirectoryPath will return the real path not
        // the using path.  So we will try and get the path from the PWD
        let projectDir = environment["PWD"] ?? FileManager.default.currentDirectoryPath
        
        let packageName = NSString(string: projectDir).lastPathComponent

        //let workingProjectDir = FileManager.default.currentDirectoryPath
        
        
        

        func printUsage(withMessage message: String? = nil) {
            if let msg = message {
                print(msg)
            }
            print("\(appName) [OPTIONS] [CONTAINER ARGUMENTS]")
            if let desc = appUsageDescription {
                print(desc)
            }
            
            let optionArguments: [(arguments: String, description: String)] = [
                Argument.helpArgument.helpDisplayObjects(),
                Argument.versionArgument.helpDisplayObjects(),
            ] + Arguments.all.map({ return $0.helpDisplayObjects() })
            
            
            var maxArgumentCharacters: Int = optionArguments[0].arguments.count
            for obj in optionArguments {
                if obj.arguments.count > maxArgumentCharacters {
                    maxArgumentCharacters = obj.arguments.count
                }
            }
            
            
            print("")
            print("OPTIONS:")
            for obj in optionArguments {
                var line = obj.arguments
                while line.count < maxArgumentCharacters {
                    line += " " // Make all argument strings the same length
                }
                line += "     " // add 'tab' after arguments
                line += obj.description // add argument description
                print(line)
            }
        }


        // Docker Arguments
        var buildDirPath: String? = nil
        var swiftRepoOrder: [DockerRepoContainerApp] = []
        var env: [String: String] = [:]
        var volumeMapping: [Docker.VolumeMapping] = []
        var mountMapping: [Docker.MountMapping] = []
        var findReplace: [String: String] = [:]
        var findReplaceX: [RegEx: String] = [:]
        var dockerPath: String? = nil

        var tag: DockerHub.RepositoryTag = "latest"

        var dockerContainerArguments: [String] = []

        var randGenerator = SystemRandomNumberGenerator()

        var currentArgumentIndex: Int = 0
        while currentArgumentIndex < arguments.count {
            if let _ = Argument.helpArgument.parse(arguments: arguments, startingAt: &currentArgumentIndex) {
                printUsage()
                return 0
            } else if let _ = Argument.versionArgument.parse(arguments: arguments,
                                                             startingAt: &currentArgumentIndex) {
                print("\(appName) version \(DockerHubList.version)")
                return 0
            } else if let parsed = Arguments.swiftRepoOrderArgument.parse(arguments: arguments,
                                                                          startingAt: &currentArgumentIndex,
                                                                          currentParsedValue: swiftRepoOrder) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                swiftRepoOrder = parsed.object as! [DockerRepoContainerApp]
            } else if let parsed = Arguments.buildDirArgument.parse(arguments: arguments,
                                                                          startingAt: &currentArgumentIndex) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                buildDirPath = parsed.object as? String
            } else if let parsed = Arguments.tagArgument.parse(arguments: arguments,
                                                               startingAt: &currentArgumentIndex,
                                                               currentParsedValue: tag) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                tag = (parsed.object as? DockerHub.RepositoryTag) ?? tag
            } else if let parsed = Arguments.envArgument.parse(arguments: arguments,
                                                               startingAt: &currentArgumentIndex,
                                                               currentParsedValue: env) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                env = (parsed.object as? [String: String]) ?? env
            } else if let parsed = Arguments.mountArgument.parse(arguments: arguments,
                                                                 startingAt: &currentArgumentIndex,
                                                                 currentParsedValue: mountMapping) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                mountMapping = (parsed.object as? [Docker.MountMapping]) ?? mountMapping
            } else if let parsed = Arguments.volumeArgument.parse(arguments: arguments,
                                                                  startingAt: &currentArgumentIndex,
                                                                  currentParsedValue: volumeMapping) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                volumeMapping = (parsed.object as? [Docker.VolumeMapping]) ?? volumeMapping
            } else if let parsed = Arguments.outputReplacementArgument.parse(arguments: arguments,
                                                                            startingAt: &currentArgumentIndex,
                                                                            currentParsedValue: findReplace) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                findReplace = (parsed.object as? [String: String]) ?? [:]
            } else if let parsed = Arguments.outputReplacementXArgument.parse(arguments: arguments,
                                                                              startingAt: &currentArgumentIndex,
                                                                              currentParsedValue: findReplaceX) {
                 if let error = parsed.errorMessage {
                     printUsage(withMessage: error)
                     return 1
                 }
                findReplaceX = (parsed.object as? [RegEx: String]) ?? [:]
            } else if let parsed = Arguments.dockerPathArgument.parse(arguments: arguments, startingAt: &currentArgumentIndex) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                dockerPath = (parsed.object as? String) ?? dockerPath
            } else {
                let range = currentArgumentIndex..<arguments.count
                dockerContainerArguments.append(contentsOf: arguments[range])
                currentArgumentIndex = arguments.count
                
            }
        }
        
        if dockerPath == nil {
            guard let defaultDockerPath = Docker.DefaultDockerPathFromENV else {
                printUsage(withMessage: "Unable to locate docker")
                return 1
            }
            dockerPath = defaultDockerPath
        }

        if swiftRepoOrder.isEmpty {
            swiftRepoOrder.append("swift")
        }
        
        
        if !volumeMapping.contains(where: { return projectDir.hasPrefix($0.realPath) }) {
            volumeMapping.append(.init(physicalPath: projectDir, virtualPath: projectDir))
        }
        
        if let bd = buildDirPath {
            if !FileManager.default.fileExists(atPath: bd) {
                do {
                    try FileManager.default.createDirectory(atPath: bd, withIntermediateDirectories: true)
                } catch {
                    print("Failed to create Build Dir '\(bd)': \(error)")
                    return 1
                }
            }
            
            let virtualBuildDir = NSString(string: projectDir).appendingPathComponent(".build")
            volumeMapping.append(.init(physicalPath: bd,
                                       virtualPath: virtualBuildDir))
        }

        let workingTag = tag

        var workingContainerApp: DockerRepoContainerApp!

        do {

            var imageTestResp: (terminationStatus: Int32, out: String, err: String)! = nil
            for containerApp in swiftRepoOrder {
                
                // Do docker check
                // check to see if we have the docker image locally
                imageTestResp = try Docker.captureSeparate(dockerPath: dockerPath,
                                                           arguments: ["images",
                                                                  "-q",
                                                                  "\(containerApp.name):\(workingTag)"])
                if imageTestResp.terminationStatus == 0 &&
                   !imageTestResp.out.isEmpty {
                    workingContainerApp = containerApp
                    break
                }
            }

            if workingContainerApp == nil {
                for containerApp in swiftRepoOrder where !containerApp.name.isLocal {
                    // try pulling the image from the server
                    imageTestResp = try Docker.captureSeparate(dockerPath: dockerPath,
                                                               arguments: ["pull",
                                                                  "\(containerApp.name):\(workingTag)"])
                    if imageTestResp.terminationStatus == 0 {
                        workingContainerApp = containerApp
                        break
                    }
                }
            }

            guard workingContainerApp != nil else {
                
                print("Unable to find a usable repository name in " + swiftRepoOrder.map({ return "'\($0.name)'" }).joined(separator: ",") + " with tag '\(workingTag)'")
                print(imageTestResp.err)
                return 1
            }


            imageTestResp = nil
            
            let repoName: DockerHub.RepositoryName = workingContainerApp.name
            let containerCommand = workingContainerApp.app
            
            
            print(primaryActionMessage.replacingOccurrences(of: "%tag%",
                                                            with: "\(repoName):\(workingTag)"))
            
            var retryCount: Int = 0
            var resp: (terminationStatus: Int32, output: String)? = nil
            var retryCountNaming: String? = nil
            var executionResponseLine: String? = nil
            while retryCount < 3 {
                if retryCount > 0 {
                    retryCountNaming = "retry-\(retryCount)"
                }
                executionResponseLine = nil
                
                let startTime = Date()
                
                var workingArguments: [String] = action.preSubCommandArguments(callType: .singular,
                                                                               image: workingContainerApp,
                                                                               tag: workingTag,
                                                                               userArguments: dockerContainerArguments)
                if let subCommand = swiftSubCommand {
                    workingArguments.append(subCommand)
                }
                workingArguments.append(contentsOf: action.postSubCommandArguments(callType: .singular,
                                                                                   image: workingContainerApp,
                                                                                   tag: workingTag,
                                                                                   userArguments: dockerContainerArguments))
                workingArguments.append(contentsOf: dockerContainerArguments)
                workingArguments.append(contentsOf: action.postUserArgumentsArguments(callType: .singular,
                                                                                      image: workingContainerApp,
                                                                                      tag: workingTag,
                                                                                      userArguments: dockerContainerArguments))
                //workingArguments.append(contentsOf: ["-Xswiftc", "-DDOCKER_BUILD"])
                resp = try Docker.runContainer(dockerPath: dockerPath,
                                               image: "\(repoName):\(workingTag)",
                                               containerName: Docker.genSwiftContName(command: containerCommand,
                                                                                      tag: workingTag,
                                                                                      subCommand: swiftSubCommand,
                                                                                      packageName: packageName,
                                                                                      using: &randGenerator,
                                                                                      additionInfo: retryCountNaming),
                                               dockerArguments: ["--cap-add=SYS_PTRACE",
                                                                 "--security-opt",
                                                                 "seccomp=unconfined"],
                                               autoRemove: true,
                                               dockerEnvironment: env,
                                               volumeMapping: volumeMapping,
                                               containerWorkingDirectory: projectDir,
                                               containerCommand: containerCommand,
                                               containerArguments: workingArguments,
                                               showCommand: false)
                let endTime = Date()
                let duration = endTime.timeIntervalSince(startTime)
                if resp!.terminationStatus != 0 ||
                   DockerResponse.containsErrors(resp!.output) {
                    retryCount += 1
                    
                    if retryCount >= 3 || !DockerResponse.containsRetryableErrors(resp!.output) {
                        retryCount = 3
                        print("\u{1B}[2K", terminator: "") //errase line
                        print("\u{1B}[1A\u{1B}[2K", terminator: "") //move up one line and errase it
                        executionResponseLine = errorMessage.replacingOccurrences(of: "%tag%",
                                                                                  with: "\(repoName):\(workingTag)") + ".  Duration: \(formatTimeInterval(duration))"
                        print(executionResponseLine!)
                    } else {
                        
                        _ = try? Docker.runContainer(dockerPath: dockerPath,
                                                     image: "\(repoName):\(workingTag)",
                                                     containerName: Docker.genSwiftContName(command: containerCommand,
                                                                                            tag: workingTag,
                                                                                            subCommand: swiftSubCommand,
                                                                                            packageName: packageName,
                                                                                            using: &randGenerator,
                                                                                            additionInfo: retryCountNaming, "-clean-update"),
                                                     dockerArguments: ["--cap-add=SYS_PTRACE",
                                                                       "--security-opt",
                                                                       "seccomp=unconfined"],
                                                     autoRemove: true,
                                                     dockerEnvironment: env,
                                                     volumeMapping: volumeMapping,
                                                     containerWorkingDirectory: projectDir,
                                                     containerCommand: "bash",
                                                     containerArguments: ["-c", "\(containerCommand) package clean && \(containerCommand) package update"],
                                                     hideOutput: true)
                        print("\u{1B}[2K", terminator: "") //errase line
                        print("\u{1B}[1A\u{1B}[2K", terminator: "") //move up one line and errase it
                        executionResponseLine = retryingMessage.replacingOccurrences(of: "%tag%",
                                                                                     with: "\(repoName):\(workingTag)") + ". \(duration)(s)"
                        print(executionResponseLine!)
                    }
                } else if DockerResponse.containsWarnings(resp!.output) {
                    retryCount = 3
                    print("\u{1B}[2K", terminator: "") //errase line
                    print("\u{1B}[1A\u{1B}[2K", terminator: "") //move up one line and errase it
                    executionResponseLine = warningMessage.replacingOccurrences(of: "%tag%",
                                                                                with: "\(repoName):\(workingTag)") + ".  Duration: \(formatTimeInterval(duration))"
                    print(executionResponseLine!)
                } else if DockerResponse.containsDockerError(resp!.output) {
                    print(resp!.output)
                    return 1
                } else {
                    retryCount = 3
                    print("\u{1B}[2K", terminator: "") //errase line
                    print("\u{1B}[1A\u{1B}[2K", terminator: "") //move up one line and errase it
                    executionResponseLine = successfulMessage.replacingOccurrences(of: "%tag%",
                                                                                   with: "\(repoName):\(workingTag)") + ".  Duration: \(formatTimeInterval(duration))"
                    print(executionResponseLine!)
                }
            }
            
            if var out = resp?.output {
                for (k,v) in findReplace {
                    out = out.replacingOccurrences(of: k, with: v)
                }
                for (k,v) in findReplaceX {
                    out = k.stringByReplacingMatches(in: out, withTemplate: v)
                }
                // clean up any blank responses
                out = out.trimmingCharacters(in: .whitespacesAndNewlines)
                if !out.isEmpty {
                    print(out)
                    if let erl = executionResponseLine,
                       out.countOccurances(of: "\n") > 5 {
                        print(erl)
                    }
                }
                
            }
            
        } catch {
            print("Fatal Error trying container '\(workingContainerApp.name):\(workingTag)'")
            print(error)
            return 1
        }
            
        
        return 0
        
    }
    
    
    /// Creates a swift docker container and load bash so that the user can join the container
    /// - Parameters:
    ///   - arguments: Any CLI arguments to create the docker container
    ///   - environment: Any CLI Enviroment variables
    ///   - appUsageDescription: The Help Usage Display message
    /// - Returns: Returns the CLI error code.  If 0 then output shold be the id of the container to join
    public static func execute(arguments: [String] = ProcessInfo.processInfo.arguments,
                               environment: [String: String] = ProcessInfo.processInfo.environment,
                               appUsageDescription: String? = nil) -> Int32 {
        
            
        var arguments = arguments
        let appPath = arguments[0]
        let appName = NSString(string: appPath).lastPathComponent
        //let appFolder = NSString(string: appPath).deletingLastPathComponent

        arguments.remove(at: 0) // Remove the application path argument
        
        // I find that if the current directory is within a symbolic link then
        // using FileManager.currentDirectoryPath will return the real path not
        // the using path.  So we will try and get the path from the PWD
        let projectDir = environment["PWD"] ?? FileManager.default.currentDirectoryPath
        
        let packageName = NSString(string: projectDir).lastPathComponent

        //let workingProjectDir = FileManager.default.currentDirectoryPath

        func printUsage(withMessage message: String? = nil) {
            if let msg = message {
                print(msg)
            }
            print("\(appName) [OPTIONS] [CONTAINER ARGUMENTS]")
            if let desc = appUsageDescription {
                print(desc)
            }
            
            let optionArguments: [(arguments: String, description: String)] = [
                Argument.helpArgument.helpDisplayObjects(),
                Argument.versionArgument.helpDisplayObjects(),
            ] + Arguments.noReplacement.map({ return $0.helpDisplayObjects() })
            
            
            var maxArgumentCharacters: Int = optionArguments[0].arguments.count
            for obj in optionArguments {
                if obj.arguments.count > maxArgumentCharacters {
                    maxArgumentCharacters = obj.arguments.count
                }
            }
            
            
            print("")
            print("OPTIONS:")
            for obj in optionArguments {
                var line = obj.arguments
                while line.count < maxArgumentCharacters {
                    line += " " // Make all argument strings the same length
                }
                line += "     " // add 'tab' after arguments
                line += obj.description // add argument description
                print(line)
            }
        }


        // Docker Arguments
        var buildDirPath: String? = nil
        var swiftRepoOrder: [DockerRepoContainerApp] = []
        var env: [String: String] = [:]
        var volumeMapping: [Docker.VolumeMapping] = []
        var mountMapping: [Docker.MountMapping] = []
        var dockerPath: String? = nil

        var tag: DockerHub.RepositoryTag = "latest"

        var dockerContainerArguments: [String] = []

        var randGenerator = SystemRandomNumberGenerator()

        var currentArgumentIndex: Int = 0
        while currentArgumentIndex < arguments.count {
            if let _ = Argument.helpArgument.parse(arguments: arguments,
                                                   startingAt: &currentArgumentIndex) {
                printUsage()
                return 0
            } else if let _ = Argument.versionArgument.parse(arguments: arguments,
                                                             startingAt: &currentArgumentIndex) {
                print("\(appName) version \(DockerHubList.version)")
                return 0
            } else if let parsed = Arguments.swiftRepoOrderArgument.parse(arguments: arguments,
                                                                          startingAt: &currentArgumentIndex,
                                                                          currentParsedValue: swiftRepoOrder) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                swiftRepoOrder = parsed.object as! [DockerRepoContainerApp]
            } else if let parsed = Arguments.buildDirArgument.parse(arguments: arguments,
                                                                    startingAt: &currentArgumentIndex) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                buildDirPath = parsed.object as? String
            } else if let parsed = Arguments.tagArgument.parse(arguments: arguments,
                                                               startingAt: &currentArgumentIndex,
                                                               currentParsedValue: tag) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                tag = (parsed.object as? DockerHub.RepositoryTag) ?? tag
            } else if let parsed = Arguments.envArgument.parse(arguments: arguments,
                                                               startingAt: &currentArgumentIndex,
                                                               currentParsedValue: env) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                env = (parsed.object as? [String: String]) ?? env
            } else if let parsed = Arguments.mountArgument.parse(arguments: arguments,
                                                                 startingAt: &currentArgumentIndex,
                                                                 currentParsedValue: mountMapping) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                mountMapping = (parsed.object as? [Docker.MountMapping]) ?? mountMapping
            } else if let parsed = Arguments.volumeArgument.parse(arguments: arguments,
                                                                  startingAt: &currentArgumentIndex,
                                                                  currentParsedValue: volumeMapping) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                volumeMapping = (parsed.object as? [Docker.VolumeMapping]) ?? volumeMapping
            } else if let parsed = Arguments.dockerPathArgument.parse(arguments: arguments, startingAt: &currentArgumentIndex) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                dockerPath = (parsed.object as? String) ?? dockerPath
            } else {
                let range = currentArgumentIndex..<arguments.count
                dockerContainerArguments.append(contentsOf: arguments[range])
                currentArgumentIndex = arguments.count
                
            }
        }
        
        if dockerPath == nil {
            guard let defaultDockerPath = Docker.DefaultDockerPathFromENV else {
                printUsage(withMessage: "Unable to locate docker")
                return 1
            }
            dockerPath = defaultDockerPath
        }

        if swiftRepoOrder.isEmpty {
            swiftRepoOrder.append("swift")
        }
        
        
        if !volumeMapping.contains(where: { return projectDir.hasPrefix($0.realPath) }) {
            volumeMapping.append(.init(physicalPath: projectDir, virtualPath: projectDir))
        }
        
        if let bd = buildDirPath {
            if !FileManager.default.fileExists(atPath: bd) {
                do {
                    try FileManager.default.createDirectory(atPath: bd, withIntermediateDirectories: true)
                } catch {
                    print("Failed to create Build Dir '\(bd)': \(error)")
                    return 1
                }
            }
            let virtualBuildDir = NSString(string: projectDir).appendingPathComponent(".build")
            volumeMapping.append(.init(physicalPath: bd,
                                       virtualPath: virtualBuildDir))
        }

        let workingTag = tag

        var workingContainerApp: DockerRepoContainerApp!

        do {

            var imageTestResp: (terminationStatus: Int32, out: String, err: String)! = nil
            for containerApp in swiftRepoOrder {
                
                // Do docker check
                // check to see if we have the docker image locally
                imageTestResp = try Docker.captureSeparate(dockerPath: dockerPath,
                                                           arguments: ["images",
                                                                  "-q",
                                                                  "\(containerApp.name):\(workingTag)"])
                if imageTestResp.terminationStatus == 0 &&
                   !imageTestResp.out.isEmpty {
                    workingContainerApp = containerApp
                    break
                }
            }

            if workingContainerApp == nil {
                for containerApp in swiftRepoOrder where !containerApp.name.isLocal {
                    // try pulling the image from the server
                    imageTestResp = try Docker.captureSeparate(dockerPath: dockerPath,
                                                               arguments: ["pull",
                                                                  "\(containerApp.name):\(workingTag)"])
                    if imageTestResp.terminationStatus == 0 {
                        workingContainerApp = containerApp
                        break
                    }
                }
            }

            guard workingContainerApp != nil else {
                
                print("Unable to find a usable repository name in " + swiftRepoOrder.map({ return "'\($0.name)'" }).joined(separator: ",") + " with tag '\(workingTag)'")
                print(imageTestResp.err)
                return 1
            }


            imageTestResp = nil
            
            let repoName: DockerHub.RepositoryName = workingContainerApp.name
            //let containerCommand = workingContainerApp.app
            
            
            
            let ret: Int32 = try Docker.runContainer(dockerPath: dockerPath,
                                                     image: "\(repoName):\(workingTag)",
                                           containerName: Docker.genSwiftContName(command: "bash" /*containerCommand*/,
                                                                                  tag: workingTag,
                                                                                  //subCommand: "bash",
                                                                                  packageName: packageName,
                                                                                  using: &randGenerator),
                                           dockerArguments: ["--cap-add=SYS_PTRACE",
                                                             "--security-opt",
                                                             "seccomp=unconfined"],
                                           autoRemove: true,
                                                     attachInput: true,
                                                     detach: true,
                                           dockerEnvironment: env,
                                           volumeMapping: volumeMapping,
                                           containerWorkingDirectory: projectDir,
                                           containerCommand: "bash" /*containerCommand*/,
                                           containerArguments: /*["bash"] +*/ dockerContainerArguments,
                                           showCommand: false,
                                                     hideOutput: false)
            exit(ret)
            
        } catch {
            print("Fatal Error trying container '\(workingContainerApp.name):\(workingTag)'")
            print(error)
            return 1
        }
        
    }
    
}


