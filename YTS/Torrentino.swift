//
//  Torrentino.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation
import Kanna
import RealmSwift

class Torrentino {

    var encoding: String.Encoding = .utf8
    
    let domain: String = "http://www.torrentino.me"
    let moviesPage: String = "http://www.torrentino.me/movies?quality=hq"
    let movieLink: String = "section div.plate div.tiles div.tile a"
    
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
    
    enum Sort: String {
        case date, rating, popularity
        static let values = [date, rating, popularity]
    }
    
    func parsePage(html: String) -> [String] {
        var links = [String]()
        if let doc = Kanna.HTML(html: html, encoding: encoding) {
            for item in doc.css(movieLink) {
                links.append(item["href"]!)
            }
        }
        return links
    }
    
    func parseMovie(html: String, url: String) {
        
        if let doc = Kanna.HTML(html: html, encoding: encoding) {
            
            let realm = try! Realm()
            realm.beginWrite()
            
            let movie = Movie()
            movie.id = Int(url.slice(from: "/", to: "-")!)!
            movie.url = url
            movie.imdb_code = String(movie.id)
            movie.slug = url.toEnd(from: "-")
            
            // Add Files Information
            // ------------------------
            var addedFiles = false
            
            var need1080 = true
            var need720 = true
            var currentQuality = QualityAPI.p1080
            var adding = false
            if let list = doc.at_css("div.main div.entity div.list-start table.quality") {
                for item in list.css("tr.item") {
                    if let quality = item.at_css("td.video")?.text, let languages = item.at_css("td.languages")?.text {
                        
                        if quality.contains("1920") && need1080 && languages.contains("ru") {
                            currentQuality = QualityAPI.p1080
                            adding = true
                            need1080 = false
                        } else if quality.contains("720") && need720 && languages.contains("ru") {
                            currentQuality = QualityAPI.p720
                            adding = true
                            need720 = false
                        }
                        if adding {
                            let torrent = Torrent()
                            torrent.idMovie = movie.id
                            torrent.qualityEnum = currentQuality
                            if let sizeString = item.at_css("td.size")?.text! {
                                torrent.size = sizeString.contains("ГБ") ? sizeString.digitsWithDot + " GB" : sizeString.digitsWithDot + " MB"
                                torrent.size_bytes = String(describing: Double(sizeString.digitsWithDot)! * 1000000000)
                            }
                            torrent.date_uploaded = item.at_css("td.updated")?.text!.changeDateFormat(from: "dd.MM.yyyy", to: "yyyy-MM-dd HH:mm:ss")
                            torrent.date_uploaded_unix = torrent.date_uploaded?.toUnixTime(from: "yyyy-MM-dd HH:mm:ss")
                            torrent.seeds = Int((item.at_css("td.seed-leech span.seed")?.text)!)!
                            torrent.peers = Int((item.at_css("td.seed-leech span.leech")?.text)!)!
                            let magnet = item.at_css("td.download a[data-default^=magnet]")?["data-default"]!
                            torrent.url = magnet
                            torrent._hash = magnet?.slice(from: "btih:", to: "&")
                            
                            realm.add(torrent, update: true)
                            movie.torrents.append(torrent)
                            
                            addedFiles = true
                            
                            adding = false
                        }
                    }
                }
            }
            
            // Add Movie Information
            // ------------------------
            
            if addedFiles {
                if let head = doc.at_css("div.main div.entity div.head-plate") {
                    movie.title = head.at_css("h1[itemprop='name']")?.text
                    movie.title_long = head.at_css("h2[itemprop='alternateName']")?.text
                    movie.year = Int((head.at_css("td[itemprop='copyrightYear']")?.text)!)!
                    if let rating = head.at_css("meta[itemprop='ratingValue']")?["content"] {
                        movie.rating = Double(rating)!
                    }
                    //                movie.small_cover_image = head.at_css("div.cover img")?["src"]
                    movie.small_cover_image = "https://st.kp.yandex.net/images/film_iphone/iphone360_"+String(movie.id)+".jpg"
                    movie.medium_cover_image = "https://st.kp.yandex.net/images/film_big/"+String(movie.id)+".jpg"
                    let synopsis = head.xpath("//div[@class='specialty']/text()")[1].text!.trim()
                    movie.synopsis = synopsis.isEmpty ? head.at_css("div.specialty p")?.text : synopsis
                    movie.trailer = nil
                    for item in head.css("a[href*=genres]") {
                        let name = (item["href"]?.toEnd(from: "="))!
                        if let genreYts = genres.first(where: { $0.value.contains(name)}) {
                            let genre = Genre()
                            genre.name = (genreYts.key.rawValue)
                            realm.add(genre, update: true)
                            movie.genres.append(genre)
                        } else {
                            print("Для", name, "нет соответствия")
                        }
                    }
                }
                realm.add(movie, update: true)
            }
            
            try! realm.commitWrite()
        }
        
    }

    
}
