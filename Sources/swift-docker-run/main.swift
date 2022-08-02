//
//  swift-docker-run-main.swift
//  swift-docker-run
//
//  Created by Tyler Anger on 2022-03-30.
//

import Foundation
import SwiftDockerExecLib

let appUsageDescription: String? = "Run a Swift Package against a specific Docker Swift Version"



var arguments = ProcessInfo.processInfo.arguments
var env = ProcessInfo.processInfo.environment


exit(DockerContainerApp.execute(arguments: arguments,
                                environment: env,
                                action: DockerContainerApp.Actions.Run.self))
