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
    
    let settings = UserDefaults.standard
    
    let parser = Parser()
    let server = Server.sharedInstance
    
    @IBOutlet weak var statusMenu: NSMenu!
    @IBOutlet weak var informationView: InformationView!
    
    var informationViewItem: NSMenuItem!
    var aboutWindow: AboutWindowController!
    var preferencesWindowController: MASPreferencesWindowController!
    
    let statusItem = NSStatusBar.system().statusItem(withLength: NSVariableStatusItemLength)
    
    @IBAction func preferencesClicked(_ sender: Any) {
        self.preferencesWindowController.showWindow(nil)
    }
    
    @IBOutlet weak var startServer: NSMenuItem!
    @IBAction func startServerClicked(_ sender: Any) {
        self.server.start()
    }
    
    @IBOutlet weak var stopServer: NSMenuItem!
    @IBAction func stopServerClicked(_ sender: Any) {
        self.server.stop()
    }
    
    @IBOutlet weak var updateLibraries: NSMenuItem!
    @IBAction func updateLibrariesClicked(_ sender: Any) {
        parser.startParsing()
    }
    
    @IBOutlet weak var cancelLibrariesUpdate: NSMenuItem!
    @IBAction func cancelLibrariesUpdateClicked(_ sender: Any) {
        parser.stopParsing()
    }
    
    @IBOutlet weak var cleanLibraries: NSMenuItem!
    @IBAction func cleanLibrariesClicked(_ sender: Any) {
        parser.cleanBase()
    }
    
    @IBAction func checkForUpdatesClicked(_ sender: Any) {
        print("check for update")
    }
    
    @IBAction func aboutClicked(_ sender: Any) {
        aboutWindow.showWindow(nil)
    }
    
    @IBAction func quitClicked(_ sender: Any) {
        let alert = NSAlert()
        alert.messageText = "Are you sure you want to quit?"
        alert.informativeText = "If you quit the YTS Server, none of your YTS clients will be able to access your movie database. Are you sure you want to continue?"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Quit")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == NSAlertFirstButtonReturn {
            NSApplication.shared().terminate(self)
        }
    }
    
    override func awakeFromNib() {
        server.delegate = self
        parser.delegate = self
        
        aboutWindow = AboutWindowController()
        
        // Set preferences window
        var controllers = [NSViewController]()
        controllers.append(ServerPreferencesViewController())
        controllers.append(ParserPreferencesViewController())
        preferencesWindowController = MASPreferencesWindowController.init(viewControllers: controllers, title: "Preferences")
        
        informationViewItem = statusMenu.item(withTitle: "Information")
        informationViewItem.view = informationView
        
        let icon = NSImage(named: "tray-off")
        statusItem.image = icon
        statusItem.menu = statusMenu
        statusMenu.autoenablesItems = false
        
        updateInformation()
        
        if settings.bool(forKey: "serverAutostart") == true {
            self.server.start()
        }
        if settings.bool(forKey: "parserAutostart") == true {
            self.parser.startParsing()
        }
        
    }
    
    fileprivate func updateInformation() {
        let database = DataBase()
        self.informationView.update(moviesCount: database.getObjects(type: Movie.self).count, showsCount: 0)
    }
    
}

extension StatusMenuController: ParserDelegate {

    func updateCount() {
        self.updateInformation()
    }
    
    func parserStateDidUpdate(running: Bool) {
        updateLibraries.isEnabled = !running
        cancelLibrariesUpdate.isEnabled = running
        cleanLibraries.isEnabled = !running
    }
    
    func parserFailure(error: Error) {
        parser.stopParsing()
        NSAlert.showAlert(title: "Warning", message: error.localizedDescription, style: .critical)
    }
}

extension StatusMenuController: ServerDelegate {
    
    func serverStateDidUpdate(running: Bool) {
        startServer.isEnabled = !running
        stopServer.isEnabled = running
        if running {
            statusItem.image = NSImage(named: "tray-on")
        } else {
            statusItem.image = NSImage(named: "tray-off")
        }
    }
    
    func serverFailure(error: ServerError) {
        server.stop()
        NSAlert.showAlert(title: "Warning", message: error.localizedDescription, style: .critical)
    }
}
