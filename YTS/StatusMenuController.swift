//
//  StatusMenuController.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Cocoa

class StatusMenuController: NSObject {
    
    let settings = Settings.sharedInstance
    let parser = Parser()
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    
    @IBAction func preferencesClicked(_ sender: Any) {
    
    }
    
    @IBOutlet weak var updateLibraries: NSMenuItem!
    @IBAction func updateLibrariesClicked(_ sender: Any) {
        parser.startParsing()
        changeUpdates()
    }
    
    @IBOutlet weak var cancelLibrariesUpdate: NSMenuItem!
    @IBAction func cancelLibrariesUpdateClicked(_ sender: Any) {
        parser.stopParsing()
        changeUpdates()
    }
    
    private func changeUpdates() {
        updateLibraries.isEnabled = !updateLibraries.isEnabled
        cancelLibrariesUpdate.isEnabled = !cancelLibrariesUpdate.isEnabled
        
        if updateLibraries.isEnabled {
            statusItem.image = NSImage(named: "tray-off")
        } else {
            statusItem.image = NSImage(named: "tray-on")
        }
    }
    
    @IBAction func checkForUpdatesClicked(_ sender: Any) {
    
    }
    
    @IBAction func aboutClicked(_ sender: Any) {
    
    }
    
    @IBAction func quitClicked(_ sender: Any) {
        settings.save() // save settings
        NSApplication.shared().terminate(self)
    }
    
    override func awakeFromNib() {
        // Insert code here to initialize your application
        
//        Realm.Configuration.defaultConfiguration.deleteRealmIfMigrationNeeded = true
//        print("Realm Path : \(Realm.Configuration.defaultConfiguration.fileURL!.absoluteURL)")
        
        let server = Server()
        server.start()
        
        let icon = NSImage(named: "tray-off")
        statusItem.image = icon
        statusItem.menu = statusMenu
        statusMenu.autoenablesItems = false
    }
    
}
