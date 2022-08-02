//
//  main.swift
//  
//
//  Created by Tyler Anger on 2022-04-10.
//

import Foundation
import SwiftDockerExecLib

let appUsageDescription: String? = "Create a specific Swift Docker Container and join it"

var arguments = ProcessInfo.processInfo.arguments
var env = ProcessInfo.processInfo.environment


exit(DockerContainerApp.execute(arguments: arguments,
                                environment: env,
                                appUsageDescription: appUsageDescription))
