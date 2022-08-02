//
//  swift-docker-test-main.swift
//  swift-docker-test
//
//  Created by Tyler Anger on 2022-03-30.
//

import Foundation
import SwiftDockerExecLib

let appUsageDescription: String? = "Test a Swift Package against a specific Docker Swift Version"
let swiftSubCommand: String = "test"

let primaryActionMessage: String = "Testing with %tag%"
let retryingMessage: String = "Retrying test on %tag%"
let errorMessage: String = "Tests failed on %tag%"
let warningMessage: String = "Tested with warnings on %tag%"
let successfulMessage: String = "Tested successfully on %tag%"

var arguments = ProcessInfo.processInfo.arguments
var env = ProcessInfo.processInfo.environment

/* FOR TESTING BEGIN */
//arguments = ["-h"]
/*
arguments = [arguments[0],
             "--volume",
             "/Users/tyler/development/swift/:/Users/tyler/development/swift/",
             "--tag",
             "5.3.1"]

//arguments.append(contentsOf: ["--filter", "CLICaptureTests.CLICaptureTests/testExecute"])

env["PWD"] = "/Users/tyler/development/swift/Packages/CLIWrapper"
FileManager.default.changeCurrentDirectoryPath(env["PWD"]!)
*/
/* FOR TESTING ENDS*/


exit(DockerContainerApp.execute(arguments: arguments,
                                environment: env,
                                action: DockerContainerApp.Actions.Test.self))
