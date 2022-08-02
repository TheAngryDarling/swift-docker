//
//  main.swift
//  swift-docker-build-range
//
//  Created by Tyler Anger on 2022-03-30.
//

import Foundation
import SwiftDockerExecLib


let appUsageDescription: String? = "Build a Swift Package against a range of Docker Swift Version"

var arguments = ProcessInfo.processInfo.arguments
var env = ProcessInfo.processInfo.environment

/* FOR TESTING BEGIN */
//arguments = ["-h"]
/*
arguments = [arguments[0],
             "--volume",
             "/Users/tyler/development/swift/:/Users/tyler/development/swift/",
             "--cachefolder",
             "/Users/tyler/downloads/swift.docker.tags.json",
             "--cacheDuration",
             "1d",
             "--useCacheOnFailure",
             "--tagFilterX",
             "^[1-9]+\\.[0-9]+(\\.[0-9]+)?$",
             //"--excludeX",
             //"^3.*",
             "--tagExclude",
             "4"]

env["PWD"] = "/Users/tyler/development/swift/Packages/SwiftNillable"
FileManager.default.changeCurrentDirectoryPath(env["PWD"]!)
*/
/* FOR TESTING ENDS*/

exit(DockerContainerRangeApp.execute(arguments: arguments,
                                     environment: env,
                                     action: DockerContainerApp.Actions.Build.self))

