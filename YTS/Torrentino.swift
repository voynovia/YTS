//
//  Torrentino.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation
import Kanna

protocol TrackerDelegate {
    func requestFast(url: String, operation: ParseOperation)
    func parsedPage()
}

class Torrentino {

    var delegate: TrackerDelegate!
    
    var encoding: String.Encoding = .utf8
    
    let domain: String = "http://www.torrentino.me"
    let moviesPage: String = "http://www.torrentino.me/movies?quality=hq&page="
    let searchMoviesPage: String = "http://www.torrentino.me/search?type=movies&page="
    
    let movieLink: String = "section div.plate div.tiles div.tile a" // ссылка на страницу с фильмом
    
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
    
    let audio = ["iTunes", "Лицензия", "Дублированный"]
    
    var sort = ["date", "rating", "popularity"]
    
    func parsePage(html: String) -> [String] {
        var links = [String]()
        if let doc = Kanna.HTML(html: html, encoding: encoding) {
            for item in doc.css(movieLink) {
                links.append(item["href"]!)
            }
        }
        return links
    }
    
    func parsePageFast(html: String) {
        if let doc = Kanna.HTML(html: html, encoding: encoding) {
            for item in doc.css(movieLink) {
                delegate.requestFast(url: item["href"]!, operation: ParseOperation.One)
            }
        }
        self.delegate.parsedPage()
    }
    
    func parseMovie(html: String, url: String, fast: Bool = false) {
            
        if let doc = Kanna.HTML(html: html, encoding: encoding) {

            var genres = [Genre]()
            
            let movie = Movie()
            movie.id = Int(url.between(from: "/", to: "-")!)!
            movie.imdb_code = String(movie.id)
            movie.slug = url.toEnd(from: "-")
            
            // Add Files Information
            // ------------------------

            var torrent720: Torrent?
            var torrent1080: Torrent?
            
            if let list = doc.at_css("div.main div.entity div.list-start table.quality") {
                
                var group: String?
                for item in list.css("tr.item") {

                    if let quality = item.at_css("td.quality a.group-label") {
                        if (quality["title"]?.contains("Blu-ray"))! || (quality["title"]?.contains("BDRip"))! || (quality["title"]?.contains("HDRip"))! {
                            group = quality["data-group"]
                        } else {
                            continue
                        }
                    } else {
                        if item["data-group"] != group {
                            continue
                        }
                    }
                    
                    if let videoText = item.at_css("td.video")?.text, let audioText = item.at_css("td.audio")?.text?.trim(),
                        let seedsText = item.at_css("td.seed-leech span.seed")?.text?.toInteger {
                        
                        let curTorrent = Torrent()
                        if videoText.hasPrefix("1280") && audio.contains(audioText) {
                            if let maxSeeds = torrent1080?.seeds {
                                if seedsText < maxSeeds {
                                    continue
                                }
                            }
                            curTorrent.qualityEnum = QualityAPI.p1080
                            torrent1080 = curTorrent
                        } else if videoText.hasPrefix("720") && audio.contains(audioText) {
                            if let maxSeeds = torrent720?.seeds {
                                if seedsText < maxSeeds {
                                    continue
                                }
                            }
                            curTorrent.qualityEnum = QualityAPI.p720
                            torrent720 = curTorrent
                        } else {
                            continue
                        }
                        
                        curTorrent.idMovie = movie.id
                        if let sizeString = item.at_css("td.size")?.text, let size = sizeString.toDouble {
                            curTorrent.size = sizeString.contains("ГБ") ? String(describing: size) + " GB" : String(describing: size) + " MB"
                            curTorrent.size_bytes = String(Int(size) * 1000000000)
                        }
                        curTorrent.date_uploaded = item.at_css("td.updated")?.text?.changeDateFormat(fromFormat: "dd.MM.yyyy", toFormat: "yyyy-MM-dd HH:mm:ss")
                        curTorrent.date_uploaded_unix = curTorrent.date_uploaded?.toUnixTime(format: "yyyy-MM-dd HH:mm:ss") ?? 0.0
                        curTorrent.seeds = seedsText
                        curTorrent.peers = item.at_css("td.seed-leech span.leech")?.text?.toInteger ?? 0
                        curTorrent.url = item.at_css("td.download a[data-type=download]")?["data-torrent"]
                        curTorrent._hash = item.at_css("td.download a[data-type=download]")?["data-default"]?.between(from: "btih:", to: "&")
                        
                    }
                    
                }
            }
            
            // Add Movie Information
            // ------------------------
            
            if torrent720 != nil || torrent1080 != nil {

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
                    
                    if let synopsis = head.xpath("//div[@class='specialty']/text()")[1].text?.trim(), !synopsis.isEmpty {
                        movie.synopsis = synopsis
                    } else {
                        movie.synopsis = head.at_css("div.specialty p")?.text
                    }
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

                    if let tor = torrent720 {
                        database.updateInTransaction(object: tor)
                        movie.torrents.append(tor)
                    }
                    if let tor = torrent1080 {
                        database.updateInTransaction(object: tor)
                        movie.torrents.append(tor)
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
    
        if fast {
            self.delegate.parsedPage()
        }
        
    }
    
}
