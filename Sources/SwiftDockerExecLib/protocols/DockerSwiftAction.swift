//
//  DockerSwiftAction.swift
//  
//
//  Created by Tyler Anger on 2022-04-15.
//

import Foundation
import SwiftDockerCoreLib

public enum DockerSwiftActionCallType {
    /// The action is a single action and not from a range
    case singular
    /// The action is from within an array of image tags
    case range
}

/// Protocol defining a Swift Action
public protocol DockerSwiftAction {
    /// The help usage for a single action
    static var singleActionAppDescription: String? { get }
    /// The help usage for a range of the action
    static var rangeActionAppDescription: String? { get }
    /// The swift sub command to exeute
    static var swiftSubCommand: String? { get }
    /// The action name
    static var action: String { get }
    /// The primary action message to display when executing
    static var primaryActionMessage: String { get }
    /// The message to display when retrying the action
    static var retryingMessage: String { get }
    /// The message to display when an errors occured
    static var errorMessage: String { get }
    /// The message to display when warnings occured
    static var warningMessage: String { get }
    /// The message to display when action was successful
    static var successfulMessage: String { get }
    
    /// Method returns any arguments to add before the sub command
    static func preSubCommandArguments(callType: DockerSwiftActionCallType,
                                       image: DockerRepoContainerApp,
                                       tag: DockerHub.RepositoryTag,
                                       userArguments: [String]) -> [String]
    /// Method returns any arguments to add after the sub command but before the user arguments
    static func postSubCommandArguments(callType: DockerSwiftActionCallType,
                                        image: DockerRepoContainerApp,
                                        tag: DockerHub.RepositoryTag,
                                        userArguments: [String]) -> [String]
    // Method returns any arguments to add after the user arguments
    static func postUserArgumentsArguments(callType: DockerSwiftActionCallType,
                                           image: DockerRepoContainerApp,
                                           tag: DockerHub.RepositoryTag,
                                           userArguments: [String]) -> [String]
}

public extension DockerSwiftAction {
    static func preSubCommandArguments(callType: DockerSwiftActionCallType,
                                       image: DockerRepoContainerApp,
                                       tag: DockerHub.RepositoryTag,
                                       userArguments: [String]) -> [String] {
        return []
    }
    static func postSubCommandArguments(callType: DockerSwiftActionCallType,
                                        image: DockerRepoContainerApp,
                                        tag: DockerHub.RepositoryTag,
                                        userArguments: [String]) -> [String] {
        return []
    }
    static func postUserArgumentsArguments(callType: DockerSwiftActionCallType,
                                           image: DockerRepoContainerApp,
                                           tag: DockerHub.RepositoryTag,
                                           userArguments: [String]) -> [String] {
        return []
    }
}
/*
public extension DockerSwiftAction {
    var appUsageDescription: String? { return Self.appUsageDescription }
    var swiftSubCommand: String? { return Self.swiftSubCommand }
    
    var primaryActionMessage: String { return Self.primaryActionMessage }
    var retryingMessage: String { return Self.retryingMessage }
    var errorMessage: String { return Self.errorMessage }
    var warningMessage: String { return Self.warningMessage }
    var successfulMessage: String { return Self.successfulMessage }
}
*/
