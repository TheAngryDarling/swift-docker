//
//  DockerHub.swift
//  SwiftDockerCoreLib
//
//  Created by Tyler Anger on 2022-03-30.
//

import Foundation
import WebRequest
import Dispatch
import RegEx
#if swift(>=4.1)
    #if canImport(FoundationNetworking)
        import FoundationNetworking
    #endif
#endif

/// Class used to communicate with registry.hub.docker.com to get repository tags
public class DockerHub {
    public enum RequestErrors: Swift.Error {
        case requestTimmedOut
    }
    public enum CodingErrors: Swift.Error {
        case invalidStringValue(String)
    }
    /// Structure Used to to store a repository tag
    public struct RepositoryTag: LosslessStringConvertible {
        
        private static let VersionRegEx = RegEx(stringLiteral: "^[1-9]+(\\.[0-9]+(\\.[0-9]+)?)?")
        /// Common tag representing the latest tag
        public static let latest: RepositoryTag = "latest"
        /// The string representation of the tag
        public let description: String
        
        public init?(_ description: String) {
            guard !description.isEmpty else { return nil }
            self.description = description
        }
        /// The version specific value of the tag if the tag starts with a version value
        public var versionValue: String {
            guard let m = RepositoryTag.VersionRegEx.firstMatch(in: self.description) else {
                return ""
            }
            var rtn = String(self.description[m.range])
            while rtn.split(separator: ".").count < 3 {
                rtn += ".0"
            }
            return rtn
        }
    }
    /// The repository name
    public struct RepositoryName: LosslessStringConvertible {
        public let user: String?
        public let name: String
        public let isLocal: Bool
        
        public var description: String {
            var rtn: String = ""
            if let u = self.user { rtn = u + "/" }
            rtn += self.name
            return rtn
        }
        
        public var path: String {
            return "/\(self.user ?? "library")/\(self.name)"
        }
        
        public init?(_ description: String) {
            guard !description.isEmpty else { return nil }
            let components = description.split(separator: "/").map(String.init)
            guard components.count >= 1 && components.count <= 2 else { return nil }
            if components.count > 1 {
                if components[0] == "local" {
                    self.user = nil
                    self.isLocal = true
                } else {
                    self.user = components[0]
                    self.isLocal = false
                }
            } else {
                self.isLocal = false
                self.user = nil
            }
            guard let r = components.last else { return nil }
            guard !r.isEmpty else { return nil }
            self.name = r
        }
    }
    
    public struct RepositoryTagDetails: Codable {
        public enum CodingKeys: String, CodingKey {
            case id
            //case imageId = "image_id"
            case images
            case creator
            case name
            case repository
            case fullSize = "full_size"
            case v2
            case tagStatus = "tag_status"
            
            case lastUpdated = "last_updated"
            case lastUpdater = "last_updater"
            case lastUpdaterName = "last_updater_name"
            
            case tagLastPulled = "tag_last_pulled"
            case tagLastPushed = "tag_last_pushed"
        }
        public struct Image: Codable {
            public enum CodingKeys: String, CodingKey {
                case architecture
                case features
                //case variant
                case digest
                case os
                case osFeatures = "os_features"
                case osVersion = "os_version"
                case size
                case status
                case lastPulled = "last_pulled"
                case lastPushed = "last_pushed"
            }
            
            public let architecture: String
            public let features: String
            //public let variant: String?
            public let digest: String
            public let os: String
            public let osFeatures: String
            public let osVersion: String?
            public let size: Int
            public let status: String
            public let lastPulled: String?
            public let lastPushed: String?
        }
        public let id: Int
        //public let imageId: ?
        public let images: [Image]
        public var digests: [String] { return self.images.map({ return $0.digest }) }
        public let creator: Int
        public let name: RepositoryTag
        public let repository: Int
        public let fullSize: Int
        public let v2: Bool
        public let tagStatus: String
        public let lastUpdated: String
        public let lastUpdater: Int
        public let lastUpdaterName: String?
        public let tagLastPulled: String?
        public let tagLastPushed: String
    }
    
    private struct Page<Record>: Decodable where Record: Decodable {
        public enum CodingKeys: String, CodingKey {
            case count
            case next
            case previous
            case results
        }
                    
