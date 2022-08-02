//
//  DockerImageContainerApp.swift
//  
//
//  Created by Tyler Anger on 2022-03-30.
//

import Foundation
import SwiftDockerCoreLib

/// Structure containing the Docker Respository and primary executable
public struct DockerRepoContainerApp: LosslessStringConvertible, ExpressibleByStringLiteral {
    /// The Docker Repository Name
    public let name: DockerHub.RepositoryName
    /// The primary application
    public let app: String
    public init(name: DockerHub.RepositoryName,
                app: String? = nil) {
        self.name = name
        self.app = app ?? name.name
    }
    
    public init?(_ description: String) {
        let components = description.split(separator: ":",
                                           omittingEmptySubsequences: false).map(String.init)
        guard components.count == 1 || components.count == 2 else {
            return nil
        }
        guard let name = DockerHub.RepositoryName(components[0]) else {
            return nil
        }
        
        var app: String? = nil
        if components.count == 2 {
            app = components[1]
        }
        
        self.init(name: name, app: app)
    }
    
    public init(stringLiteral value: String) {
        guard let nv = DockerRepoContainerApp(value) else {
            fatalError("Invalid DockerRepoContainerApp value '\(value)'")
        }
        self = nv
    }
    
    public var description: String {
        return self.name.description + ":" + self.app
    }
}

public struct DockerImageContainerApp: LosslessStringConvertible, ExpressibleByStringLiteral {
    /// The Docker Repository Name
    public let name: DockerHub.RepositoryName
    /// The specific docker tag
    public let tag: DockerHub.RepositoryTag
    /// The primary application
    public let app: String
    public init(name: DockerHub.RepositoryName,
                tag: DockerHub.RepositoryTag = .latest,
                app: String? = nil) {
        self.name = name
        self.tag = tag
        self.app = app ?? name.name
    }
    
    public init?(_ description: String) {
        let components = description.split(separator: ":",
                                           omittingEmptySubsequences: false).map(String.init)
        guard components.count == 1 || components.count == 3 else {
            return nil
        }
        guard let name = DockerHub.RepositoryName(components[0]) else {
            return nil
        }
        var tag: DockerHub.RepositoryTag = .latest
        if components.count > 1 {
            guard let t = DockerHub.RepositoryTag(components[1]) else {
                return nil
            }
            tag = t
        }
        
        var app: String? = nil
        if components.count == 3 {
            app = components[2]
        }
        
        self.init(name: name, tag: tag, app: app)
    }
    
    public init(stringLiteral value: String) {
        guard let nv = DockerImageContainerApp(value) else {
            fatalError("Invalid DockerRepoContainerApp value '\(value)'")
        }
        self = nv
    }
    
    public var description: String {
        return self.name.description + ":" + self.tag.description + ":" + self.app
    }
}
