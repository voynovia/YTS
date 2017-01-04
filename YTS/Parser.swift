//
//  Parser.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation
import Alamofire

enum ParseOperation {
    case All, One
}

protocol ParserDelegate {
    func updateCount()
    func parserStateDidUpdate(running: Bool)
    func parserFailure(error: Error)
}

class Parser {
    
//    static let sharedInstance: Parser = {
//        let instance = Parser()
//        return instance
//    }()
    
    var delegate: ParserDelegate?
    
    private let settings = UserDefaults.standard
    
    fileprivate let tracker = Torrentino()
    
    let parseGroup =  DispatchGroup()
    
    private var links = [String]() // links to movies
    private var parsingPage: Int = 1
    
    private var stop = false {
        didSet {
            if stop {
                links.removeAll()
            } else if self.clean {
                let database = DataBase()
                database.deleteAll()
                self.resetSettings()
                self.clean = false
                self.delegate?.updateCount()
            }
        }
    }
    private var clean = false
    
    private var running = false
    
    init() {
        tracker.delegate = self
    }
    
    
    public func cleanBase() {
        if running {
            self.stopParsing()
            self.clean = true
        } else {
            let database = DataBase()
            database.deleteAll()
            self.resetSettings()
            self.delegate?.updateCount()
        }
    }
    
    private func resetSettings() {
        settings.set(Date(), forKey: "parseUpdate")
        settings.set(1, forKey: "parsePage")
    }
    
    public func startParsing(slow: Bool = true) {
        self.running = true
        
        self.delegate?.parserStateDidUpdate(running: true)
        
        if let lastdate = settings.object(forKey: "parseUpdate") as? Date {
            let hoursCount = Calendar.current.dateComponents([.hour], from: lastdate, to: Date()).hour ?? 0
            if hoursCount > 24 {
                self.resetSettings()
            }
        }
        self.parsingPage = self.settings.integer(forKey: "parsePage")
        
        let link = tracker.moviesPage + String(parsingPage)
        if slow {
            self.requestSlow(url: link, operation: .All)
        } else {
            self.requestFast(url: link, operation: .All)
        }
    }
    
    public func stopParsing() {
        self.stop = true
    }
    
    private func requestSlow(url: String, operation: ParseOperation) {
        var url = url
        if !url.contains(tracker.domain) {
            url = tracker.domain + url
        }
        let delay = settings.double(forKey: "parseDelay") // the delay may change
        Alamofire.request(url).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let text = String(data: data, encoding: self.tracker.encoding) {
                    DispatchQueue.background(delay: delay, background: {
                        switch operation {
                        case .All:
                            let links = self.tracker.parsePage(html: text)
                            self.links = links
                        case .One:
                            self.tracker.parseMovie(html: text, url: url)
                        }
                    }, completion: {
                        if self.stop {
                            self.running = false
                            self.stop = false
                            self.delegate?.parserStateDidUpdate(running: false)
                            return
                        }
                        if self.links.count > 0 {
                            self.requestSlow(url: self.links[0], operation: .One)
                            self.links.remove(at: 0)
                            self.delegate?.updateCount()
                        } else {
                            self.settings.setValue(self.parsingPage + 1, forKey: "parsePage") // save new number of the processed page
                            self.startParsing(slow: true)
                        }
                    })
                }
            case .failure(let error):
                self.delegate?.parserFailure(error: error)
            }
        }
    }
    
    public func search(query: String) {
        let link = tracker.searchMoviesPage + String(parsingPage) + "&search=\(query)"
        
        var wait = false
        self.requestFast(url: link, operation: .All)
        self.parseGroup.notify(queue: DispatchQueue.main, execute: {
            wait = true
        })
        while !wait {
            // wait search results
        }
    }
    
}

extension Parser: TrackerDelegate {
    
    func parsedPage() {
        self.parseGroup.leave()
    }
    
    func requestFast(url: String, operation: ParseOperation) {
        var url = url
        if !url.contains(self.tracker.domain) {
            url = self.tracker.domain + url
        }
        let urlEncoded = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        self.parseGroup.enter()
        Alamofire.request(urlEncoded!).responseData { response in
            switch response.result {
            case .success:
                if let data = response.result.value, let text = String(data: data, encoding: self.tracker.encoding) {
                    switch operation {
                    case .All: self.tracker.parsePageFast(html: text)
                    case .One: self.tracker.parseMovie(html: text, url: url, fast: true)
                    }
                }
            case .failure(let error):
                self.parseGroup.enter()
                self.delegate?.parserFailure(error: error)
            }
        }
    }
    
}