        public let count: Int
        public let next: URL?
        public let previous: URL?
        public let results: [Record]
    }
    
    
    
    private let repositoryHub: URL
    public init(repositoryHub: URL = URL(string: "https://registry.hub.docker.com")!) {
        self.repositoryHub = repositoryHub
    }
    
    @discardableResult
    private func createRequest(session: URLSession,
                               url: URL,
                               completionHandler: @escaping (WebRequest.DataRequest.Results) -> Void) -> WebRequest.DataRequest {
        
        let request = WebRequest.DataRequest.init(URLRequest(url: url,
                                                             cachePolicy: .reloadIgnoringCacheData),
                                                  usingSession: session,
                                                  completionHandler: completionHandler)
        request.resume()
        return request
    }
    
    private func createURL(contextPath: String,
                           parameters: [String: String]) -> URL {
        let url = self.repositoryHub.appendingPathComponent("v2").appendingPathComponent(contextPath)
        var builder = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        var params: [URLQueryItem] = []
        for (k,v) in parameters {
            params.append(.init(name: k, value: v))
        }
        if params.count > 0 {
            builder.queryItems = params
        }
        return builder.url!
    }
    
    @discardableResult
    private func createRequest(session: URLSession,
                               contextPath: String,
                               parameters: [String: String],
                               completionHandler: @escaping (WebRequest.DataRequest.Results) -> Void) -> WebRequest.DataRequest {
        
        let url = createURL(contextPath: contextPath, parameters: parameters)
        
       
        return createRequest(session: session,
                             url: url,
                             completionHandler: completionHandler)
    }
    
    private func createBlockingRequest(session: URLSession,
                                       url: URL,
                                       timeout: DispatchTime = .distantFuture) throws -> Data {
        let semaphore = DispatchSemaphore(value: 0)
        var rtn: Data? = nil
        var err: Error? = nil
        let request = createRequest(session: session,
                                    url: url) { r in
            rtn = r.results
            err = r.error
            semaphore.signal()
        }
        if semaphore.wait(timeout: timeout) != .success {
            request.cancel()
            throw RequestErrors.requestTimmedOut
            
        }
        
        if let e = err {
            throw e
        }
        return rtn!
    }
    
    private func createBlockingRequest(session: URLSession,
                                       contextPath: String,
                                       parameters: [String: String],
                                       timeout: DispatchTime = .distantFuture) throws -> Data {
        let url = self.createURL(contextPath: contextPath, parameters: parameters)
        
        return try self.createBlockingRequest(session: session,
                                              url: url,
                                              timeout: timeout)
    }
    
    
    
    
    private func getAllRepositoryTags<Record>(for repositoryName: RepositoryName,
                                              using recordType: Record.Type) throws -> [Record] where Record: Decodable {
        
        var rtn: [Record] = []
        
        var nextPage: URL? = self.createURL(contextPath: "/repositories\(repositoryName.path)/tags",
                                            parameters: ["page": "1", "page_size": "100"])
        
        let session: URLSession = URLSession(configuration: URLSessionConfiguration.default)
        let decoder = JSONDecoder()
        while let nP = nextPage {
            //print(nP.absoluteString)
            let data = try self.createBlockingRequest(session: session,
                                                      url: nP)
            
            let workingPage = try decoder.decode(Page<Record>.self,
                                                 from: data)
            
            rtn.append(contentsOf: workingPage.results)
            nextPage = workingPage.next
            
        }
        
        return rtn
    }
    
    public func getAllRepositoryTags(for repositoryName: RepositoryName) throws -> [RepositoryTagDetails] {
        let rtn = try getAllRepositoryTags(for: repositoryName,
                                           using: RepositoryTagDetails.self)
        return rtn.sorted(by: { return $0.name < $1.name })
    }
    
    public func getAllRepositoryTagNames(for repositoryName: RepositoryName) throws -> [RepositoryTag] {
        
        struct ImageBasic: Codable {
            public enum CodingKeys: String, CodingKey {
                case name
            }
            let name: RepositoryTag
        }
        
        let rtn = try getAllRepositoryTags(for: repositoryName,
                                              using: ImageBasic.self)
        
        return rtn.map({ return $0.name }).sorted()
        
    }
}

