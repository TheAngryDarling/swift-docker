//
//  String+SwiftDockerExecLib.swift
//  
//
//  Created by Tyler Anger on 2023-05-23.
//

import Foundation

internal extension String {
    
    func ranges(of aString: String,
                options: CompareOptions = [],
                range searchRange: Range<String.Index>? = nil,
                locale: Locale? = nil) -> [Range<String.Index>] {
        var rtn: [Range<String.Index>] = []
        
        let withIn = searchRange ?? self.startIndex..<self.endIndex
        
        var from = withIn.lowerBound
        while let r = self.range(of: aString, options: options, range: from..<withIn.upperBound, locale: locale) {
            rtn.append(r)
            from = r.upperBound
        }
        
        return rtn
    }
    func countOccurances(of aString: String,
                         options: CompareOptions = [],
                         range searchRange: Range<String.Index>? = nil,
                         locale: Locale? = nil) -> Int {
        let r = self.ranges(of: aString,
                            options: options,
                            range: searchRange,
                            locale: locale)
        return r.count
        
    }
}
