//
//  DockerHubList.swift
//  
//
//  Created by Tyler Anger on 2022-03-31.
//

import Foundation
import RegEx
import SwiftDockerCoreLib

public enum DockerHubList {
    
    public static let version: String = "1.0.0"
    
    public enum Arguments {
        
        
        public static let filterArgument = Argument(short: "tf",
                                                    long: "tagFilter",
                                                    additionalParamName: "string",
                                                    description: "Filter Tag Names by string") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Filter Pattern")
            }
            let sFilter = arguments[currentIndex]
            currentIndex += 1
            
           
            var filter: [String] = (currentValue as? [String]) ?? []
            filter.append(sFilter)
            
            return .parsed(filter)
            
            
        }
        
        public static let filterXArgument = Argument(short: "tfX",
                                                    long: "tagFilterX",
                                                    additionalParamName: "pattern",
                                                    description: "Filter Tag Names by pattern") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Filter Pattern")
            }
            let sFilter = arguments[currentIndex]
            currentIndex += 1
            
            do {
                var filter: [RegEx] = (currentValue as? [RegEx]) ?? []
                let fltr = try RegEx(pattern: sFilter)
                filter.append(fltr)
                
                return .parsed(filter)
            } catch {
                return .failedToParse(message: "Invalid Filter Pattern '\(sFilter)': \(error)")
                
            }
            
        }
        public static let excludeArgument = Argument(short: "te",
                                                     long: "tagExclude",
                                                     additionalParamName: "string",
                                                     description: "Exclude Tag Names by string") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Exclude Pattern")
            }
            let sFilter = arguments[currentIndex]
            currentIndex += 1
            
            var filter: [String] = (currentValue as? [String]) ?? []
            filter.append(sFilter)
            
            return .parsed(filter)
            
        }
        public static let excludeXArgument = Argument(short: "teX",
                                                     long: "tagExcludeX",
                                                     additionalParamName: "pattern",
                                                     description: "Exclude Tag Names by pattern") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Exclude Pattern")
            }
            let sFilter = arguments[currentIndex]
            currentIndex += 1
            
            do {
                var filter: [RegEx] = (currentValue as? [RegEx]) ?? []
                let fltr = try RegEx(pattern: sFilter)
                filter.append(fltr)
                
                return .parsed(filter)
            } catch {
                return .failedToParse(message: "Invalid Exclude Pattern '\(sFilter): \(error)'")
                
            }
            
        }
        public static let ignoreCacheArgument = Argument(short: "ic",
                                                    long: "ignoreCache",
                                                    description: "Indicator if cache should be ignored") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            var current = (currentValue as? Caching.CacheUse) ?? Caching.CacheUse.default
            
            guard current.isDefault else {
                return .failedToParse(message: "Caching use was already previously set.")
            }
            
            current = .ignoreCache
            return .parsed(current)
            
        }
        
        public static let useCacheOnlyArgument = Argument(short: "uco",
                                                    long: "useCacheOnly",
                                                    description: "Indicates of should only return from cache") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            var current = (currentValue as? Caching.CacheUse) ?? Caching.CacheUse.default
            
            guard current.isDefault else {
                return .failedToParse(message: "Caching use was already previously set.")
            }
            
            current = .cacheOnly
            return .parsed(current)
            
        }
        
        
        public static let cacheFolderArgument = Argument(short: "cF",
                                                         long: "cachefolder",
                                                         additionalParamName: "path",
                                                         description: "Path to the Cache Folder") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Cache Folder Path")
            }
            let rtn = arguments[currentIndex]
            currentIndex += 1
            return .parsed(rtn)
        }
        public static let cacheDurationArgument = Argument(short: "cd",
                                                           long: "cacheDuration",
                                                           additionalParamName: "duration",
                                                           description: "The duration to use cache file before refresh. Eg: 1s = 1 second, 1h = 1 hour, 1d = 1 day, 1w = 1 week ") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Cache Duration Value")
            }
            
            let sDuration = arguments[currentIndex].lowercased()
            currentIndex += 1
            
            let workingRange = sDuration.startIndex..<sDuration.index(before: sDuration.endIndex)
            if let iDuration = TimeInterval(sDuration) {
                return .parsed(iDuration)
            } else if sDuration.hasSuffix("s"),
                      let iDuration = TimeInterval(String(sDuration[workingRange])) {
                return .parsed(iDuration)
            } else if sDuration.hasSuffix("m"),
                      let iDuration = TimeInterval(String(sDuration[workingRange])) {
                return .parsed(iDuration * 60)
            } else if sDuration.hasSuffix("h"),
                      let iDuration = TimeInterval(String(sDuration[workingRange])) {
                return .parsed(iDuration * 60 * 60)
            } else if sDuration.hasSuffix("d"),
                      let iDuration = TimeInterval(String(sDuration[workingRange])) {
                return .parsed(iDuration * 60 * 60 * 24)
            } else if sDuration.hasSuffix("w"),
                      let iDuration = TimeInterval(String(sDuration[workingRange])) {
                return .parsed(iDuration * 60 * 60 * 24 * 7)
            } else {
                return .failedToParse(message: "Invalid Cache Duration Value '\(sDuration)'")
            }
            
        }
        public static let useCacheOnFailureArgument = Argument(short: "ucof",
                                                               long: "useCacheOnFailure",
                                                               description: "In the event of an error while fetching list return from cache instead of failing out")
        
        public static let similarToArgument = Argument(long: "similarTo",
                                                         additionalParamName: "tag",
                                                         description: "The tag to match against") {
            (arguments: [String], currentIndex: inout Int, currentValue: Any?) -> Argument.Parsed in
            
            guard currentIndex < arguments.count else {
                return .failedToParse(message: "Missing Cache Folder Path")
            }
            let sTag = arguments[currentIndex]
            currentIndex += 1
            guard let tag = DockerHub.RepositoryTag(sTag) else {
                return .failedToParse(message: "Invalid From Tag '\(sTag)'")
            }
            return .parsed(tag)
        }
        
        public static let listCacheReposArgument = Argument(short: "lcr",
                                                            long: "listCachedRepos",
                                                            description: "Returns a list of Repositorys that have been cached")
        
        
        
        public static let listTagArguments: [Argument] = [
            filterArgument,
            filterXArgument,
            excludeArgument,
            excludeXArgument,
            ignoreCacheArgument,
            useCacheOnlyArgument,
            cacheFolderArgument,
            cacheDurationArgument,
            useCacheOnFailureArgument,
            similarToArgument
        ]
        
        public static let listCacheArguments: [Argument] = [
            cacheFolderArgument,
            listCacheReposArgument
        ]
        
        public static let allArguments: [Argument] = [
            filterArgument,
            filterXArgument,
            excludeArgument,
            excludeXArgument,
            ignoreCacheArgument,
            useCacheOnlyArgument,
            cacheFolderArgument,
            cacheDurationArgument,
            useCacheOnFailureArgument,
            listCacheReposArgument
        ]
    }
    
    public struct Caching {
        public enum CacheUse {
            case `default`
            case ignoreCache
            case cacheOnly
            
            public var isDefault: Bool {
                guard case .default = self else {
                    return false
                }
                return true
            }
            public var ignore: Bool {
                guard case .ignoreCache = self else {
                    return false
                }
                return true
            }
            
            public var useCacheOnly: Bool {
                guard case .cacheOnly = self else {
                    return false
                }
                return true
            }
        }
        public static let defaultExpiryDuration: TimeInterval = 60 * 60 * 24 * 7 // 1 week
        
        public let cacheFolder: String?
        public let expiryDuration: TimeInterval
        public let useCacheOnFailure: Bool
        public let cacheUse: CacheUse
        public let isNone: Bool
        
        public static let none = Caching()
        
        private init(cacheFolder: String,
                     expiryDuration: TimeInterval,
                     useCacheOnFailure: Bool,
                     cacheUse: CacheUse) {
            self.cacheFolder = cacheFolder
            self.expiryDuration = expiryDuration
            self.useCacheOnFailure = useCacheOnFailure
            self.cacheUse = cacheUse
            self.isNone = false
        }
        
        private init() {
            self.cacheFolder = nil
            self.expiryDuration = 0
            self.useCacheOnFailure = false
            self.cacheUse = .default
            self.isNone = true
        }
        
        
        
        public static func caching(cacheFolder: String,
                                   expiryDuration: TimeInterval = Caching.defaultExpiryDuration,
                                   useCacheOnFailure: Bool = false,
                                   cacheUse: CacheUse = .default) -> Caching{
            return .init(cacheFolder: cacheFolder,
                         expiryDuration: expiryDuration,
                         useCacheOnFailure: useCacheOnFailure,
                         cacheUse: cacheUse)
        }
        
        public struct Parsed {
            public let errorMessage: String?
            public let object: Caching?
            
            private init(errorMessage: String? = nil,
                         object: Caching? = nil) {
                self.errorMessage = errorMessage
                self.object = object
            }
            
            public static func failedToParse(message: String) -> Parsed {
                return .init(errorMessage: message, object: nil)
            }
            
            public static func parsed(_ object: Caching) -> Parsed {
               return  self.init(errorMessage: nil, object: object)
            }
        }
        
        
        public static func parse(cacheFolder: String?,
                                 expiryDuration: TimeInterval?,
                                 useCacheOnFailure: Bool,
                                 cacheUse: Caching.CacheUse) -> Parsed {
            if (cacheFolder != nil && expiryDuration == nil) {
                return .failedToParse(message: "Using a Cache Folder requires a Cache Duration Value")
            }
            
            if (cacheFolder == nil && expiryDuration != nil) {
                return .failedToParse(message: "Using a Cache Duration requires a Cache Folder")
            }

            if (useCacheOnFailure && cacheFolder == nil) {
                return .failedToParse(message: "Using Cache on Failure requires a Cache Folder")
            }
            if let folder = cacheFolder {
                return .parsed(Caching.caching(cacheFolder: folder,
                                               expiryDuration: expiryDuration ?? 0,
                                               useCacheOnFailure: useCacheOnFailure,
                                               cacheUse: cacheUse))
            } else {
                return .parsed(Caching.none)
            }
        }
    }
    private static let cacheExtension: String = ".cache.json"
    
    private static func repoNameToCacheFileName(_ name: DockerHub.RepositoryName) -> String {
        return name.description.replacingOccurrences(of: "/", with: ".") + cacheExtension
    }
    private static func cacheFileNameToRepoName(_ name: String) -> DockerHub.RepositoryName? {
        guard name.hasSuffix(cacheExtension) else { return nil }
        var name = name
        name.removeLast(cacheExtension.count) // remove cache extension
        name = name.replacingOccurrences(of: ".", with: "/")
        return DockerHub.RepositoryName(name)
    }
    public static func listCachedRepositories(in cacheFolder: String) throws -> [DockerHub.RepositoryName] {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: cacheFolder) else {
            return []
        }
        
        var rtn: [DockerHub.RepositoryName] = []
        let files = try fileManager.contentsOfDirectory(atPath: cacheFolder)
        for file in files.sorted() {
            if let rn = cacheFileNameToRepoName(file) {
                rtn.append(rn)
            }
        }
        
        return rtn
            
        
    }
    
    public static func getTagDetails(for repository: DockerHub.RepositoryName = "swift",
                                   filter: [String] = [],
                                   filterX: [RegEx] = [],
                                   excludeFilter: [String] = [],
                                   excludeFilterX: [RegEx] = [],
                                   caching: Caching = .none,
                                   similarTo: DockerHub.RepositoryTag? = nil) throws -> [DockerHub.RepositoryTagDetails] {
        
        guard !repository.isLocal else {
            return []
        }
        
        let hub = DockerHub()
        
        let cacheFile: String? = {
            guard let cF = caching.cacheFolder else {
                return nil
            }
            return NSString(string: cF).appendingPathComponent(repoNameToCacheFileName(repository))
        }()
        
        let fileManager = FileManager.default
        
        var tags = try { () throws -> [DockerHub.RepositoryTagDetails] in
            
            guard !caching.cacheUse.useCacheOnly else {
                guard let cachePath = cacheFile else { return [] }
                guard fileManager.fileExists(atPath: cachePath) else { return [] }
                //print("Getting info from cache ('\(cachePath)').1")
                let data = try Data(contentsOf: URL(fileURLWithPath: cachePath))
                let decoder = JSONDecoder()
                return try decoder.decode([DockerHub.RepositoryTagDetails].self, from: data)
            }
            
            if !caching.cacheUse.ignore,
               let cachePath = cacheFile,
               fileManager.fileExists(atPath: cachePath),
               let modDate = fileManager.modificationDateForItemNoThrow(atPath: cachePath),
               Date().timeIntervalSince(modDate) < caching.expiryDuration {
                //print("Getting info from cache ('\(cachePath)').2")
                let data = try Data(contentsOf: URL(fileURLWithPath: cachePath))
                let decoder = JSONDecoder()
                return try decoder.decode([DockerHub.RepositoryTagDetails].self, from: data)
            } else {
                
                do {
                    let ret = try hub.getAllRepositoryTags(for: repository)
                    if let cachePath = cacheFile {
                        //print("Writing new cache to '\(cachePath)'")
                        let parentFolder = NSString(string: cachePath).deletingLastPathComponent
                        if !fileManager.fileExists(atPath: parentFolder) {
                            try fileManager.createDirectory(atPath: parentFolder,
                                                            withIntermediateDirectories: true)
                        }
                        let encoder = JSONEncoder()
                        let data = try encoder.encode(ret)
                        try data.write(to: URL(fileURLWithPath: cachePath))
                    }
                    return ret
                } catch {
                    if caching.useCacheOnFailure,
                       let cachePath = cacheFile,
                       fileManager.fileExists(atPath: cachePath) {
                        let data = try Data(contentsOf: URL(fileURLWithPath: cachePath))
                        let decoder = JSONDecoder()
                        return try decoder.decode([DockerHub.RepositoryTagDetails].self, from: data)
                    } else {
                        throw error
                    }
                }
            }
        }()
        
        if let s = similarTo {
            if let st = tags.first(where: { return $0.name == s }) {
                tags = tags.filter({ return $0.name != s && $0.digests.containsAny(st.digests) })
            } else {
                tags = []
            }
        }
        
        if !filter.isEmpty || !filterX.isEmpty {
            // Remove any tags that don't match either filter
            tags.removeAll {
                return !(filter.contains($0.name.description) || filterX.anyMatches($0.name.description))
            }
        }
        
        if !excludeFilter.isEmpty {
            tags.removeAll {
                return excludeFilter.contains($0.name.description)
            }
        }
        if !excludeFilterX.isEmpty {
            // Remove any tags that match any of the patterns
            tags.removeAll {
                return excludeFilterX.anyMatches($0.name.description)
                
            }
        }
        return tags
    }
    public static func getTags(for repository: DockerHub.RepositoryName = "swift",
                               filter: [String] = [],
                               filterX: [RegEx] = [],
                               excludeFilter: [String] = [],
                               excludeFilterX: [RegEx] = [],
                               caching: Caching = .none,
                               similarTo: DockerHub.RepositoryTag? = nil) throws -> [DockerHub.RepositoryTag] {
        
        return try self.getTagDetails(for: repository,
                                         filter: filter,
                                         filterX: filterX,
                                         excludeFilter: excludeFilter,
                                         excludeFilterX: excludeFilterX,
                                         caching: caching,
                                         similarTo: similarTo).map({ return $0.name })
    }
    
    public static func execute(arguments: [String] = ProcessInfo.processInfo.arguments,
                               environment: [String: String] = ProcessInfo.processInfo.environment,
                               appUsageDescription: String? = nil) -> Int32 {
        
        var arguments = arguments
        let appPath = arguments[0]
        var appName = NSString(string: appPath).lastPathComponent
        if let dockerAppName = ProcessInfo.processInfo.environment["DOCKER_APP_NAME"] {
            appName = dockerAppName
        }
        arguments.remove(at: 0) // Remove the application path argument

        func printUsage(withMessage message: String? = nil) {
            if let msg = message {
                print(msg)
            }
            print("\(appName) [options] {repository name}")
            if let desc = appUsageDescription {
                print(desc)
            }
            print("")
            print("OPTIONS:")
            
            var optionArguments: [(arguments: String, description: String)] = [
                Argument.helpArgument.helpDisplayObjects(),
                Argument.versionArgument.helpDisplayObjects(),
            ]
            let helpObjects = DockerHubList.Arguments.allArguments.map({ return $0.helpDisplayObjects() })
            optionArguments.append(contentsOf: helpObjects)
            
            var maxArgumentCharacters: Int = optionArguments[0].arguments.count
            for obj in optionArguments {
                if obj.arguments.count > maxArgumentCharacters {
                    maxArgumentCharacters = obj.arguments.count
                }
            }
            
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


        // Repo to look at
        var repoName: DockerHub.RepositoryName = "swift"
        
        // Docker Hub List Arguments
        var filter: [String] = []
        var filterX: [RegEx] = []
        var excludeFilter: [String] = []
        var excludeFilterX: [RegEx] = []
        var cacheFolder: String? = nil
        var cacheDuration: TimeInterval? = nil
        var useCacheOnFailure: Bool = false
        var cachingUse: DockerHubList.Caching.CacheUse = .default
        
        var similarTo: DockerHub.RepositoryTag? = nil
        /// Flag used to list cached repos
        var listCachedRepos: Bool = false
        

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
            } else if let parsed = Arguments.filterArgument.parse(arguments: arguments,
                                                                  startingAt: &currentArgumentIndex,
                                                                  currentParsedValue: filter) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                filter = parsed.object as! [String]
            } else if let parsed = Arguments.filterXArgument.parse(arguments: arguments,
                                                                   startingAt: &currentArgumentIndex,
                                                                   currentParsedValue: filterX) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                filterX = parsed.object as! [RegEx]
            } else if let parsed = Arguments.excludeArgument.parse(arguments: arguments,
                                                                   startingAt: &currentArgumentIndex,
                                                                   currentParsedValue: excludeFilter) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                excludeFilter = parsed.object as! [String]
            } else if let parsed = Arguments.excludeXArgument.parse(arguments: arguments,
                                                                    startingAt: &currentArgumentIndex,
                                                                    currentParsedValue: excludeFilterX) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                excludeFilterX = parsed.object as! [RegEx]
            } else if let parsed = Arguments.ignoreCacheArgument.parse(arguments: arguments,
                                                                       startingAt: &currentArgumentIndex,
                                                                       currentParsedValue: cachingUse) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                cachingUse = (parsed.object as? DockerHubList.Caching.CacheUse) ?? .default
            } else if let parsed = Arguments.useCacheOnlyArgument.parse(arguments: arguments,
                                                                        startingAt: &currentArgumentIndex,
                                                                        currentParsedValue: cachingUse) {
                     if let error = parsed.errorMessage {
                         printUsage(withMessage: error)
                         return 1
                     }
                     cachingUse = (parsed.object as? DockerHubList.Caching.CacheUse) ?? .default
                 } else if let parsed = Arguments.cacheFolderArgument.parse(arguments: arguments,
                                                                            startingAt: &currentArgumentIndex) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                cacheFolder = parsed.object as? String
            } else if let parsed = Arguments.cacheDurationArgument.parse(arguments: arguments,
                                                                         startingAt: &currentArgumentIndex) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                cacheDuration = parsed.object as? TimeInterval
            } else if let parsed = Arguments.useCacheOnFailureArgument.parse(arguments: arguments,
                                                                             startingAt: &currentArgumentIndex) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                useCacheOnFailure = parsed.object as? Bool ?? false
            } else if let parsed = Arguments.similarToArgument.parse(arguments: arguments,
                                                                             startingAt: &currentArgumentIndex) {
                if let error = parsed.errorMessage {
                    printUsage(withMessage: error)
                    return 1
                }
                similarTo = parsed.object as? DockerHub.RepositoryTag
                
            } else if let _ = Arguments.listCacheReposArgument.parse(arguments: arguments,
                                                                                   startingAt: &currentArgumentIndex) {
                listCachedRepos = true
            } else {
                let arg = arguments[currentArgumentIndex]
                if currentArgumentIndex == (arguments.count - 1) {
                    guard let rn = DockerHub.RepositoryName(arg) else {
                        printUsage(withMessage: "Invalid Repository Name '\(arg)'")
                        return 1
                    }
                    repoName = rn
                } else {
                    printUsage(withMessage: "Invalid Argument: '\(arg)'")
                    return 1
                }
                currentArgumentIndex += 1
            }
        }

        let parsedCaching = Caching.parse(cacheFolder: cacheFolder,
                                          expiryDuration: cacheDuration,
                                          useCacheOnFailure: useCacheOnFailure,
                                          cacheUse: cachingUse)

        guard let caching = parsedCaching.object else {
            if let msg = parsedCaching.errorMessage {
                printUsage(withMessage: msg)
            }
            return 1
        }

        if listCachedRepos && cacheFolder == nil {
            printUsage(withMessage: "List Cached Repositories requires the Cache Folder parameter")
            return 1
        }

        if listCachedRepos {
            do {
                let list = try DockerHubList.listCachedRepositories(in: cacheFolder!)
                for item in list {
                    print(item)
                }
                return 0
            } catch {
                print("Fatal Error: \(error)")
                return 1
            }
            
        }
        
        do {
            //print(caching)
            let list = try DockerHubList.getTagDetails(for: repoName,
                                                          filter: filter,
                                                          filterX: filterX,
                                                          excludeFilter: excludeFilter,
                                                          excludeFilterX: excludeFilterX,
                                                          caching: caching,
                                                          similarTo: similarTo)
            
            for item in list {
                print(item.name)
            }
            
        } catch {
            print("Fatal Error: \(error)")
            return 1
        }
        return 0
    }
}
