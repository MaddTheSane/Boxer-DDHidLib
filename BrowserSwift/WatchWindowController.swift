//
//  WatchWindowController.swift
//  BrowserSwift
//
//  Created by C.W. Betts on 10/20/19.
//

import Cocoa
import DDHidLib.DDHidDevice
import DDHidLib.DDHidElement


class WatchWindowController : NSWindowController {
    @IBOutlet weak var eventHistoryController: NSArrayController!

    
    @IBAction func clearHistory(_ sender: Any?) {
        
    }
    
    var device: DDHidDevice?

    var elements: [Any] = []

    var eventHistory: NSMutableArray? = NSMutableArray() 

}
