//
//  ServerPreferencesViewController.swift
//  YTS
//
//  Created by Igor Voynov on 27.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Cocoa
import MASPreferences

class ServerPreferencesViewController: NSViewController {

    let settings = UserDefaults.standard
    
    @IBOutlet weak var portTextField: NSTextField!
    
    @IBAction func saveButton(_ sender: NSButton) {
        settings.setValue(portTextField.integerValue, forKey: "serverPort")
    }
    
    @IBAction func saveRestartButton(_ sender: NSButton) {
        settings.setValue(portTextField.integerValue, forKey: "serverPort")
        
        let server = Server.sharedInstance
        server.restart()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.portTextField.integerValue = settings.integer(forKey: "serverPort")
    }
    
    override init?(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        // set default value
        if settings.integer(forKey: "serverPort") == 0 {
            settings.set(3000, forKey: "serverPort")
        }
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("not implemented")
    }
    
}

extension ServerPreferencesViewController: MASPreferencesViewController {
    override var identifier: String? { get {return "server"} set { super.identifier = newValue} }
    
    var toolbarItemImage: NSImage? {
        return NSImage(named: NSImageNameComputer)
    }
    
    var toolbarItemLabel: String? {
        return "Server"
    }
}
