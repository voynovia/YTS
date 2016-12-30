//
//  Torrent.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation
import RealmSwift

class Torrent: Object {
    
    dynamic var idMovie: Int = 0 { didSet { compoundKey = compoundKeyValue() } }
    dynamic var url: String?
    dynamic var _hash: String?
    dynamic var quality: String = QualityAPI.p1080.rawValue { didSet { compoundKey = compoundKeyValue() } }
    dynamic var seeds: Int = 0
    dynamic var peers: Int = 0
    dynamic var size: String?
    dynamic var size_bytes: String?
    dynamic var date_uploaded: String?
    dynamic var date_uploaded_unix: Double = 0.0
    
    var qualityEnum: QualityAPI {
        get {
            return QualityAPI(rawValue: quality)!
        }
        set {
            quality = newValue.rawValue
        }
    }
    
    dynamic var compoundKey: String = "0-quality"
    override static func primaryKey() -> String? {
        return "compoundKey"
    }
    func compoundKeyValue() -> String {
        return "\(idMovie)-\(quality)"
    }
    
}
