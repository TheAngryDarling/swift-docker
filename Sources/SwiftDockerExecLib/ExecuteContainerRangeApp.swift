//
//  ExecuteContainerRangeApp.swift
//  
//
//  Created by Tyler Anger on 2022-04-03.
//

import Foundation
import Dispatch
#if os(macOS)
import AppKit
#endif
import RegEx
import SwiftDockerCoreLib
import SwiftPatches

/// Had to set this as a global variable for signal trap to have access to it
fileprivate var ramDisk: RamDisk? = nil


public enum DockerContainerRangeApp {
    
    public static let version: String = "1.0.7"
    /// Collection of aruguments that this CLI Application collects
    public enum Arguments {
        
        public static var swiftRepoOrderArgument: Argument {
            return DockerContainerApp.Arguments.swiftRepoOrderArgument
        }
        
        public static let swiftRepoOrderFirstArgument = Argument(short: "srof",
                                                                 long: "swiftRepoOrderFirst",
                                                                 additionalParamName: "list",
                                                                 description: "A ';' separated list of repo:{container cli app} to try and use as the swift image / swift app for the first tag in the list (Optional)") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Swift Repo Order First List Parameter")
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
        
        public static var buildDirArgument: Argument {
            return DockerContainerApp.Arguments.buildDirArgument
        }
        public static let buildAllDirArgument = Argument(long: "buildAllDir",
                                    additionalParamName: "path",
                                    description: "The location where all the tags .build dir are located. (Optional)") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Build Dir")
            }
            
