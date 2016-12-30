//
//  Dictionary.swift
//  YTS
//
//  Created by Igor Voynov on 30.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation

extension Dictionary {
    mutating func changeKey(from: Key, to: Key) {
        self[to] = self[from]
        self.removeValue(forKey: from)
    }
}
