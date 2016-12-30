//
//  Realm+Extensions.swift
//  YTS
//
//  Created by Igor Voynov on 28.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation
import RealmSwift

extension RealmSwift.Results {
    func toDictionary() -> [[String: Any]] {
        var objects = [[String: Any]]()
        for object in self {
            objects.append(object.toDictionary())
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
