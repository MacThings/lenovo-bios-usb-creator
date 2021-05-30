//
//  mainwindow.swift
//  Lenovo BIOS USB Creator
//
//  Created by Prof. Dr. Luigi on 11.03.20.
//  Copyright © 2020 Sascha Lamprecht. All rights reserved.
//

import Cocoa
//import LetsMove

class MainWindow: NSViewController {
    
    @IBOutlet weak var textfield_isopath: NSTextField!
    @IBOutlet weak var pulldown_drives: NSPopUpButton!
    @IBOutlet weak var button_select: NSButton!
    @IBOutlet weak var button_refresh: NSButton!
    
    @IBOutlet var output_window: NSTextView!
    @IBOutlet weak var content_scroller: NSScrollView!
    @IBOutlet weak var pulldown_menu: NSPopUpButton!
    @IBOutlet weak var button_start: NSButton!
    @IBOutlet weak var button_stop: NSButton!
    @IBOutlet weak var progress_wheel: NSProgressIndicator!
    
    var process:Process!
    var out:FileHandle?
    var outputTimer: Timer?
    
    let scriptPath = Bundle.main.path(forResource: "/Script/script", ofType: "command")!
    let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.view.window?.title = "Lenovo BIOS USB Creator v" + appVersion!

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        //PFMoveToApplicationsFolderIfNecessary()
      
        
        let fontsize = CGFloat(13)
        let fontfamily = "Menlo"
        output_window.font = NSFont(name: fontfamily, size: fontsize)
        
        self.syncShellExec(path: self.scriptPath, args: ["_initial"])
        
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
            self.pulldown_menu.removeItem(withTitle: "")
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
        self.pulldown_menu.removeAllItems()
        output_window.textStorage?.mutableString.setString("")
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
        self.syncShellExec(path: self.scriptPath, args: ["_refresh"])
    }
        
    @objc func menuItemClicked(_ sender: NSMenuItem) {
        let destination = sender.title
        UserDefaults.standard.set(destination, forKey: "Destination")
    }

    @IBAction func start(_ sender: Any) {
        self.progress_wheel?.startAnimation(self);
        self.progress_wheel.isHidden = false
        self.button_start.isHidden = false
        self.button_start.isEnabled = false
        self.textfield_isopath.isEnabled = false
        self.pulldown_menu.isEnabled = false
        self.button_select.isEnabled = false
        self.button_refresh.isEnabled = false
        output_window.textStorage?.mutableString.setString("")
        DispatchQueue.global(qos: .background).async {
            self.syncShellExec(path: self.scriptPath, args: ["_write_device"])
            DispatchQueue.main.async {
                //self.button_start.isHidden = false
                self.button_start.isEnabled = true
                self.textfield_isopath.isEnabled = true
                self.pulldown_menu.isEnabled = true
                self.button_select.isEnabled = true
                self.button_refresh.isEnabled = true
                self.progress_wheel?.stopAnimation(self);
                self.progress_wheel.isHidden = true
            }
        }
    }
    
    @IBAction func stop(_ sender: Any) {
        print("bla")
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
