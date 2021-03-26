//
//  AppDelegate.swift
//  HermezTesterMac2
//
//  Created by Nicholas Gustilo on 3/25/21.
//

import Cocoa
import SwiftUI
import Hermez_Mac

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        let contentView = ContentView()

        // Create the window and set the content view.
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.center()
        window.setFrameAutosaveName("Main Window")
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        Hermez.shared.stopService()
    }

    func applicationDidBecomeActive(_ notification: Notification) {        
        if let deviceName = UserDefaults.standard.object(forKey: "device_name") as? String, Hermez.shared.setServiceAndDeviceName(serviceName: "blah", deviceName: deviceName, deviceJson: nil) {
            
            let deadlineTime = DispatchTime.now() + .seconds(2)
            DispatchQueue.main.asyncAfter(deadline: deadlineTime) {
                print("Hermez.shared.findAvailableDevices()")
                Hermez.shared.findAvailableDevices()
            }
        }
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        Hermez.shared.stopService()
    }
}

