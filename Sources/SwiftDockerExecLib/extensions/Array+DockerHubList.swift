//
//  Array+DockerHubList.swift
//  docker-hub-list
//
//  Created by Tyler Anger on 2022-03-30.
//

import Foundation
import RegEx

internal extension Array where Element == RegEx {
    func anyMatches(_ string: String) -> Bool {
        return self.contains() {
            return ($0.firstMatch(in: string) != nil)
        }
    }
    
    
}

internal extension Array where Element: Equatable {
    func containsAny<S>(_ sequence: S) -> Bool where S: Sequence, S.Element == Element {
        for s in sequence {
            if self.contains(s) {
                return true
            }
        }
        return false
    }
}
