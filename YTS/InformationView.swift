//
//  InformationView.swift
//  YTS
//
//  Created by Igor Voynov on 28.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Cocoa

class InformationView: NSView {

    @IBOutlet weak var moviesCount: NSTextField!
    @IBOutlet weak var showsCount: NSTextField!
    
    public func update(moviesCount: Int, showsCount: Int) {
        DispatchQueue.main.async {
            self.moviesCount.integerValue = moviesCount
            self.showsCount.integerValue = showsCount
        }
    }
    
}
