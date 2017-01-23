//
//  AppDelegate.swift
//  Phototrain
//
//  Created by Preston Mueller on 1/3/17.
//  Copyright © 2017 Preston Mueller. All rights reserved.
//

import Cocoa
import FileWatch
import Async

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    @IBOutlet weak var window: NSWindow!
    
    var statusBar = NSStatusBar.system()
    var statusBarItem : NSStatusItem = NSStatusItem()
    var menu: NSMenu = NSMenu()
    let textItem : NSMenuItem = NSMenuItem()
    var fileWatch : FileWatch? = nil
    
    var importerCount : Int = 0
    let importerAsync = Async.background {
        
    }

    func setWindowVisible(sender: AnyObject){
        self.window!.makeKeyAndOrderFront(sender)
    }
    
    func updateTextItem() {
        if self.importerCount > 0 {
            textItem.title = String(format:"Importing %d photos into Photos.app...", self.importerCount)
        }
        else {
            textItem.title = "Waiting for new Camera Uploads photos..."
        }
    }
    
    func incUploadingCount() {
        self.importerCount += 1
        updateTextItem()
    }
    
    
    func decUploadingCount() {
        self.importerCount -= 1
        updateTextItem()
    }
    
    override func awakeFromNib() {

        if detectFirstRun() {
            firstRun()
        }

        
        statusBarItem = statusBar.statusItem(withLength: -1)
        statusBarItem.menu = menu
        statusBarItem.title = "P"
        
        textItem.title = "Waiting for new Camera Uploads photos..."
        textItem.isEnabled = false;
        menu.addItem(textItem)
        
        let menuItem : NSMenuItem = NSMenuItem()
        menuItem.title = "Preferences..."
        menuItem.action = #selector(setWindowVisible(sender:))
        menu.addItem(menuItem)
        
        let quitItem : NSMenuItem = NSMenuItem()
        quitItem.title = "Quit Phototrain"
        quitItem.action = #selector(quit(sender:))
        menu.addItem(quitItem)
        
       let cameraUploadsFolder = NSString(string: "~/Dropbox/Camera Uploads").expandingTildeInPath
        
        fileWatch = try! FileWatch(paths: [cameraUploadsFolder],  createFlag: [.UseCFTypes, .FileEvents], runLoop: RunLoop.current, latency: 3.0, eventHandler: { event in
 
            if event.flag.contains(.ItemIsFile) {
                if NSString(string: event.path).lastPathComponent != ".DS_Store" {
                    
                    self.importerAsync.main() {
                        self.incUploadingCount()
                    }.background() {
                        self.attemptImport(path: event.path)
                    }
                    .main() {
                        self.decUploadingCount()
                    }
                }
            }
        })
        
    }
    
    func attemptImport(path: String) {
      
        let fileManager = FileManager.default
        var isDir : ObjCBool = false
        if fileManager.fileExists(atPath: path, isDirectory:&isDir) {
            if isDir.boolValue {
                //Don't keep going
                return
            } else {
                //Keep going
            }
        } else {
            //Don't keep going
            return
        }
        
        let filename = NSString(string: path).lastPathComponent
        print("Handling " + filename)
        if filename.contains("PT-") {
            print("Contained PT-, returning")
            return
        }

        let myAppleScript = "tell application \"Photos\"\n" +
            "return import POSIX file \"" + path + "\"\n" +
            "end tell"

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: myAppleScript) {
            if let _: NSAppleEventDescriptor = scriptObject.executeAndReturnError(
                &error) {
                let newPath = NSString(string: NSString(string: path).deletingLastPathComponent).appendingPathComponent("PT-IMPORTED-" + filename)
                do {
                    try fileManager.moveItem(atPath: path, toPath: newPath)
                    print("Imported.")
                }
                catch {
                    print("Imported, but failed to rename with PT-IMPORTED.")
                }
                
                if UserDefaults.standard.bool(forKey: "deleteWhenImported") {
                    do {
                        try fileManager.trashItem(at: URL(string: newPath)!, resultingItemURL: nil)
                        print("Trashed.")
                    }
                    catch {
                        print("Failed to trash " + newPath)
                    }
                }
            } else if (error != nil) {
                let newPath = NSString(string: NSString(string: path).deletingLastPathComponent).appendingPathComponent("PT-ERROR-" + filename)
                
                do {
                    try fileManager.moveItem(atPath: path, toPath: newPath)
                    print("Error.")
                }
                catch {
                    print("Error, but failed to rename with PT-ERROR.")
                }
            }
        }

    }
    
    func detectFirstRun() -> Bool {
        return !UserDefaults.standard.bool(forKey: "firstRunDone")
    }
    
    func firstRun() {
        UserDefaults.standard.set(false, forKey: "deleteWhenImported")
        UserDefaults.standard.set(true, forKey: "firstRunDone")
        UserDefaults.standard.synchronize()
    }
    
    func photosIsRunning() -> Bool {
        if NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Photos").count > 0 {
            return false
        }
        else {
            return true
        }
    }
    
    func quit(sender : NSMenuItem) {
        NSApp.terminate(self)
    }

}

