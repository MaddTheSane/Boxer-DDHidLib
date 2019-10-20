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
    @objc let event: DDHidEvent?
    @objc let index: Int
    
    init(usageDescription ud: String, event e: DDHidEvent?, index idx: Int) {
        usageDescription = ud
        event = e
        index = idx
        super.init()
    }
}


class WatchWindowController : NSWindowController, DDHidQueueDelegate, NSWindowDelegate {
    @IBOutlet weak var eventHistoryController: NSArrayController!
    var device: DDHidDevice?
    var queue: DDHidQueue?
    var elements: [DDHidElement] = []
    private var nextIndex = 1
    
    override var windowNibName: NSNib.Name? {
        return NSNib.Name("EventWatcher")
    }
        
    func windowWillClose(_ notification: Notification) {
        queue = nil
        device?.close()
    }
    
    func ddhidQueueHasEvents(_ hidQueue: DDHidQueue) {
        let watcherEvent = WatcherEvent(usageDescription: "-----------------------------", event: nil, index: nextIndex)
        nextIndex += 1
        eventHistoryController.addObject(watcherEvent)
        
        var newEvents = [WatcherEvent]()
        while let event = hidQueue.nextEvent() {
            let element = device?.element(forCookie: event.elementCookie)
            let watcherEvent = WatcherEvent(usageDescription: element?.usage.usageNameWithIds ?? "?", event: event, index: nextIndex)
            nextIndex += 1
            newEvents.append(watcherEvent)
        }
        
        eventHistoryController.add(contentsOf: newEvents)
    }
    
    override func windowDidLoad() {
        device?.open()
        queue = device?.createQueue(withSize: 30)
        queue?.delegate = self
        queue?.add(elements)
        willChangeValue(for: \WatchWindowController.isWatching)
        queue?.startOnCurrentRunLoop()
        didChangeValue(for: \WatchWindowController.isWatching)
    }
    
    // MARK: - eventHistory
    var eventHistory = NSMutableArray()
    @objc func addToEventHistory(_ mEventHistoryObject: Any) {
        eventHistory.add(mEventHistoryObject)
    }
    
    @objc func removeFromEventHistory(_ mEventHistoryObject: Any) {
        eventHistory.remove(mEventHistoryObject)
    }
    
    @objc(watching) var isWatching: Bool {
        @objc(isWatching) get {
            guard let mQueue = queue else {
                return false
            }
            return mQueue.isStarted
        }
        set(watching) {
            let isStarted = queue?.isStarted ?? false
            guard isStarted != watching else {
                return
            }
            
            if watching {
                queue?.startOnCurrentRunLoop()
            } else {
                queue?.stop()
            }
        }
    }

    @IBAction func clearHistory(_ sender: Any?) {
        willChangeValue(for: \WatchWindowController.eventHistory)
        eventHistory.removeAllObjects()
        nextIndex = 1
        didChangeValue(for: \WatchWindowController.eventHistory)
    }
}
