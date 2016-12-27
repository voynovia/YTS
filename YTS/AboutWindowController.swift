//
//  AboutWindowController.swift
//  YTS
//
//  Created by Igor Voynov on 27.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Cocoa
import WebKit

class AboutWindowController: NSWindowController {

    @IBOutlet weak var webView: WebView!
    
    override var windowNibName : String! {
        return "AboutWindowController"
    }
    
    let url = Bundle.main.url(forResource: "about", withExtension: "html")
    
    override func windowDidLoad() {
        super.windowDidLoad()

        let request = URLRequest(url: self.url!)
        self.webView.policyDelegate = self
        self.webView.mainFrame.load(request)
        
        self.window?.center()
        self.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

}

extension AboutWindowController: WebPolicyDelegate {
    func webView(_ webView: WebView!, decidePolicyForNavigationAction actionInformation: [AnyHashable : Any]!, request: URLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
        if let currentURL = request.url {
            if currentURL == self.url {
                listener.use()
            } else {
                listener.ignore()
                NSWorkspace.shared().open(currentURL)
            }
        }
    }
}
