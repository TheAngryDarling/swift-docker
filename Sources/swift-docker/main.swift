//
//  main.swift
//  
//
//  Created by Tyler Anger on 2022-04-15.
//

import Foundation
import SwiftDockerExecLib

var arguments = ProcessInfo.processInfo.arguments

guard arguments.count > 1 else {
    print("Missing sub command")
    exit(1)
}

let strAction = arguments[1].lowercased()
guard let action = DockerContainerApp.Actions.all.first(where: { $0.action == strAction }) else {
    print("Invalid sub command '\(arguments[1])'")
    print("Available sub commands: \(DockerContainerApp.Actions.actions.joined(separator: ", "))")
    exit(1)
}

//print(arguments.joined(separator: " "))

// remove the sub command from the arguments
arguments.remove(at: 1)

exit(DockerContainerApp.execute(arguments: arguments,
                                action: action))
