//
//  swift-docker-list-main.swift
//  docker-hub-list
//
//  Created by Tyler Anger on 2022-03-30.
//

import Foundation
import SwiftDockerExecLib

let appUsageDescription: String? = "Get the list of Swift Docker Tags"

var arguments = ProcessInfo.processInfo.arguments
var env = ProcessInfo.processInfo.environment

exit(DockerHubList.execute(arguments: arguments,
                           environment: env,
                           appUsageDescription: appUsageDescription))
