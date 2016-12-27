//
//  StatusMenuController.swift
//  YTS
//
//  Created by Igor Voynov on 26.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Cocoa
import MASPreferences

class StatusMenuController: NSObject {
    
    let parser = Parser.sharedInstance
    
    var aboutWindow: AboutWindowController!
    var preferencesWindowController: MASPreferencesWindowController!
    
    @IBOutlet weak var statusMenu: NSMenu!
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    
    @IBAction func preferencesClicked(_ sender: Any) {
        self.preferencesWindowController.showWindow(nil)
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
        print("check for update")
    }
    
    @IBAction func aboutClicked(_ sender: Any) {
        aboutWindow.showWindow(nil)
    }
    
    @IBAction func quitClicked(_ sender: Any) {
        NSApplication.shared().terminate(self)
    }
    
    override func awakeFromNib() {
        
        aboutWindow = AboutWindowController()
        
        // Set preferences window
        var controllers = [NSViewController]()
        controllers.append(ServerPreferencesViewController())
        controllers.append(ParserPreferencesViewController())
        preferencesWindowController = MASPreferencesWindowController.init(viewControllers: controllers, title: "Preferences")
        
        let server = Server.sharedInstance
        server.start()
        
        let icon = NSImage(named: "tray-off")
        statusItem.image = icon
        statusItem.menu = statusMenu
        statusMenu.autoenablesItems = false
    }
    
}
