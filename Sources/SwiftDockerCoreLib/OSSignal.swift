//
//  OSSignal.swift
//  
//
//  Created by Tyler Anger on 2022-04-16.
//
// Based on work done by Alejandro Martínez here https://github.com/alexito4/Trap
//

import Foundation
import Dispatch
#if os(Linux)
import Glibc
#endif
import SwiftPatches

/// Object used to trap system signals
public enum OSSignal: Hashable, CustomStringConvertible, CaseIterable {
    
    public typealias AllCases = Set<OSSignal>
    public typealias SignalHandler = @convention(c) (Int32) -> (Void)
    
    case hangup
    case interrupt
    case illegal
    case trap
    case abort
    case kill
    case alarm
    case termination
    
    public static let allCases: AllCases = [
        .hangup,
        .interrupt,
        .illegal,
        .trap,
        .abort,
        .kill,
        .alarm,
        .termination
    ]
    
    fileprivate init(rawValue: Int32) {
        switch rawValue {
            case SIGHUP: self = .hangup
            case SIGINT: self = .interrupt
            case SIGILL: self = .illegal
            case SIGTRAP: self = .trap
            case SIGABRT: self = .abort
            case SIGKILL: self = .kill
            case SIGALRM: self = .alarm
            case SIGTERM: self = .termination
            default: preconditionFailure("Invalid Signal Value '\(rawValue)'")
        }
    }
    
    
    fileprivate var sigValue: Int32 {
        switch self {
            case .hangup:
                return SIGHUP
            case .interrupt:
                return SIGINT
            case .illegal:
                return SIGILL
            case .trap:
                return SIGTRAP
            case .abort:
                return SIGABRT
            case .kill:
                return SIGKILL
            case .alarm:
                return SIGALRM
            case .termination:
                return SIGTERM
        }
    }
    
    public var description: String {
        return String(cString: strsignal(self.sigValue))
    }
    #if !swift(>=4.1)
    public var hashValue: Int {
        return self.sigValue.hashValue
    }
    #endif
    #if swift(>=4.2)
    public func hash(into hasher: inout Hasher) {
        self.sigValue.hash(into: &hasher)
    }
    #endif
    
    func trapSignal(_ handler: @escaping SignalHandler) {
        
        
        #if os(Linux)
            signal(self.sigValue, handler)
        #else

        typealias SignalAction = sigaction

        // Instead of using just `signal` we can use the more powerful `sigaction`
        var signalAction = SignalAction(__sigaction_u: unsafeBitCast(handler, to: __sigaction_u.self), sa_mask: 0, sa_flags: 0)
        _ = withUnsafePointer(to: &signalAction) { actionPointer in
            sigaction(self.sigValue, actionPointer, nil)
        }
		#endif
    }
    
    public static func ==(lhs: OSSignal,
                          rhs: OSSignal) -> Bool {
        switch (lhs, rhs) {
            case (.hangup,.hangup): return true
            case (.interrupt,.interrupt): return true
            case (.illegal,.illegal): return true
            case (.trap,.trap): return true
            case (.abort,.abort): return true
            case (.kill,.kill): return true
            case (.alarm,.alarm): return true
            case (.termination,.termination): return true
            default: return false
        }
    }
}

public extension Collection where Element == OSSignal {
    func trapSignals(_ handler: @escaping OSSignal.SignalHandler) {
        var hasTrapped: [OSSignal] = []
        for sig in self {
            // Only trap signal if not already done so
            if !hasTrapped.contains(sig) {
                hasTrapped.append(sig)
                sig.trapSignal(handler)
            }
        }
    }
}
