//
//  AppDelegate.swift
//  Lenovo BIOS USB Creator
//
//  Created by Prof. Dr. Luigi on 11.03.20.
//  Copyright © 2020 Sascha Lamprecht. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    
    let scriptPath = Bundle.main.path(forResource: "/Script/script", ofType: "command")!
    
    func applicationShouldTerminateAfterLastWindowClosed (_
        theApplication: NSApplication) -> Bool {
        self.syncShellExec(path: self.scriptPath, args: ["_quit_app"])
        let destination = UserDefaults.standard.string(forKey: "Destination")
        if destination != nil{
            UserDefaults.standard.removeObject(forKey: "Destination")
        }
        let cellar = UserDefaults.standard.string(forKey: "Cellar")
        if cellar != nil{
            UserDefaults.standard.removeObject(forKey: "Cellar")
        }
        let perl = UserDefaults.standard.string(forKey: "Perl")
        if perl != nil{
            UserDefaults.standard.removeObject(forKey: "Perl")
        }
        return true
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func syncShellExec(path: String, args: [String] = []) {
        let process            = Process()
        process.launchPath     = "/bin/bash"
        process.arguments      = [path] + args
        let outputPipe         = Pipe()
        let filelHandler       = outputPipe.fileHandleForReading
        process.standardOutput = outputPipe
        process.launch()
        process.waitUntilExit()
        filelHandler.readabilityHandler = nil
    }
    
}

