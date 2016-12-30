//
//  Torrentino.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation
import Kanna

class Torrentino {

    var encoding: String.Encoding = .utf8
    
    let domain: String = "http://www.torrentino.me"
    let moviesPage: String = "http://www.torrentino.me/movies?quality=hq&page="
    
    var genres: [GenreAPI: [String]] = [
        .All: ["Все"],
        .Action: ["боевик"],
        .Adventure: ["приключения"],
        .Animation: ["мультфильм", "аниме", "детский"],
        .Biography: ["биография"],
        .Comedy: ["комедия"],
        .Crime: ["криминал", "детектив"],
        .Documentary: ["документальный", "новости"],
        .Drama: ["драма"],
        .Family: ["семейный", "детский"],
        .Fantasy: ["фэнтези"],
        .FilmNoir: ["фильм-нуар"],
        .History: ["история"],
        .Horror: ["ужасы"],
        .Music: ["музыка", "концерт"],
        .Musical: ["мюзикл"],
        .Mystery: ["ужасы"],
        .Romance: ["мелодрама"],
        .SciFi: ["фантастика"],
        .Short: ["короткометражка"],
        .Sport: ["спорт"],
        .Thriller: ["триллер", "детектив"],
        .War: ["военный"],
        .Western: ["вестерн"]
    ]
    
    var audio = ["iTunes", "Лицензия", "Дублированный"]
    
    var sort = ["date", "rating", "popularity"]
    
    func parsePage(html: String) -> [String] {
        var links = [String]()
        if let doc = Kanna.HTML(html: html, encoding: encoding) {
            for item in doc.css("section div.plate div.tiles div.tile a") {
                links.append(item["href"]!)
            }
        }
        return links
    }
    
    func parseMovie(html: String, url: String) {
            
        if let doc = Kanna.HTML(html: html, encoding: encoding) {

            var torrents = [Torrent]()
            var genres = [Genre]()
            
            let movie = Movie()
            movie.id = Int(url.between(from: "/", to: "-")!)!
            movie.imdb_code = String(movie.id)
            movie.slug = url.toEnd(from: "-")
            
            // Add Files Information
            // ------------------------
            var need1080 = true
            var need720 = true
            var currentQuality = QualityAPI.p720
            var adding = false
            if let list = doc.at_css("div.main div.entity div.list-start table.quality") {
                for item in list.css("tr.item") {
                    if let qualityText = item.at_css("td.video")?.text,
                        let audioText = item.at_css("td.audio")?.text?.trim() {
                        
                        if qualityText.contains("1920") && need1080 && audio.contains(audioText) {
                            currentQuality = QualityAPI.p1080
                            adding = true
                            need1080 = false
                        } else if qualityText.contains("720") && need720 && audio.contains(audioText) {
                            currentQuality = QualityAPI.p720
                            adding = true
                            need720 = false
                        }
                        
                        if adding {
                            let torrent = Torrent()
                            torrent.idMovie = movie.id
                            torrent.qualityEnum = currentQuality
                            if let sizeString = item.at_css("td.size")?.text, let size = sizeString.toDouble {
                                torrent.size = sizeString.contains("ГБ") ? String(describing: size) + " GB" : String(describing: size) + " MB"
                                torrent.size_bytes = String(Int(size) * 1000000000)
                            }
                            torrent.date_uploaded = item.at_css("td.updated")?.text?.changeDateFormat(fromFormat: "dd.MM.yyyy", toFormat: "yyyy-MM-dd HH:mm:ss")
                            torrent.date_uploaded_unix = torrent.date_uploaded?.toUnixTime(format: "yyyy-MM-dd HH:mm:ss") ?? 0.0
                            torrent.seeds = item.at_css("td.seed-leech span.seed")?.text?.toInteger ?? 0
                            torrent.peers = item.at_css("td.seed-leech span.leech")?.text?.toInteger ?? 0
                            torrent.url = item.at_css("td.download a[data-type=download]")?["data-torrent"]
                            torrent._hash = item.at_css("td.download a[data-type=download]")?["data-default"]?.between(from: "btih:", to: "&")
                            
                            torrents.append(torrent)
                            
                            adding = false
                        }
                    }
                }
            }
            
            // Add Movie Information
            // ------------------------
            
            if torrents.count > 0 {
                if let head = doc.at_css("div.main div.entity div.head-plate") {
                    
                    movie.title = head.at_css("h1[itemprop='name']")?.text
                    movie.year = head.at_css("td[itemprop='copyrightYear']")?.text?.toInteger ?? 2000
                    movie.rating = head.at_css("meta[itemprop='ratingValue']")?["content"]?.toDouble ?? 0.0
                    if let runtime = head.at_css("td[itemprop='duration']")?["datetime"] {
                        if let hours = runtime.between(from: "PT", to: "H")?.toInteger,
                            let minutes = runtime.between(from: "H", to: "M")?.toInteger {
                            movie.runtime = hours * 60 + minutes
                        }
                    }
                    movie.small_cover_image = "https://st.kp.yandex.net/images/film_iphone/iphone360_"+String(movie.id)+".jpg"
                    movie.medium_cover_image = "https://st.kp.yandex.net/images/film_big/"+String(movie.id)+".jpg"
                    let synopsis = head.xpath("//div[@class='specialty']/text()")[1].text?.trim()
                    movie.synopsis = synopsis != nil ? head.at_css("div.specialty p")?.text : synopsis
                    movie.yt_trailer_code = nil
            
                    for item in head.css("a[href*=genres]") {
                        let name = (item["href"]?.toEnd(from: "="))!
                        if let genreYts = self.genres.first(where: { $0.value.contains(name)}) {
                            let genre = Genre()
                            genre.name = (genreYts.key.rawValue)
                            genres.append(genre)
                        } else {
                            print("Для", name, "нет соответствия")
                        }
                    }
                    
                }
                
                // save in database
                let database = DataBase()
                database.executeInTransaction(execute: {
                
                    database.updateInTransaction(object: movie)
                    
                    for torrent in torrents {
                        database.updateInTransaction(object: torrent)
                        movie.torrents.append(torrent)
                    }
                    
                    if genres.count > 0 {
                        for genre in genres {
                            database.updateInTransaction(object: genre)
                            movie.genres.append(genre)
                        }
                    } else {
                        let genre = Genre()
                        genre.name = GenreAPI.All.rawValue
                        movie.genres.append(genre)
                    }
                    
                })
                
            }
            
        }
        
    }

    
}
