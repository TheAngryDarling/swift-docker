//
//  main.swift
//  swift-docker-run-range
//
//  Created by Tyler Anger on 2022-03-30.
//

import Foundation
import SwiftDockerExecLib


let appUsageDescription: String? = "Run a Swift Package against a range of Docker Swift Version"


var arguments = ProcessInfo.processInfo.arguments
var env = ProcessInfo.processInfo.environment


exit(DockerContainerRangeApp.execute(arguments: arguments,
                                     environment: env,
                                     action: DockerContainerApp.Actions.Run.self))
