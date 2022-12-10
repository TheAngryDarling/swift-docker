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

//print(arguments.map({ $0.contains(" ") ? "'\($0)'" : $0 }).joined(separator: " "))
let strAction = arguments[1].lowercased()
guard var action = DockerContainerApp.Actions.all.first(where: { $0.action == strAction }) else {
    print("Invalid sub command '\(arguments[1])'")
    print("Available sub commands: \(DockerContainerApp.Actions.actions.joined(separator: ", "))")
    exit(1)
}

if action.action == "execute",
   let packageIdx = arguments.firstIndex(of: "package") {
    action = DockerContainerApp.Actions.Package.self
    arguments[1] = "package"
    arguments.remove(at: packageIdx)
}

//print(arguments.joined(separator: " "))

// remove the sub command from the arguments
arguments.remove(at: 1)

exit(DockerContainerApp.execute(arguments: arguments,
                                action: action))
