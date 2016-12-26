//
//  Genre.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation
import RealmSwift

class Genre: Object {
    
    dynamic var name: String = GenreAPI.All.rawValue
    
    var genreEnum: GenreAPI {
        get {
            return GenreAPI(rawValue: name)!
        }
        set {
            name = newValue.rawValue
        }
    }
    
    override static func primaryKey() -> String? {
        return "name"
    }
}
