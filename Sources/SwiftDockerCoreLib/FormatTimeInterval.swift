//
//  FormatTimeInterval.swift
//  
//
//  Created by Tyler Anger on 2022-04-06.
//

import Foundation
fileprivate let minuteInterval = 60
fileprivate let hourInterval = minuteInterval * 60
fileprivate let dayInterval = hourInterval * 24
fileprivate let weekInterval = dayInterval * 7

/// Function used to convert a time interval into a human redable string format
public func formatTimeInterval(_ time: TimeInterval) -> String {
    
    var time = Int(time)
    var rtn: String = ""
    
    if time > weekInterval {
        if !rtn.isEmpty { rtn += ", " }
        let remainder = (time % weekInterval)
        let val = Int((time - remainder) / weekInterval)
        time = remainder
        rtn += "\(val) week"
        if val > 1 { rtn += "s" }
    }
    
    if time > dayInterval {
        if !rtn.isEmpty { rtn += ", " }
        let remainder = (time % dayInterval)
        let val = Int((time - remainder) / dayInterval)
        time = remainder
        rtn += "\(val) day"
        if val > 1 { rtn += "s" }
    }
    
    if time > hourInterval {
        if !rtn.isEmpty { rtn += ", " }
        let remainder = (time % hourInterval)
        let val = Int((time - remainder) / hourInterval)
        time = remainder
        rtn += "\(val) hour"
        if val > 1 { rtn += "s" }
    }
    
    if time > minuteInterval {
        if !rtn.isEmpty { rtn += ", " }
        let remainder = (time % minuteInterval)
        let val = Int((time - remainder) / minuteInterval)
        time = remainder
        rtn += "\(val) minute"
        if val > 1 { rtn += "s" }
    }
    
    if time > 0 {
        if !rtn.isEmpty { rtn += ", " }
        rtn += "\(time) second"
        if time > 1 {
            rtn += "s"
        }
    }
    
    if rtn.isEmpty {
        rtn = "0s"
    }
    
    return rtn
    
    
    
}
