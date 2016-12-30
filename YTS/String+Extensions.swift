//
//  String+Extensions.swift
//  YTS
//
//  Created by Igor Voynov on 30.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation

extension String {
    
    func toEnd(from: String, fromEnd: Bool = false) -> String? {
        guard let index = range(of: from, options: fromEnd ? [.backwards, .caseInsensitive] : [.caseInsensitive] )?.upperBound else { return nil }
        return substring(from: index)
    }
    
    func between(from: String, to: String, fromEnd: Bool = false) -> String? {
        guard let endIndex = self.range(of: to, options: fromEnd ? [.backwards, .caseInsensitive] : [.caseInsensitive] )?.lowerBound,
            let startIndex = self.range(of: from, options: .backwards, range: self.startIndex..<endIndex)?.upperBound else { return nil }
        return self.substring(with: startIndex..<endIndex)
    }
    
    var toDouble: Double? {
        return (self as NSString).doubleValue
    }
    
    var toInteger: Int? {
        return (self as NSString).integerValue
    }
    
    func changeDateFormat(fromFormat: String, toFormat: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = fromFormat
        guard let str = formatter.date(from: self) else { return nil }
        formatter.dateFormat = toFormat
        return formatter.string(from: str)
    }
    
    func toUnixTime(format: String) -> Double? {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        guard let unixTime = formatter.date(from: self)?.timeIntervalSince1970 else { return nil }
        return unixTime
    }
    
}
