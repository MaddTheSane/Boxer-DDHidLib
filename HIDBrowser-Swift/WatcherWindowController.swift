//
//  WatcherWindowController.swift
//  DDHidLib
//
//  Created by C.W. Betts on 11/21/15.
//
//

import Cocoa
import DDHidLib.DDHidDevice
import DDHidLib.DDHidElement
import DDHidLib.DDHidQueue
import DDHidLib.DDHidEvent
import DDHidLib.DDHidUsage

private final class WatcherEvent {
	let usageDescription: String
	let event: DDHidEvent?
	let index: Int

	init(usageDescription anUsageDecription: String, event anEvent: DDHidEvent?, index: Int) {
		usageDescription = anUsageDecription
		event = anEvent
		self.index = index
	}
}

final class WatcherWindowController : NSWindowController {
	@IBOutlet weak var eventHistoryController: NSArrayController!
	var device: DDHidDevice!
	var elements = [DDHidElement]()
	var queue: DDHidQueue!
	dynamic var eventHistory = [AnyObject]()
	private var nextIndex = 0
	
	
}
