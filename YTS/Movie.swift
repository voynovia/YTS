//
//  Movie.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation
import RealmSwift

class Movie: Object {
    dynamic var id: Int = 0
    dynamic var url: String? // -
    dynamic var imdb_code: String?
    dynamic var title: String!
    dynamic var title_long: String? // -
    dynamic var slug: String?
    dynamic var year: Int = 2000
    public var genres = List<Genre>()
    //directors
    //cast
    dynamic var rating: Double = 0
    dynamic var runtime: Int = 0
    dynamic var language: String = "English" // -
    dynamic var small_cover_image: String? // -
    dynamic var medium_cover_image: String?
    // background_image
    dynamic var synopsis: String?
    dynamic var trailer: String? // yt_trailer_code
    // google_video
    // mpa_rating
    var torrents = List<Torrent>()
    
    dynamic var state: String = "ok" // -
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}
