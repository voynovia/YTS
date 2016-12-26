//
//  Enums.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation

enum QualityAPI: String {
    case p1080 = "1080p", p720 = "720p"
}

enum GenreAPI: String {
    case All, Action, Adventure, Animation,
    Biography,
    Comedy, Crime,
    Documentary, Drama,
    Family, Fantasy, FilmNoir = "Film-Noir",
    History, Horror,
    Music, Musical, Mystery,
    Romance,
    SciFi = "Sci-Fi", Short, Sport,
    Thriller,
    War, Western
}