extension DockerHub.RepositoryTag: Codable, ExpressibleByStringLiteral, Comparable {
    public init(stringLiteral value: String) {
        guard let obj = DockerHub.RepositoryTag(value) else {
            preconditionFailure("Invalid Tag value '\(value)'")
        }
        self = obj
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let obj = DockerHub.RepositoryTag(string) else {
            throw DockerHub.CodingErrors.invalidStringValue(string)
        }
        self = obj
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
    
    public static func ==(lhs: DockerHub.RepositoryTag, rhs: DockerHub.RepositoryTag) -> Bool {
        return lhs.description == rhs.description
    }
    public static func ==(lhs: String, rhs: DockerHub.RepositoryTag) -> Bool {
        return lhs == rhs.description
    }
    public static func ==(lhs: DockerHub.RepositoryTag, rhs: String) -> Bool {
        return lhs.description == rhs
    }
    
    public static func !=(lhs: String, rhs: DockerHub.RepositoryTag) -> Bool {
        return lhs != rhs.description
    }
    public static func !=(lhs: DockerHub.RepositoryTag, rhs: String) -> Bool {
        return lhs.description != rhs
    }
    
    
    public static func <(lhs: DockerHub.RepositoryTag, rhs: DockerHub.RepositoryTag) -> Bool {
        return lhs.description < rhs.description
    }
    public static func >(lhs: DockerHub.RepositoryTag, rhs: DockerHub.RepositoryTag) -> Bool {
        return lhs.description > rhs.description
    }
    
    public static func <(lhs: String, rhs: DockerHub.RepositoryTag) -> Bool {
        return lhs < rhs.description
    }
    public static func <(lhs: DockerHub.RepositoryTag, rhs: String) -> Bool {
        return lhs.description < rhs
    }
    
    public static func >(lhs: String, rhs: DockerHub.RepositoryTag) -> Bool {
        return lhs > rhs.description
    }
    public static func >(lhs: DockerHub.RepositoryTag, rhs: String) -> Bool {
        return lhs.description > rhs
    }
}

extension DockerHub.RepositoryName: Codable, ExpressibleByStringLiteral, Comparable {
    public init(stringLiteral value: String) {
        guard let obj = DockerHub.RepositoryName(value) else {
            preconditionFailure("Invalid Repository Name value '\(value)'")
        }
        self = obj
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        guard let obj = DockerHub.RepositoryName(string) else {
            throw DockerHub.CodingErrors.invalidStringValue(string)
        }
        self = obj
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.description)
    }
    
    public static func ==(lhs: DockerHub.RepositoryName, rhs: DockerHub.RepositoryName) -> Bool {
        return lhs.description == rhs.description
    }
    public static func ==(lhs: String, rhs: DockerHub.RepositoryName) -> Bool {
        return lhs == rhs.description
    }
    public static func ==(lhs: DockerHub.RepositoryName, rhs: String) -> Bool {
        return lhs.description == rhs
    }
    
    public static func !=(lhs: String, rhs: DockerHub.RepositoryName) -> Bool {
        return lhs != rhs.description
    }
    public static func !=(lhs: DockerHub.RepositoryName, rhs: String) -> Bool {
        return lhs.description != rhs
    }
    
    
    public static func <(lhs: DockerHub.RepositoryName, rhs: DockerHub.RepositoryName) -> Bool {
        return lhs.description < rhs.description
    }
    public static func >(lhs: DockerHub.RepositoryName, rhs: DockerHub.RepositoryName) -> Bool {
        return lhs.description > rhs.description
    }
    
    public static func <(lhs: String, rhs: DockerHub.RepositoryName) -> Bool {
        return lhs < rhs.description
    }
    public static func <(lhs: DockerHub.RepositoryName, rhs: String) -> Bool {
        return lhs.description < rhs
    }
    
    public static func >(lhs: String, rhs: DockerHub.RepositoryName) -> Bool {
        return lhs > rhs.description
    }
    public static func >(lhs: DockerHub.RepositoryName, rhs: String) -> Bool {
        return lhs.description > rhs
    }
}
