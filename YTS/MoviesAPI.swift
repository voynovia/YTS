//
//  MoviesAPI.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation

class MoviesAPI {
    
    var params = Params()
    
    struct Params {
        var limit = 20
        var page = 1
        var sort_by: String?
        var order_by: String?
        var genre: String?
        var query_term: String?
    }
    
    enum Sort: String {
        case title, year, rating, peers, seeds, download_count, like_count, date_added
        static let values = [title, year, rating, peers, seeds, download_count, like_count, date_added]
    }
    
    enum Order: String {
        case desc, asc
        static let values = [desc, asc]
    }
    
    private enum Operation {
        case Sorting( (Movie, Movie)->Bool )
    }
    
    private var sortOperations: [Sort: Operation] = [
        Sort.title: Operation.Sorting({ $0.title < $1.title }),
        Sort.year: Operation.Sorting({ $0.year > $1.year }),
        Sort.rating: Operation.Sorting({ $0.rating > $1.rating }),
//        Sort.peers: Operation.Sorting({ }),
//        Sort.seeds: Operation.Sorting({ }),
//        Sort.download_count: Operation.Sorting({ }),
//        Sort.like_count: Operation.Sorting({ }),
        Sort.date_added: Operation.Sorting({ $0.id > $1.id }),
    ]
    
    // List Movies
    func moviesInfo(params: Params) -> [String: Any] {
        
        let database = DataBase()
        var objects = Array(database.getObjects(type: Movie.self))
        
        if let genreParam = params.genre {
            objects = Array(objects.filter({$0.genres.contains(where: {$0.name == genreParam})}))
        }

        if let queryParam = params.query_term {
            objects = Array(objects.filter({ $0.title.lowercased().contains(queryParam) }))
        }

        if let sort = Sort.values.first(where: {$0.rawValue == params.sort_by }) {
            if let operation = sortOperations[sort] {
                switch operation {
                case .Sorting(let function):
                    objects.sort(by: function)
                }
            }
        }
        
        let startParam = params.limit * (params.page - 1)
        let endParam = params.page * params.limit - 1
        let end = endParam > objects.count ? objects.count - 1 : endParam

        var movies = [[String: Any]]()
        for i in stride(from: startParam, through: end, by: 1) {
            movies.append(self.detailInfo(id: objects[i].id))
        }
        if movies.count > 0 {
            var data = [String: Any]()
            data["movie_count"] = objects.count
            data["limit"] = params.limit
            data["page_number"] = params.page
            data["movies"] = movies
            return data
        }
        return [String: Any]()
    }
    
    // Movie Details
    
    func detailInfo(id: Int) -> [String: Any] {

        let database = DataBase()        
        if let movie = database.getObjects(type: Movie.self).first(where: {$0.id == id}) {
            
            var data = movie.toDictionary()
            
            // change torrents key
            var torrents = data["torrents"] as! [[String: Any]]
            for i in 0..<torrents.count {
                torrents[i].changeKey(from: "_hash", to: "hash")
            }
            data.removeValue(forKey: "torrents")
            data["torrents"] = torrents
            
            // change genres key
            var genres = [String] ()
            for genre in movie.genres {
                genres.append(genre.name)
            }
            data.removeValue(forKey: "genres")
            data["genres"] = genres
            
            return data
        } else {
            return [String: Any]()
        }
    }
        
    // Meta
    func metaInfo() -> [String: Any] {
        let tz = TimeZone.abbreviationDictionary.first { $0.value == NSTimeZone.local.identifier }
        var meta = [String: Any]()
        meta["server_time"] = Date.timeIntervalBetween1970AndReferenceDate
        meta["server_timezone"] = tz?.key ?? "MSD"
        meta["api_version"] = 2
        meta["execution_time"] = 0
        return meta
    }
    
}
