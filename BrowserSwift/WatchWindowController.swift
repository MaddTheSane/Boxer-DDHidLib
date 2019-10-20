//
//  WatchWindowController.swift
//  BrowserSwift
//
//  Created by C.W. Betts on 10/20/19.
//

import Cocoa
import DDHidLib.DDHidDevice
import DDHidLib.DDHidElement
import DDHidLib.DDHidQueue
import DDHidLib.DDHidEvent
import DDHidLib.DDHidUsage

@objc private class WatcherEvent : NSObject {
    @objc let usageDescription: String
    @objc let event: DDHidEvent
    @objc let index: Int32
    
    init(usageDescription ud: String, event e: DDHidEvent, index idx: Int32) {
        usageDescription = ud
        event = e
        index = idx
        super.init()
    }
}


class WatchWindowController : NSWindowController {
    @IBOutlet weak var eventHistoryController: NSArrayController!

    
    @IBAction func clearHistory(_ sender: Any?) {
        
    }
    
    var device: DDHidDevice?

    var elements: [Any] = []

    var eventHistory: NSMutableArray? = NSMutableArray() 

    /* - (void) addToEventHistory: (id)mEventHistoryObject;
    - (void) removeFromEventHistory: (id)mEventHistoryObject;

    @property (getter=isWatching) BOOL watching;

    - (IBAction) clearHistory: (id) sender;
*/
}
