//
//  NSAlert+Extensions.swift
//  YTS
//
//  Created by Igor Voynov on 30.12.16.
//  Copyright © 2016 Igor Voynov. All rights reserved.
//

import Cocoa

extension NSAlert {
    
    static func showAlert(title: String?, message: String?, style: NSAlertStyle = .informational) {
        let alert = NSAlert()
        if let title = title {
            alert.messageText = title
        }
        if let message = message {
            alert.informativeText = message
        }
        alert.alertStyle = style
        alert.runModal()
    }
    
}
