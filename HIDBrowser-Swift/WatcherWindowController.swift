//
//  WatcherWindowController.swift
//  DDHidLib
//
//  Created by C.W. Betts on 11/21/15.
//
//

import Cocoa
import DDHidLib

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

}
