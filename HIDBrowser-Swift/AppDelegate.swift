//
//  AppDelegate.swift
//  HIDBrowser-Swift
//
//  Created by C.W. Betts on 11/21/15.
//
//

import Cocoa
import DDHidLib.DDHidUsageTables
import DDHidLib.DDHidDevice
import DDHidLib.DDHidElement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!
    @IBOutlet weak var mDevicesController: NSArrayController!
    @IBOutlet weak var mElementsController: NSTreeController!

	private(set) var devices: [DDHidDevice]!

	func applicationDidFinishLaunching(aNotification: NSNotification) {
		// Insert code here to initialize your application
		devices = DDHidDevice.allDevices()
	}

	func applicationWillTerminate(aNotification: NSNotification) {
		// Insert code here to tear down your application
	}

    @IBAction func watchSelected(sender: AnyObject!) {
        
    }
    
    @IBAction func exportPlist(sender: AnyObject!) {
        
    }

}

