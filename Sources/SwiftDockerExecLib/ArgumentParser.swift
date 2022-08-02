//
//  ArgumentParser.swift
//  
//
//  Created by Tyler Anger on 2022-03-31.
//

import Foundation

/// Structure used to define a CLI Argument
public struct Argument {
    /// Parsed Results from a CLI Argument
    public enum Parsed {
        case errMessage(String)
        case value(Any)
        
        public var errorMessage: String? {
            guard case .errMessage(let rtn) = self else {
                return nil
            }
            return rtn
        }
        public var object: Any? {
            guard case .value(let rtn) = self else {
                return nil
            }
            return rtn
        }
        
        public static func failedToParse(message: String) -> Parsed {
            return .errMessage(message)
        }
        
        public static func parsed(_ object: Any) -> Parsed {
            return .value(object)
        }
        
    }
    /// Template for closures to parse arguments
    /// - Parameters:
    ///   - arguments: The CLI Arguments
    ///   - startingAt: The current position in the arguments to look for the given parameter.  If does not match do not update startingAt,  If matches then increment startingAt
    ///   - object:  The current value for the parameter.  This allows the parameter to be passed multiple times if needed
    ///  - Returns: Returns the parsed object from the closure to indicate of the parameter was parsed or not
    public typealias Parser = (_ arguments: [String], _ startingAt: inout Int, _ object: Any?) -> Parsed
    /// The Short hand argument for the parameter if there is one
    public let short: String?
    /// The long hand argument for hte parameter if there is one
    public let long: String?
    /// Any additional parameter names (For usage display)
    public let additionalParamName: String?
    /// The description of the paramter (For usage display
    public let description: String
    /// The parser used to parse the parameter
    private let customParser: Parser
    
    
    public init(short: String,
                long: String? = nil,
                additionalParamName: String? = nil,
                description: String,
                parser: Parser? = nil) {
        self.short = short
        self.long = long
        self.additionalParamName = additionalParamName
        self.description = description
        self.customParser = parser ?? Argument.defaultParser
    }
    
    public init(long: String,
                additionalParamName: String? = nil,
                description: String,
                parser: Parser? = nil) {
        self.short = nil
        self.long = long
        self.additionalParamName = additionalParamName
        self.description = description
        self.customParser = parser ?? Argument.defaultParser
    }
    
    public func helpDisplayObjects(argumentShortPrefix: String = "-",
                                   argumentLongPrefix: String = "--") -> (arguments: String, description: String) {
        var args: String = ""
        if let a = self.short {
            if !args.isEmpty { args += ", " }
            args += argumentShortPrefix + a
        }
        if let a = self.long {
            if !args.isEmpty { args += ", " }
            args += argumentLongPrefix + a
        }
        if let add = self.additionalParamName {
            if !args.isEmpty { args += " " }
            args += add
        }
        
        return (arguments: args, description: self.description)
    }
    
    private static func defaultParser(_ arguments: [String],
                                      _ startingAt: inout Int,
                                      _ object: Any?) -> Parsed {
        return .parsed(true)
    }
    
    
    public func parse(argumentShortPrefix: String = "-",
                      argumentLongPrefix: String = "--",
                      arguments: [String],
                      startingAt index: inout Int,
                      currentParsedValue parsedValue: Any? = nil) -> Parsed? {
        guard index >= 0 && index < arguments.count else {
            return nil
        }
        var args: [String] = []
        if let v = self.short?.lowercased() {
            args.append(argumentShortPrefix + v)
            args.append(argumentLongPrefix + v)
        }
        if let v = self.long?.lowercased() {
            args.append(argumentShortPrefix + v)
            args.append(argumentLongPrefix + v)
        }
        
        guard args.contains(arguments[index].lowercased()) else {
            return nil
        }
        
        index += 1
        
        return self.customParser(arguments, &index, parsedValue)
    }
    
    public static let helpArgument = Argument(short: "h",
                                                long: "help",
                                                description: "Display Help Screen")
    
    public static let versionArgument = Argument(long: "version",
                                                 description: "Display the version of the application")
}

