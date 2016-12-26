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
    
    private let tracker = Torrentino()
    
    private let settings = Settings.sharedInstance

    private var parsePage = 1 // the initial page for processing
    private var parseDelay = 5.0 // the delay between the processing
    private var links = [String]() // links to movies
    
    private var stop = false { didSet { if stop { links.removeAll() } } }
    
    init() {
        if let parseUpdate = settings.getValue(key: "parseUpdate") as? Date,
            let parsePage = settings.getValue(key: "parsePage") as? Int,
            let parseDelay = settings.getValue(key: "parseDelay") as? Double {
            
            self.parsePage = parsePage
            self.parseDelay = parseDelay
            
            let hoursCount = Calendar.current.dateComponents([.hour], from: parseUpdate, to: Date()).hour ?? 0
            if hoursCount > 24 {
                settings.setValue(key: "parseUpdate", value: Date())
                settings.setValue(key: "parsePage", value: 1)
            }
        } else {
            settings.setValue(key: "parseUpdate", value: Date())
            settings.setValue(key: "parsePage", value: self.parsePage)
            settings.setValue(key: "parseDelay", value: self.parseDelay)
        }
    }
    
    public func startParsing(slow: Bool = true) {
        settings.setValue(key: "parsePage", value: self.parsePage) // save the number of the processed page
        let link = tracker.moviesPage + "&page=\(self.parsePage)"
        if slow {
            self.requestSlow(url: link, operation: .All, delay: parseDelay)
        } else {
            
        }
    }
    
    public func stopParsing() {
        self.stop = true
    }
    
    private func requestSlow(url: String, operation: ParseOperation, delay: Double) {
        var url = url
        if !url.contains(tracker.domain) {
            url = tracker.domain + url
        }
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
                            self.requestSlow(url: self.links[0], operation: .One, delay: delay)
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
