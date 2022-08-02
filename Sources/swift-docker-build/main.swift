//
//  swift-docker-build-main.swift
//  swift-docker-build
//
//  Created by Tyler Anger on 2022-03-30.
//

import Foundation
import SwiftDockerExecLib



var arguments = ProcessInfo.processInfo.arguments
var env = ProcessInfo.processInfo.environment

/* FOR TESTING BEGIN */
//arguments = ["-h"]
/*
arguments = [arguments[0],
             "--volume",
             "/Users/tyler/development/swift/:/Users/tyler/development/swift/",
             "--tag",
             "4.0"]


env["PWD"] = "/Users/tyler/development/swift/Packages/SynchronizeObjects"
FileManager.default.changeCurrentDirectoryPath(env["PWD"]!)
*/
/* FOR TESTING ENDS*/

exit(DockerContainerApp.execute(arguments: arguments,
                                environment: env,
                                action: DockerContainerApp.Actions.Build.self))



