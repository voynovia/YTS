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

class Parser {
    
    static let sharedInstance: Parser = {
        let instance = Parser()
        return instance
    }()
    
    private let settings = UserDefaults.standard
    
    private let tracker = Torrentino()
    
    private var parsePage = 1 // the initial page for processing
    private var links = [String]() // links to movies
    
    private var stop = false { didSet { if stop { links.removeAll() } } }
    
    init() {
        if let lastdate = settings.object(forKey: "parseUpdate") as? Date {
            let hoursCount = Calendar.current.dateComponents([.hour], from: lastdate, to: Date()).hour ?? 0
            if hoursCount > 24 {
                settings.set(Date(), forKey: "parseUpdate")
                settings.set(1, forKey: "parsePage")
            }
        }
        self.parsePage = settings.integer(forKey: "parsePage")
    }
    
    public func startParsing(slow: Bool = true) {
        settings.setValue(self.parsePage, forKey: "parsePage") // save the number of the processed page
        let link = tracker.moviesPage + "&page=\(self.parsePage)"
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
        let delay = settings.double(forKey: "parseDelay") // the delay may change
        print(url, " with delay:", delay)
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
                        print("parsed: \(url)")
                        if self.stop {
                            print("stop parsing")
                            self.stop = false
                            return
                        }
                        if self.links.count > 0 {
                            self.requestSlow(url: self.links[0], operation: .One)
                            self.links.remove(at: 0)
                        } else {
                            self.parsePage += 1
                            self.startParsing(slow: true)
                        }
                    })
                }
            case .failure(let error):
                print("\(url) is failure: \(error)")
            }
        }
    }
    
}
