//
//  AppDelegate.swift
//  BrowserSwift
//
//  Created by C.W. Betts on 10/20/19.
//

import Cocoa
import DDHidLib.DDHidDevice

private var sSleepAtExit = false

private func exit_sleeper() {
    while sSleepAtExit {
        sleep(60)
    }
}


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

	@IBOutlet weak var window: NSWindow!
    @IBOutlet weak var devicesController: NSArrayController!
    @IBOutlet weak var elementsController: NSTreeController!

    override func awakeFromNib() {
        sSleepAtExit = UserDefaults.standard.bool(forKey: "SleepAtExit")
        atexit(exit_sleeper)
        
        willChangeValue(for: \AppDelegate.devices)
        devices = DDHidDevice.allDevices() ?? []
        didChangeValue(for: \AppDelegate.devices)
        
        window.center()
        window.makeKeyAndOrderFront(self)
    }
    
    func selectedDevice() -> DDHidDevice? {
        guard let selectedDevices = devicesController.selectedObjects, selectedDevices.count > 0 else {
            return nil
        }
        return selectedDevices.first as? DDHidDevice
    }


    @objc private(set) var devices: [DDHidDevice] = []

    @IBAction func watchSelected(_ sender: Any?) {
        let selectedElements = elementsController.selectedObjects
        if selectedElements.count == 0 {
            return;
        }

        let controller = WatchWindowController()
        controller.device = selectedDevice()
        controller.elements = selectedElements as! [DDHidElement]
        controller.showWindow(self)
    }

    @IBAction func exportPlist(_ sender: Any?) {
        guard let selectedDevice = selectedDevice() else {
            return
        }
        
        let panel = NSSavePanel()
        
        panel.allowedFileTypes = ["plist"]
        panel.allowsOtherFileTypes = false
        panel.canSelectHiddenExtension = true
        
        panel.beginSheet(NSApp.mainWindow!) { (response) in
            /* if successful, save file under designated name */
            guard response == .OK else {
                return;
            }
            
            let deviceProperties = selectedDevice.properties
            
            if (!(deviceProperties as NSDictionary).write(to: panel.url!, atomically: true)) {
                NSSound.beep();
            }

        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        willChangeValue(forKey: "devices")
        devices.removeAll(keepingCapacity: false)
        didChangeValue(forKey: "devices")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

