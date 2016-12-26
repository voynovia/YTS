//
//  Settings.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Foundation

class Settings {
    
    static let sharedInstance: Settings = {
        let instance = Settings()
        return instance
    }()
    
    var url: URL!
    var dictionary: [String: Any] = [:]
    
    convenience init() {
        self.init(name: "Settings")
    }
    
    init(name: String) {
        let fileManager = FileManager.default
        let applicationSupportDirectory = try! fileManager.url(for: .applicationSupportDirectory,
                                                               in: .userDomainMask,
                                                               appropriateFor: nil,
                                                               create: true)
        let dirName = applicationSupportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier!)
        self.url = dirName.appendingPathComponent("\(name).plist")
        
        if !fileManager.fileExists(atPath: self.url.path) {
            do {
                try fileManager.createDirectory(atPath: dirName.path, withIntermediateDirectories: true, attributes: nil)
                self.save()
            } catch {
                print(error)
            }
        }
        self.read()
    }
    
    func save() {
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: self.dictionary, format: .xml, options: 0)
            try data.write(to: self.url)
        } catch {
            print(error)
        }
    }
    
    func read() {
        do {
            let data = try Data(contentsOf: self.url)
            self.dictionary = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as! [String:Any]
        } catch {
            print(error)
        }
    }
    
    func getDictionary() -> [String:Any] {
        return dictionary
    }
    
    func getValue(key: String) -> Any? {
        return dictionary[key]
    }
    
    func setValue(key: String, value: Any) {
        dictionary[key] = value
    }
    
}
