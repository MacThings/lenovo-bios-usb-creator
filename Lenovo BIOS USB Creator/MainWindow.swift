//
//  mainwindow.swift
//  Lenovo BIOS USB Creator
//
//  Created by Prof. Dr. Luigi on 11.03.20.
//  Copyright © 2020 Sascha Lamprecht. All rights reserved.
//

import Cocoa
import LetsMove

class MainWindow: NSViewController {

    @IBOutlet var output_window: NSTextView!
    @IBOutlet weak var content_scroller: NSScrollView!
    @IBOutlet weak var pulldown_menu: NSPopUpButton!
    
    var process:Process!
    var out:FileHandle?
    var outputTimer: Timer?
    
    let scriptPath = Bundle.main.path(forResource: "/Script/script", ofType: "command")!
    let appversion : Any! = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
                
        let destination = UserDefaults.standard.string(forKey: "Destination")
        if destination != nil{
            UserDefaults.standard.removeObject(forKey: "Destination")
        }
        
        self.syncShellExec(path: self.scriptPath, args: ["_initial"])
        
        let fontsizeinit = UserDefaults.standard.string(forKey: "Font Size")
        if fontsizeinit == nil{
            UserDefaults.standard.set("14", forKey: "Font Size")
        }
        
        let fontinit = UserDefaults.standard.string(forKey: "Font Family")
        if fontinit == nil{
            UserDefaults.standard.set("Courier", forKey: "Font Family")
        }
        
        let fontpt = CGFloat(UserDefaults.standard.float(forKey: "Font Size"))
        let fontfam = UserDefaults.standard.string(forKey: "Font Family")
        
        output_window.font = NSFont(name: fontfam!, size: fontpt)
        DispatchQueue.global(qos: .background).async {
        self.syncShellExec(path: self.scriptPath, args: ["_get_drives"])
                    
        DispatchQueue.main.async {
        let filePath = "/private/tmp/lenovobios/drives_pulldown"
        if (FileManager.default.fileExists(atPath: filePath)) {
            print("")
        } else{
            return
        }

        let location = NSString(string:"/private/tmp/lenovobios/drives_pulldown").expandingTildeInPath
        let fileContent = try? NSString(contentsOfFile: location, encoding: String.Encoding.utf8.rawValue)
        for (_, drive) in (fileContent?.components(separatedBy: "\n").enumerated())! {
            self.pulldown_menu.menu?.addItem(withTitle: drive, action: #selector(MainWindow.menuItemClicked(_:)), keyEquivalent: "")
        }


            
        }
    }
        
     }
        
    
    
    @IBAction func browseFile(sender: AnyObject) {
        
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose a Folder";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseDirectories    = true;
        dialog.canCreateDirectories    = true;
        dialog.allowsMultipleSelection = false;
        dialog.allowedFileTypes        = ["iso"];
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
            
            if (result != nil) {
                let path = result!.path
                let isopath = (path as String)
                UserDefaults.standard.set(isopath, forKey: "Isopath")
                self.syncShellExec(path: self.scriptPath, args: ["_get_isoname"])
            }
        } else {
            return
        }
  
    }
    
    @IBAction func refresh_drives(_ sender: Any) {
        output_window.textStorage?.mutableString.setString("")
        self.syncShellExec(path: self.scriptPath, args: ["_refresh"])
    }
    
    
    @objc func menuItemClicked(_ sender: NSMenuItem) {
        self.pulldown_menu.item(withTitle: "Please select ...")?.isHidden=true
        let destination = sender.title
        UserDefaults.standard.set(destination, forKey: "Destination")
    }

    @IBAction func start(_ sender: Any) {
        output_window.textStorage?.mutableString.setString("")
        DispatchQueue.global(qos: .background).async {
        self.syncShellExec(path: self.scriptPath, args: ["_write_device"])
        }
    }
    
    
     func syncShellExec(path: String, args: [String] = []) {
        let process            = Process()
        process.launchPath     = "/bin/bash"
        process.arguments      = [path] + args
        let outputPipe         = Pipe()
        let filelHandler       = outputPipe.fileHandleForReading
        process.standardOutput = outputPipe
        process.launch()
        
        filelHandler.readabilityHandler = { pipe in
            let data = pipe.availableData
            if let line = String(data: data, encoding: .utf8) {
                DispatchQueue.main.sync {
                    self.output_window.string += line
                }
            } else {
                print("Error decoding data: \(data.base64EncodedString())")
            }
        }
        process.waitUntilExit()
        filelHandler.readabilityHandler = nil
    }
    
}
