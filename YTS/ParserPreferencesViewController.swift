//
//  ParserPreferencesViewController.swift
//  YTS
//
//  Created by Igor Voynov on 27.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Cocoa
import MASPreferences

class ParserPreferencesViewController: NSViewController {

    let settings = UserDefaults.standard
    
    @IBOutlet weak var delayTextField: NSTextField!
    @IBOutlet weak var autostartCheckBox: NSButton!
    
    @IBAction func saveButton(_ sender: NSButton) {
        settings.setValue(delayTextField.doubleValue, forKey: "parseDelay")
        settings.set(autostartCheckBox.state == NSOnState ? true : false, forKey: "parserAutostart")
    }
        
    override func viewDidLoad() {
        super.viewDidLoad()
        self.delayTextField.doubleValue = settings.double(forKey: "parseDelay")
        self.autostartCheckBox.state = settings.bool(forKey: "parserAutostart") == false ? NSOffState : NSOnState
    }
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        // set default value
        if settings.object(forKey: "parseUpdate") == nil {
            settings.set(Date(), forKey: "parseUpdate")
        }
        if settings.integer(forKey: "parsePage") == 0 {
            settings.set(1, forKey: "parsePage")
        }
        if settings.double(forKey: "parseDelay") == 0 {
            settings.set(10.0, forKey: "parseDelay")
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
}

extension ParserPreferencesViewController: MASPreferencesViewController {
    override var identifier: String? { get {return "parser"} set { super.identifier = newValue} }
    
    var toolbarItemImage: NSImage? {
        return NSImage(named: NSImageNameNetwork)
    }
    
    var toolbarItemLabel: String? {
        return "Parser"
    }
}
