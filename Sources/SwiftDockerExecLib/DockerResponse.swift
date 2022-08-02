//
//  DockerResponse.swift
//  
//
//  Created by Tyler Anger on 2022-03-31.
//

import Foundation

/// Collection of pre-defined messages to check for from the docker response
public enum DockerResponse {
    
    public static let retryablePackageResetErrorPatterns: [String] = ["failed to load the cached build description",
                                                          "could not build C module ",
                                                          "Error: Unable to parse dependencie"]
    public static func containsErrorRequiringPackageReset(_ output: String) -> Bool {
        return retryablePackageResetErrorPatterns.contains(where: { return output.contains($0) })
    }
    
    public static let retryableErrorPatterns: [String] = ["error: unable to execute command: Killed",
                                                          " cannot be imported by the Swift ",
                                                          "unable to upgrade to tcp, received 500",
                                                          "Error response from daemon: dial unix",
                                                          "Docker Timmed Out"]
    public static func containsRetryableErrors(_ output: String) -> Bool {
        return retryableErrorPatterns.contains(where: { return output.contains($0) }) ||
        containsErrorRequiringPackageReset(output)
    }
    private static let errorPatterns: [String] = ["error: ",
                                                  "Error: "] + retryableErrorPatterns
    public static func containsErrors(_ output: String) -> Bool {
        return errorPatterns.contains(where: { return output.contains($0) })
    }
    
    
    
    private static let warningPatterns: [String] = ["warning:", "Warning:"]
    public static func containsWarnings(_ output: String) -> Bool {
        return warningPatterns.contains(where: { return output.contains($0) })
    }
    
    private static let dockerErrorPatterns: [String] = ["docker: Error response from daemon:"]
    public static func containsDockerError(_ output: String) -> Bool {
        return dockerErrorPatterns.contains(where: { return output.contains($0) })
    }
    
}