            let path = arguments[currentIndex]
            currentIndex += 1
            return .parsed(path)
        }
        
        public static let cleanBuildDirArgument = Argument(short: "cbd",
                                                    long: "cleanBuildDir",
                                                   description: "Clean build directory before each build")
        
        public static var tagArgument: Argument {
            return DockerContainerApp.Arguments.tagArgument
        }
        
        public static var envArgument: Argument {
            return DockerContainerApp.Arguments.envArgument
        }
        
        public static var volumeArgument: Argument {
            return DockerContainerApp.Arguments.volumeArgument
        }
        
        public static var mountArgument: Argument {
            return DockerContainerApp.Arguments.mountArgument
        }
        
        public static var outputReplacementArgument: Argument {
            return DockerContainerApp.Arguments.outputReplacementArgument
        }
        
        public static var outputReplacementXArgument: Argument {
            return DockerContainerApp.Arguments.outputReplacementXArgument
        }
        
        
        public static let stopOnFirstErrorArgument = Argument(long: "stopOnFirstError",
                                                        description: "Stop when first non-retryable error occurs")
        
        public static let skipIdenticalHashesArgument = Argument(long: "skipIdenticalHashes",
                                                        description: "Skip any tags with identical hashs as previously used tags")
        
        public static var dockerPathArgument: Argument {
            return DockerContainerApp.Arguments.dockerPathArgument
        }
        /// List of all CLI Arguments this application uses
        public static let all: [Argument] = [swiftRepoOrderArgument,
                                             swiftRepoOrderFirstArgument,
                                             stopOnFirstErrorArgument,
                                             skipIdenticalHashesArgument,
                                             buildDirArgument,
                                             buildAllDirArgument,
                                             cleanBuildDirArgument,
                                             envArgument,
                                             mountArgument,
                                             volumeArgument,
                                             outputReplacementArgument,
                                             outputReplacementXArgument,
                                             dockerPathArgument]
    }
    
    /// Execute the action with in the range of swift docker tags
    /// - Parameters:
    ///   - arguments: CLI Arguments
    ///   - environment: CLI Enviroment
    ///   - action: The action to perform
    /// - Returns: Returns the error code
    public static func execute(arguments: [String] = ProcessInfo.processInfo.arguments,
                               environment: [String: String] = ProcessInfo.processInfo.environment,
                               action: DockerSwiftAction.Type) -> Int32 {
        
        let appUsageDescription = action.rangeActionAppDescription
        let swiftSubCommand = action.swiftSubCommand
        let primaryActionMessage = action.primaryActionMessage
        let retryingMessage = action.retryingMessage
        let errorMessage = action.errorMessage
        let warningMessage = action.warningMessage
        let successfulMessage = action.successfulMessage
        
        do {
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

            let workingProjectDir = FileManager.default.currentDirectoryPath


            let fromArgument = Argument(long: "from",
                                        additionalParamName: "tag",
                                        description: "From tag.  Where to start within the tag list (Optional)") {
                (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
                guard currentIndex < arguments.count else {
                    return .failedToParse(message: "Missing From Tag")
                }
                
                let sTag = arguments[currentIndex]
                currentIndex += 1
                guard let tag = DockerHub.RepositoryTag(sTag) else {
                    return .failedToParse(message: "Invalid From Tag '\(sTag)'")
                }
                return .parsed(tag)
            }

            let toArgument = Argument(long: "to",
                                      additionalParamName: "tag",
                                      description: "To tag,  The tag to stop before (Optional)") {
                (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
                guard currentIndex < arguments.count else {
                    return .failedToParse(message: "Missing To Tag")
                }
                
                let sTag = arguments[currentIndex]
                currentIndex += 1
                guard let tag = DockerHub.RepositoryTag(sTag) else {
                    return .failedToParse(message: "Invalid To Tag '\(sTag)'")
                }
                return .parsed(tag)
            }

            let throughArgument = Argument(long: "through",
                                           additionalParamName: "tag",
                                           description: "Through tag.  The last tag before stopping (Optional)") {
                (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
                guard currentIndex < arguments.count else {
                    return .failedToParse(message: "Missing Through Tag")
                }
                
                let sTag = arguments[currentIndex]
                currentIndex += 1
                guard let tag = DockerHub.RepositoryTag(sTag) else {
                    return .failedToParse(message: "Invalid Through Tag '\(sTag)'")
                }
                return .parsed(tag)
            }

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
                    fromArgument.helpDisplayObjects(),
                    toArgument.helpDisplayObjects(),
                    throughArgument.helpDisplayObjects(),
                ]
                
                
                let listTagOptions = DockerHubList.Arguments.listTagArguments.map({ return $0.helpDisplayObjects() })
                
                let dockerArgumets = Arguments.all.map({ return $0.helpDisplayObjects() })
                
                
                let allOptions: [(arguments: String, description: String)] = optionArguments + listTagOptions + dockerArgumets
                
                var maxArgumentCharacters: Int = optionArguments[0].arguments.count
                for obj in allOptions {
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
                
                print("")
                print("TAG LIST OPTIONS:")
                for obj in listTagOptions {
                    var line = obj.arguments
                    while line.count < maxArgumentCharacters {
                        line += " " // Make all argument strings the same length
                    }
                    line += "     " // add 'tab' after arguments
                    line += obj.description // add argument description
                    print(line)
                }
                
                print("")
                print("DOCKER OPTIONS:")
                for obj in dockerArgumets {
                    var line = obj.arguments
                    while line.count < maxArgumentCharacters {
                        line += " " // Make all argument strings the same length
                    }
                    line += "     " // add 'tab' after arguments
                    line += obj.description // add argument description
                    print(line)
                }
            }

            // Docker Hub List Arguments
            var filter: [String] = []
            var filterX: [RegEx] = []
            var excludeFilter: [String] = []
            var excludeFilterX: [RegEx] = []
            var cacheFolder: String? = nil
            var cacheDuration: TimeInterval? = nil
            var useCacheOnFailure: Bool = false
            var cachingUse: DockerHubList.Caching.CacheUse = .default

            // Docker Arguments
            var swiftRepoOrder: [DockerRepoContainerApp] = []
            var buildDirPath: String? = nil
            var buildAllDirPath: String? = nil
            var cleanBuildDir: Bool = false
            var env: [String: String] = [:]
            var volumeMapping: [Docker.VolumeMapping] = []
            var mountMapping: [Docker.MountMapping] = []
            var findReplace: [String: String] = [:]
            var findReplaceX: [RegEx: String] = [:]
            var dockerPath: String? = nil


            var dockerContainerArguments: [String] = []

            var swiftRepoOrderFirst: [DockerRepoContainerApp]? = nil
            var stopOnFirstError: Bool = false
            var skipIdenticalHashes: Bool = false

            var fromTag: DockerHub.RepositoryTag? = nil
            var toTag: DockerHub.RepositoryTag? = nil
            var throughTag: DockerHub.RepositoryTag? = nil
            
            // Should set this a var and have a cli argument change the value
            let executionTimoutDurationInSec: Int? = (60 * 5) // 5min

            var currentArgumentIndex: Int = 0
            while currentArgumentIndex < arguments.count {
                if let _ = Argument.helpArgument.parse(arguments: arguments,
                                                       startingAt: &currentArgumentIndex) {
                    printUsage()
                    return 0
                } else if let _ = Argument.versionArgument.parse(arguments: arguments,
                                                                 startingAt: &currentArgumentIndex) {
                    print("\(appName) version \(DockerContainerRangeApp.version)")
                    return 0
                } else if let parsed = fromArgument.parse(arguments: arguments,
                                                          startingAt: &currentArgumentIndex) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    fromTag = parsed.object as? DockerHub.RepositoryTag
                } else if let parsed = toArgument.parse(arguments: arguments,
                                                        startingAt: &currentArgumentIndex) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    toTag = parsed.object as? DockerHub.RepositoryTag
                } else if let parsed = throughArgument.parse(arguments: arguments,
                                                             startingAt: &currentArgumentIndex) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    throughTag = parsed.object as? DockerHub.RepositoryTag
                } else if let parsed = DockerHubList.Arguments.filterArgument.parse(arguments: arguments,
                                                                                    startingAt: &currentArgumentIndex,
                                                                                    currentParsedValue: filter) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    filter = parsed.object as! [String]
                } else if let parsed = DockerHubList.Arguments.filterXArgument.parse(arguments: arguments,
                                                                                     startingAt: &currentArgumentIndex,
                                                                                     currentParsedValue: filter) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    filterX = parsed.object as! [RegEx]
                } else if let parsed = DockerHubList.Arguments.excludeArgument.parse(arguments: arguments,
                                                                                     startingAt: &currentArgumentIndex,
                                                                                     currentParsedValue: excludeFilter) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    excludeFilter = parsed.object as! [String]
                } else if let parsed = DockerHubList.Arguments.excludeXArgument.parse(arguments: arguments,
                                                                                      startingAt: &currentArgumentIndex,
                                                                                      currentParsedValue: excludeFilter) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    excludeFilterX = parsed.object as! [RegEx]
                } else if let parsed = DockerHubList.Arguments.ignoreCacheArgument.parse(arguments: arguments,
                                                                                    startingAt: &currentArgumentIndex,
                                                                                    currentParsedValue: cachingUse) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    cachingUse = (parsed.object as? DockerHubList.Caching.CacheUse) ?? .default
                } else if let parsed = DockerHubList.Arguments.useCacheOnlyArgument.parse(arguments: arguments,
                                                                                         startingAt: &currentArgumentIndex,
                                                                                         currentParsedValue: cachingUse) {
                         if let error = parsed.errorMessage {
                             printUsage(withMessage: error)
                             return 1
                         }
                         cachingUse = (parsed.object as? DockerHubList.Caching.CacheUse) ?? .default
                     } else if let parsed = DockerHubList.Arguments.cacheFolderArgument.parse(arguments: arguments, startingAt: &currentArgumentIndex) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    cacheFolder = parsed.object as? String
                } else if let parsed = DockerHubList.Arguments.cacheDurationArgument.parse(arguments: arguments,
                                                                                           startingAt: &currentArgumentIndex) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    cacheDuration = parsed.object as? TimeInterval
                } else if let parsed = DockerHubList.Arguments.useCacheOnFailureArgument.parse(arguments: arguments,
                                                                                               startingAt: &currentArgumentIndex) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    useCacheOnFailure = parsed.object as? Bool ?? false
                } else if let parsed = Arguments.swiftRepoOrderArgument.parse(arguments: arguments,
                                                                             startingAt: &currentArgumentIndex,
                                                                             currentParsedValue: swiftRepoOrder) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    swiftRepoOrder = parsed.object as! [DockerRepoContainerApp]
                } else if let parsed = Arguments.swiftRepoOrderFirstArgument.parse(arguments: arguments,
                                                                                   startingAt: &currentArgumentIndex,
                                                                                   currentParsedValue: swiftRepoOrderFirst) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    swiftRepoOrderFirst = parsed.object as? [DockerRepoContainerApp]
                } else if let _ = Arguments.stopOnFirstErrorArgument.parse(arguments: arguments,
                                                                           startingAt: &currentArgumentIndex) {
                    stopOnFirstError = true
                } else if let _ = Arguments.skipIdenticalHashesArgument.parse(arguments: arguments,
                                                                              startingAt: &currentArgumentIndex) {
                    skipIdenticalHashes = true
                } else if let parsed = Arguments.buildDirArgument.parse(arguments: arguments,
                                                                        startingAt: &currentArgumentIndex) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    buildDirPath = parsed.object as? String
                } else if let parsed = Arguments.buildAllDirArgument.parse(arguments: arguments,
                                                                           startingAt: &currentArgumentIndex) {
                    if let error = parsed.errorMessage {
                        printUsage(withMessage: error)
                        return 1
                    }
                    buildAllDirPath = parsed.object as? String
                } else if let _ = Arguments.cleanBuildDirArgument.parse(arguments: arguments,
                                                                        startingAt: &currentArgumentIndex) {
                    cleanBuildDir = true
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
                // if swiftRepoOrder was no set then we will set it to swift as default
                swiftRepoOrder.append("swift")
            }

            let parsedCaching = DockerHubList.Caching.parse(cacheFolder: cacheFolder,
                                                      expiryDuration: cacheDuration,
                                                      useCacheOnFailure: useCacheOnFailure,
                                                      cacheUse: cachingUse)

            if let msg = parsedCaching.errorMessage {
                printUsage(withMessage: msg)
                return 1
            }


            if toTag != nil && throughTag != nil {
                printUsage(withMessage: "Arguments --to and --through can not be used together")
                return 1
            }
            
            if buildDirPath != nil && buildAllDirPath != nil {
                printUsage(withMessage: "Arguments --buildDir and --buildAllDir can not be used together")
                return 1
            }
            
            let allTags: [DockerHub.RepositoryTagDetails]
            do {
                // assume any swift docker repository we are going to use uses the same tagging system
                allTags = try DockerHubList.getTagDetails(for: "swift",
                                                             filter: filter,
                                                             filterX: filterX,
                                                             excludeFilter: excludeFilter,
                                                             excludeFilterX: excludeFilterX,
                                                             caching: parsedCaching.object!)
            } catch {
                print("Fatal Error: Unable to get list of tags")
                print(error)
                return 1
            }

            guard !allTags.isEmpty else {
                print("No tags available with the given parameters")
                return 1
            }

            if fromTag == nil {
                fromTag = allTags.first!.name
            }

            guard var lowerIdx = allTags.index(where: { return $0.name == fromTag! }) else {
                printUsage(withMessage: "Unable to find Repository Tag '\(fromTag!)' with list of tags")
                return 1
            }

            var upperBounds: Int = allTags.count
            if let t = toTag {
                guard let idx = allTags.index(where: { return $0.name == t }) else {
                    printUsage(withMessage: "Unable to find To Repository Tag '\(fromTag!)' with list of tags")
                    return 1
                }
                upperBounds = idx
            } else if let t = throughTag {
                guard let idx = allTags.index(where: { return $0.name == t }) else {
                    printUsage(withMessage: "Unable to find Through Repository Tag '\(fromTag!)' with list of tags")
                    return 1
                }
                upperBounds = idx + 1
            }

            
            defer {
                do {
                    try ramDisk?.remove()
                    ramDisk = nil
                } catch {
                    print("Failed to remove RamDisk '[\(ramDisk!.disk)]:\(ramDisk!.mountPath)'")
                    print(error)
                }
                
            }
            
            
            
            OSSignal.allCases.trapSignals() { _ in
                try? ramDisk?.remove()
                exit(EXIT_FAILURE)
            }

            func packgeSizeFilterDir(_ url: URL) -> Bool {
                let path = url.path
                return !path.contains("/.git/") && // ignore any git folder
                       !path.hasSuffix("/.git") && // ignore any git folder
                       !path.contains("/.swiftpm/") && // ignore any swiftpm folder
                       !path.hasSuffix("/.swiftpm") && // ignore any swiftpm folder
                       !path.contains(".xcodeproj/") && // ignore xcode project folder
                       !path.hasSuffix(".xcodeproj") && // ignore xcode project folder
                       !path.hasSuffix(".DS_Store") // ignore xcode project folder
            }

            func packgeCopyFilterDir(_ url: URL) -> Bool {
                let path = url.path
                return packgeSizeFilterDir(url) && // ignore any git folder
                       !path.contains("/.build/") && // ignore any build folder
                       !path.hasSuffix("/.build")  // ignore any build folder
            }

            var workingBuildDir = NSString(string: workingProjectDir).appendingPathComponent(".build")
            
            do {
                if RamDisk.ramDiskSupported,
                   var fileSize = try FileManager.default.fileAllocatedSize(atPath: workingProjectDir,
                                                                            filtering: packgeCopyFilterDir), fileSize > 0 {
                    
                    // If fileSize is < 3MB
                    if fileSize < (1024 * 1024 * 3) {
                        // We reset fileSize to 3MB
                        fileSize = 1024 * 1024 * 3
                    }
                    // we create ram disk 50 times the size of the project folder
                    let rDisk = try RamDisk.create(byteSize: Int(Double(fileSize) * 50),
                                                   volumeName: packageName + "-" + (swiftSubCommand ?? "execute") + "-range")
                    // Keep referene to rDisk for defer (teardown)
                    ramDisk = rDisk
                    
                    print("Moving Project '\(packageName)' to RamDrive ('\(rDisk.mountPath)')")
                    // copy project from current directory to RamDisk
                    let children = try FileManager.default.contentsOfDirectory(at: URL(fileURLWithPath: projectDir, isDirectory: true), includingPropertiesForKeys: nil )
                    
                    for child in children {
                        if packgeCopyFilterDir(child) {
                            let dest = child.path.replacingOccurrences(of: workingProjectDir,
                                                                 with: rDisk.mountPath)
                            try FileManager.default.copyItem(atPath: child.path,
                                                             toPath: dest)
                        }
                    }
                    print("\u{1B}[2K", terminator: "") //errase line
                    print("\u{1B}[1A\u{1B}[2K", terminator: "") //move up one line
                    
                    print("Moved Project '\(packageName)' to RamDrive ('\(rDisk.mountPath)')")
                    volumeMapping.append(.init(physicalPath: rDisk.mountPath, virtualPath: projectDir))
                    
                    workingBuildDir = NSString(string: rDisk.mountPath).appendingPathComponent(".build")
                }
            } catch {
                print("\u{1B}[2K", terminator: "") //errase line
                print("\u{1B}[1A\u{1B}[2K", terminator: "") //move up one line
                print("There was an error while trying to create RamDisk for project")
                print(error)
                
                do {
                    try ramDisk?.remove()
                    ramDisk = nil
                } catch {
                    print("Failed to remove RamDisk '[\(ramDisk!.disk)]:\(ramDisk!.mountPath)'")
                    print(error)
                }
                
            }
            
            if let bd = buildDirPath {
                if !FileManager.default.fileExists(atPath: bd) {
                    do {
                        try FileManager.default.createDirectory(atPath: bd,
                                                                withIntermediateDirectories: true)
                    } catch {
                        print("Failed to create Build Dir '\(bd)': \(error)")
                        return 1
                    }
                }
                let virtualBuildDir = NSString(string: projectDir).appendingPathComponent(".build")
                volumeMapping.append(.init(physicalPath: bd,
                                           virtualPath: virtualBuildDir))
                workingBuildDir = bd
            } else if let bd = buildAllDirPath {
                // We try and test / create build all dir
                // just incase there is a problem it occurs before
                // actually trying to build the container
                if !FileManager.default.fileExists(atPath: bd) {
                    do {
                        try FileManager.default.createDirectory(atPath: bd,
                                                                withIntermediateDirectories: true)
                    } catch {
                        print("Failed to create Build All Dir '\(bd)': \(error)")
                        return 1
                    }
                }
                workingBuildDir = ""
            }
            


            var randGenerator = SystemRandomNumberGenerator()


            var toolsVersion: String = ""
            do {
                print("Getting Tools-Version of package")
                let packageToolVerResp = try Docker.runContainer(dockerPath: dockerPath,
                                                                 image: "swift:latest",
                                                                 containerName: Docker.genSwiftContName(command: "swift",
                                                                                                        tag: "latest",
                                                                                                        packageName: packageName,
                                                                                                        using: &randGenerator,
                                                                                                        additionInfo: "tools-version"),
                                                                 
                                                                     dockerArguments: ["--cap-add=SYS_PTRACE",
                                                                                       "--security-opt",
                                                                                       "seccomp=unconfined"],
                                                                     autoRemove: true,
                                                                     dockerEnvironment: env,
                                                                     volumeMapping: volumeMapping,
                                                                     containerWorkingDirectory: projectDir,
                                                                     containerCommand: "swift",
                                                                     containerArguments: ["package", "tools-version"])
                guard packageToolVerResp.terminationStatus == 0 else {
                    print("Failed to get tools-version for package:")
                    print(packageToolVerResp.output)
                    return 1
                }
                
                toolsVersion = packageToolVerResp.output
                toolsVersion = toolsVersion.replacingOccurrences(of: "\r\n", with: "\n")
                toolsVersion = String(toolsVersion.split(separator: "\n")[0])
                
                // Get all 'Package@swift-...swift' files
                var altPackageFiles = (try FileManager.default.contentsOfDirectory(atPath: projectDir)).filter({ return $0.hasPrefix("Package@swift-") && $0.lowercased().hasSuffix(".swift") })
                // Remove 'Package@swift-' from file names
                altPackageFiles = altPackageFiles.map({ return $0.replacingOccurrences(of: "Package@swift-", with: "") })
                // Remove .swift file extension
                altPackageFiles = altPackageFiles.map({ return NSString(string: $0).deletingPathExtension })
                /// Convert version numbers into #.#.# format
                altPackageFiles = altPackageFiles.map {
                    var rtn = $0
                    while rtn.split(separator: ".").count < 3 {
                        rtn += ".0"
                    }
                    return rtn
                }
                // Add current tools version to the list
                altPackageFiles.append(toolsVersion)
                // Sort the list of versions
                altPackageFiles.sort()
                // The first tools-version will be the
                // earliest version of swift this package
                // supports compiling with
                toolsVersion = altPackageFiles[0]
                
                
                print("Found base Tools-Version: '\(toolsVersion)'")
                
            } catch {
                print("Fatal Error: Failed to get tools-version for package: \(error)")
                return 1
            }

            // Find the index of the tools-version of the package
            if let toolsVerIndex = allTags.firstIndex(where: { return $0.name.versionValue == toolsVersion }) {
                // if the tools-version is after the from tag then we move change to start at the tools-version tag
                if toolsVerIndex > lowerIdx {
                    //print("Warning: Package has a higher minimun requirement for tools-verion of '\(toolsVersion)'.  Adjusting from tag to new value")
                    lowerIdx = toolsVerIndex
                }
            }
            let startTotalTime = Date()
            var totalTagsTested: Int = 0
            var passedCount: Int = 0
            var skippedCount: Int = 0
            var warningCount: Int = 0
            var errorCount: Int = 0


            var warningTags: [DockerHub.RepositoryTag] = []
            var failureTags: [DockerHub.RepositoryTag] = []


            guard lowerIdx < upperBounds else {
                if let to = toTag {
                    print("No tags available between \(allTags[lowerIdx])..<\(to)")
                } else if let through = throughTag {
                    print("No tags available between \(allTags[lowerIdx])...\(through)")
                } else {
                    print("No tags available between \(allTags[lowerIdx])...")
                }
                return 1
            }
            let totalTests = (upperBounds-lowerIdx)
            print("Expected Test Count: \(totalTests)")
            var stop: Bool = false
            var usedTagsDetails: [DockerHub.RepositoryTagDetails] = []
            // Loop through the list of tags to test
            
            let totalTestsCharCount = "\(totalTests)".count
            
            for i in lowerIdx..<upperBounds where !stop {
                let currentTest = (i-lowerIdx) + 1
                var sCurrentTest = "\(currentTest)"
                while sCurrentTest.count < totalTestsCharCount {
                    sCurrentTest = " " + sCurrentTest
                }
                
                let tagDetails = allTags[i]
                
                let currentTag = tagDetails.name
                
                let currentHashes = tagDetails.digests
                
                if skipIdenticalHashes,
                    let tag = usedTagsDetails.first(where: { return currentHashes.containsAny($0.digests) }) {
                    skippedCount += 1
                    print("[\(sCurrentTest)/\(totalTests)]: Skipping '\(currentTag)' because it matches '\(tag.name)' ")
                    continue
                }
                
                usedTagsDetails.append(tagDetails)
                
                var displayTagName = ":" + currentTag.description
                if skipIdenticalHashes {
                    displayTagName = ":("
                    displayTagName += allTags[lowerIdx..<upperBounds]
                            .filter { return $0.digests.containsAny(currentHashes) }
                            .map { return $0.name.description }
                            .joined(separator: ", ")
                    displayTagName += ")"
                }
                
                
                var workingVolumeMappings = volumeMapping
                
                // If we have a build all dir
                // that means we have a folder location to store
                // seperate build folder for each tag being used
                if var bd = buildAllDirPath {
                    bd = NSString(string: bd).appendingPathComponent("\(currentTag)")
                    if !FileManager.default.fileExists(atPath: bd) {
                        do {
                            try FileManager.default.createDirectory(atPath: bd, withIntermediateDirectories: true)
                        } catch {
                            print("[\(sCurrentTest)/\(totalTests)]: Failed to create Build All Tag Dir '\(bd)': \(error)")
                            return 1
                        }
                        let virtualBuildDir = NSString(string: projectDir).appendingPathComponent(".build")
                        workingVolumeMappings.append(.init(physicalPath: bd,
                                                           virtualPath: virtualBuildDir))
                        
                    }
                }
                
                if cleanBuildDir && !workingBuildDir.isEmpty {
                    let fileManager = FileManager.default
                    // Try and clean build directory
                    if fileManager.fileExists(atPath: workingBuildDir) {
                        let nsWorkingBuildDir = NSString(string: workingBuildDir)
                        let linuxBuildDir = nsWorkingBuildDir.appendingPathComponent("x86_64-unknown-linux")
                        if fileManager.fileExists(atPath: linuxBuildDir) {
                            try? fileManager.removeItem(atPath: linuxBuildDir)
                        }
                    }
                }
                
                if let disk = ramDisk {
                    if disk.fsPercentFree < 50 &&
                       disk.fsFreeSize < disk.originalSize {
                        // If our RamDisk is running out of space
                        // Lets resize it by adding and additional (original size worth of) bytes
                        print("Re-sizing RamDisk")
                        try disk.resize(addingBytes: disk.originalSize)
                    }
                }
                totalTagsTested += 1
                
                var workingContainerApp: DockerRepoContainerApp!
                
                var workingContainerAppList = swiftRepoOrder
                
                if i == lowerIdx,
                    let repoFirst = swiftRepoOrderFirst {
                    workingContainerAppList = repoFirst
                }
                
                
                var imageTestResp: (terminationStatus: Int32, out: String, err: String)! = nil
                for containerApp in workingContainerAppList {
                    
                    // Do docker check
                    // check to see if we have the docker image locally
                    imageTestResp = try Docker.captureSeparate(dockerPath: dockerPath,
                                                               arguments: ["images",
                                                                      "-q",
                                                                      "\(containerApp.name):\(currentTag)"])
                    if imageTestResp.terminationStatus == 0 &&
                       !imageTestResp.out.isEmpty {
                        workingContainerApp = containerApp
                        break
                    }
                }
                
                if workingContainerApp == nil {
                    for containerApp in workingContainerAppList where !containerApp.name.isLocal {
                        // try pulling the image from the server
                        imageTestResp = try Docker.captureSeparate(dockerPath: dockerPath,
                                                                   arguments: ["pull",
                                                                      "\(containerApp.name):\(currentTag)"])
                        if imageTestResp.terminationStatus == 0 {
                            workingContainerApp = containerApp
                            break
                        }
                    }
                }
                
                guard workingContainerApp != nil else {
                    
                    print("[\(sCurrentTest)/\(totalTests)]: Unable to find a usable repository name in " + workingContainerAppList.map({ return "'\($0.name)'" }).joined(separator: ",") + " with tag '\(currentTag)'")
                    print(imageTestResp.err)
                    exit(1)
                }
                
                
                imageTestResp = nil
                
                do {
                    // Try and remove dependencies-state.json since sometimes with
                    // different versions if swift the different versions of dependencies-state.json
                    // aren't supported
                    let dependenciesStateJSON = NSString(string: NSString(string: projectDir).appendingPathComponent(".build")).appendingPathComponent("dependencies-state.json")
                    if FileManager.default.fileExists(atPath: dependenciesStateJSON) {
                        try? FileManager.default.removeItem(atPath: dependenciesStateJSON)
                    }
                    
                    let repoName: DockerHub.RepositoryName = workingContainerApp.name
                    let containerCommand = workingContainerApp.app
                    
                    let workingTag: DockerHub.RepositoryTag = currentTag
                    
                    if i == lowerIdx {
                        print("Downloading any dependencies")
                        // If this is the first build, we will do {swift} package update
                        // to download all dependancies
                        let ret = try? Docker.runContainer(dockerPath: dockerPath,
                                                           image: "\(repoName):\(workingTag)",
                                                         containerName: Docker.genSwiftContName(command: containerCommand,
                                                                                                tag: workingTag,
                                                                                                subCommand: swiftSubCommand,
                                                                                                packageName: packageName,
                                                                                                using: &randGenerator,
                                                                                                additionInfo: "update"),
                                                         dockerArguments: ["--cap-add=SYS_PTRACE",
                                                                           "--security-opt",
                                                                           "seccomp=unconfined"],
                                                         autoRemove: true,
                                                         dockerEnvironment: env,
                                                         volumeMapping: workingVolumeMappings,
                                                         containerWorkingDirectory: projectDir,
                                                         containerCommand: containerCommand,
                                                         containerArguments: ["package", "update"],
                                                         hideOutput: true)
                        
                        
                        // See if downloading packages caused a the RamDisk to run out of space
                        if ret != 0,
                           let disk = ramDisk {
                               if disk.fsPercentFree < 50 &&
                                  disk.fsFreeSize < disk.originalSize {
                                   // If our RamDisk is running out of space
                                   // Lets resize it by adding and additional (original size worth of) bytes
                                   print("RamDisk too small.  Resizing...")
                                   try disk.resize(addingBytes: disk.originalSize)
                                   
                                   _ = try? Docker.runContainer(dockerPath: dockerPath,
                                                                image: "\(repoName):\(workingTag)",
                                                                    containerName: Docker.genSwiftContName(command: containerCommand,
                                                                                                           tag: workingTag,
                                                                                                           subCommand: swiftSubCommand,
                                                                                                           packageName: packageName,
                                                                                                           using: &randGenerator,
                                                                                                           additionInfo: "update"),
                                                                    dockerArguments: ["--cap-add=SYS_PTRACE",
                                                                                      "--security-opt",
                                                                                      "seccomp=unconfined"],
                                                                    autoRemove: true,
                                                                    dockerEnvironment: env,
                                                                    volumeMapping: workingVolumeMappings,
                                                                    containerWorkingDirectory: projectDir,
                                                                    containerCommand: containerCommand,
                                                                    containerArguments: ["package", "update"],
                                                                    hideOutput: true)
                               }
                        }
                    }
                    
                    var retryCount: Int = 0
                    var resp: (terminationStatus: Int32, output: String)? = nil
                    var shouldOutputResponse: Bool = false
                    var retryCountNaming: String? = nil
                    
                    var workingArguments: [String] = action.preSubCommandArguments(callType: .singular,
                                                                                   image: workingContainerApp,
                                                                                   tag: workingTag,
                                                                                   userArguments: dockerContainerArguments)
                    if let subCommand = swiftSubCommand {
                        workingArguments.append(subCommand)
                    }
                    workingArguments.append(contentsOf: action.postSubCommandArguments(callType: .range,
                                                                                       image: workingContainerApp,
                                                                                       tag: workingTag,
                                                                                       userArguments: dockerContainerArguments))
                    workingArguments.append(contentsOf: dockerContainerArguments)
                    workingArguments.append(contentsOf: action.postUserArgumentsArguments(callType: .range,
                                                                                          image: workingContainerApp,
                                                                                          tag: workingTag,
                                                                                          userArguments: dockerContainerArguments))
                    
                    while retryCount < 3 {
                        shouldOutputResponse = false
                        if retryCount > 0 {
                            print("\u{1B}[2K", terminator: "") //errase line
                            print("\u{1B}[1A\u{1B}[2K", terminator: "") //move up one line and
                            
                            retryCountNaming = "retry-\(retryCount)"
                            print("[\(sCurrentTest)/\(totalTests)]: " + retryingMessage.replacingOccurrences(of: "%tag%",
                                                                       with: "\(repoName)\(displayTagName)"))
                        } else {
                            print("[\(sCurrentTest)/\(totalTests)]: " + primaryActionMessage.replacingOccurrences(of: "%tag%",
                                                                            with: "\(repoName)\(displayTagName)"))
                        }
                        let startTime = Date()
                        var endTime = Date()
                        do {
                            var executionTimeout: DispatchTime = .distantFuture
                            if let d = executionTimoutDurationInSec {
                                executionTimeout = DispatchTime.now() + Double(d)
                            }
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
                                                      volumeMapping: workingVolumeMappings,
                                                      containerWorkingDirectory: projectDir,
                                                      containerCommand: containerCommand,
                                                      containerArguments: workingArguments,
                                                           timeout: executionTimeout)
                            endTime = Date()
                        } catch Docker.DockerError.processTimedOut {
                            endTime = Date()
                            if resp == nil {
                                resp = (terminationStatus: -1,
                                        output: "Docker Timmed Out... Trying Restart.")
                            }
							#if os(macOS)
                            // Docker most likely stalled out
                            // should try and restart docker here
                            print("Container has timmed out.  Mostlikely Docker has stalled")
                            print("Trying to restart Docker...")
                            print("Killing Docker...")
                            var appBundle: URL? = nil
                            let apps = NSWorkspace.shared.runningApplications.filter({ return $0.executableURL?.path.contains("Docker.app") ?? false })
                            for app in apps {
                                if let bundle = app.bundleURL,
                                   bundle.path.hasPrefix("Docker.app") {
                                    appBundle = bundle
                                }
                                app.forceTerminate()
                            }
                            
                            Thread.sleep(forTimeInterval: 10)
                            print("Starting Docker...")
                            
                            var openDockerRetry: Int = 0
                            while openDockerRetry < 3 {
                                do {
                                    var app = appBundle
                                    let homeAppURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").appendingPathComponent("Docker.app")
                                    if app == nil &&
                                        FileManager.default.fileExists(atPath: homeAppURL.path) {
                                        app = homeAppURL
                                    }
                                    if app == nil &&
                                      FileManager.default.fileExists(atPath: "/Applications/Docker.app") {
                                        app = URL(fileURLWithPath: "/Applications/Docker.app")
                                    }
                                    if let a = app  {
                                        
                                        _ = try NSWorkspace.shared.launchApplication(at: a,
                                                                                     options: [],
                                                                                     configuration: [:])
                                        
                                        // Try and wait for docker to load
                                        Thread.sleep(forTimeInterval: 10)
                                        // Make sure Docker didn't fail loading
                                        // (Sometime this happens after improper exit, like killing it)
                                        if NSWorkspace.shared.runningApplications.filter({ return $0.executableURL?.path.contains("Docker.app") ?? false }).count > 0 {
                                            openDockerRetry = 3
                                        } else {
                                            openDockerRetry += 1
                                        }
                                    } else {
                                        print("Docker application not found")
                                        openDockerRetry = 3
                                    }
                                } catch {
                                    openDockerRetry += 1
                                    if openDockerRetry == 3 {
                                        print("Failed to Open Docker.")
                                        print(error)
                                    } else {
                                        // Lets wait and try again
                                        Thread.sleep(forTimeInterval: 10)
                                    }
                                    
                                }
                            }
                            
                            if NSWorkspace.shared.runningApplications.filter({ return $0.executableURL?.path.contains("Docker.app") ?? false }).count == 0 {
                                print("Failed to restart Docker.  Please start manually")
                            }
                            #else
                            print("Docker has stalled, please restart.")
                            print("Waiting to re-establish connection with Docker")
                            #endif
                            // wait until docker has re-started
                            while true {
                                if let t = try? Docker.execute(dockerPath: dockerPath,
                                                               arguments: ["container", "ls"],
                                                               hideOutput: true),
                                   t == 0 {
                                    break
                                }
                                Thread.sleep(forTimeInterval: 10)
                            }
                            
                            
                            
                        }
                        
                        let duration = endTime.timeIntervalSince(startTime)
                        
                        if resp!.terminationStatus != 0 ||
                           DockerResponse.containsErrors(resp!.output) {
                            retryCount += 1
                            shouldOutputResponse = true
                            
                            print("\u{1B}[2K", terminator: "") //errase line
                            print("\u{1B}[1A\u{1B}[2K", terminator: "") //move up one line and errase it
                            print("[\(sCurrentTest)/\(totalTests)]: " + errorMessage.replacingOccurrences(of: "%tag%",
                                                                    with: "\(repoName)\(displayTagName)") + ".  Duration: \(formatTimeInterval(duration))")
                            
                            if retryCount >= 3 || !DockerResponse.containsRetryableErrors(resp!.output) {
                                retryCount = 3
                                errorCount += 1
                                failureTags.append(workingTag)
                                if stopOnFirstError {
                                    stop = true
                                }
                            } else {
                                if !DockerResponse.containsErrorRequiringPackageReset(resp!.output) {
                                    // Docker call failed but is not something that a
                                    // package clean && package update can fix.
                                    // lets relax for a moment and see if slowing
                                    // down will fix the issue
                                    Thread.sleep(forTimeInterval: 5)
                                } else {
                                    // do swift package clean && swift package update
                                    _ = try? Docker.runContainer(dockerPath: dockerPath,
                                                                 image: "\(repoName):\(workingTag)",
                                                                     containerName: Docker.genSwiftContName(command: containerCommand,
                                                                                                            tag: workingTag,
                                                                                                            subCommand: swiftSubCommand,
                                                                                                            packageName: packageName,
                                                                                                            using: &randGenerator,
                                                                                                            additionInfo: retryCountNaming, "clean-update"),
                                                                     dockerArguments: ["--cap-add=SYS_PTRACE",
                                                                                       "--security-opt",
                                                                                       "seccomp=unconfined"],
                                                                     autoRemove: true,
                                                                     dockerEnvironment: env,
                                                                     volumeMapping: workingVolumeMappings,
                                                                     containerWorkingDirectory: projectDir,
                                                                     containerCommand: "bash",
                                                                     containerArguments: ["-c", "\(containerCommand) package clean && \(containerCommand) package update"],
                                                                     hideOutput: true)
                                }
                            }
                        } else if DockerResponse.containsWarnings(resp!.output) {
                            retryCount = 3
                            warningCount += 1
                            shouldOutputResponse = true
                            warningTags.append(workingTag)
                            print("\u{1B}[2K", terminator: "") //errase line
                            print("\u{1B}[1A\u{1B}[2K", terminator: "") //move up one line and errase it
                            print("[\(sCurrentTest)/\(totalTests)]: " + warningMessage.replacingOccurrences(of: "%tag%",
                                                                      with: "\(repoName)\(displayTagName)") + ".  Duration: \(formatTimeInterval(duration))")
                        } else if DockerResponse.containsDockerError(resp!.output) {
                            print(resp!.output)
                            return 1
                        } else {
                            retryCount = 3
                            passedCount += 1
                            shouldOutputResponse = false
                            print("\u{1B}[2K", terminator: "") //errase line
                            print("\u{1B}[1A\u{1B}[2K", terminator: "") //move up one line and errase it
                            print("[\(sCurrentTest)/\(totalTests)]: " + successfulMessage.replacingOccurrences(of: "%tag%",
                                                                         with: "\(repoName)\(displayTagName)") + ".  Duration: \(formatTimeInterval(duration))")
                        }
                    }
                    
                    if shouldOutputResponse,
                       var out = resp?.output {
                        for (k,v) in findReplace {
                            out = out.replacingOccurrences(of: k, with: v)
                        }
                        for (k,v) in findReplaceX {
                            out = k.stringByReplacingMatches(in: out, withTemplate: v)
                        }
                        print(out)
                    }
                } catch {
                    print("\u{1B}[2K", terminator: "") //errase line
                    print("\u{1B}[1A\u{1B}[2K", terminator: "") //move up one line and errase it
                    print("[\(sCurrentTest)/\(totalTests)]: Fatal Error trying container '\(workingContainerApp.name):\(currentTag)'")
                    print(error)
                }
            }

            let endTotalTime = Date()

            print("")
            print("Total Duration: \(formatTimeInterval(endTotalTime.timeIntervalSince(startTotalTime)))")

            print("")
            print("Stats for '\(packageName)':")
            print("Total Tags Tested: \(totalTagsTested)")
            print("\tPassed: \(passedCount)")
            if skippedCount > 0 {
                print("Skipped: \(skippedCount)")
            }
            print("\tWarnings: \(warningCount)")
            print("\tErrors: \(errorCount)")

            if !warningTags.isEmpty || !failureTags.isEmpty {
                print("")
                print("List:")
                if !warningTags.isEmpty {
                    print("\tWarnings:")
                    for t in warningTags {
                        print("\t\t\(t)")
                    }
                }
                if !failureTags.isEmpty {
                    print("\tErrors:")
                    for t in failureTags {
                        print("\t\t\(t)")
                    }
                }
            }
        } catch {
            print(error)
            return 1
        }
        return 0
        
    }
}
