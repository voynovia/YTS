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
    func parserFailure(error: Error)
}

class Parser {
    
    static let sharedInstance: Parser = {
        let instance = Parser()
        return instance
    }()
    
    var delegate: ParserDelegate?
    
    private let settings = UserDefaults.standard
    
    private let tracker = Torrentino()
    
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
            // TODO: fast parsing
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
        print(url)
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
    
}
