//
//  Extensions.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation
import RealmSwift

extension String {
    
    func toEnd(from: String) -> String? {
        let index = range(of: from)?.upperBound
        return substring(from: index!)
    }
    
    func slice(from: String, to: String) -> String? {
        return (range(of: from, options: .backwards)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                substring(with: substringFrom..<substringTo)
            }
        }
    }
    
    var digitsWithDot: String {
        return String(characters.filter { String($0).rangeOfCharacter(from: CharacterSet(charactersIn: ".0123456789")) != nil })
    }
    
    func changeDateFormat(from: String, to: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = from
        if let str = formatter.date(from: self) {
            formatter.dateFormat = to
            return formatter.string(from: str)
        } else {
            return nil
        }
    }
    
    func toUnixTime(from: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = from
        let g = formatter.date(from: self)
        if let double = g?.timeIntervalSince1970 {
            return String(Int(double))
        } else {
            return nil
        }
    }
    
}

extension DispatchQueue {
    static func background(delay: Double = 0.0, background: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            background?()
            if let completion = completion {
                DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: {
                    completion()
                })
            }
        }
    }
}

extension Dictionary {
    mutating func changeKey(from: Key, to: Key) {
        self[to] = self[from]
        self.removeValue(forKey: from)
    }
}

extension RealmSwift.Results {
    func toDictionary() -> [[String: Any]] {
        var objects = [[String: Any]]()
        for i in 0..<self.count {
            objects.append(self[i].toDictionary())
        }
        return objects
    }
}

extension RealmSwift.Object {
    func toDictionary() -> [String: Any] {
        let properties = self.objectSchema.properties.map { $0.name }
        var dictionary = self.dictionaryWithValues(forKeys: properties)
        for prop in self.objectSchema.properties as [Property]! {
            if let nestedObject = self[prop.name] as? Object {
                dictionary[prop.name] = nestedObject.toDictionary()
            } else if let nestedListObject = self[prop.name] as? ListBase {
                var objects = [[String: Any]]()
                for index in 0..<nestedListObject._rlmArray.count {
                    let object = nestedListObject._rlmArray[index] as AnyObject
                    objects.append(object.toDictionary())
                }
                dictionary[prop.name] = objects
            }
        }
        return dictionary
    }
}
