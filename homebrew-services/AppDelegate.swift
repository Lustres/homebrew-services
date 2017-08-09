//
//  AppDelegate.swift
//  homebrew-services
//
//  Created by Lustres on 8/9/17.
//  Copyright © 2017 Lustres. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

  let statusBarItem = NSStatusBar.system.statusItem(withLength: -2)

  let services = Services.sharedInstance
  
  private var notifyToken: Any?
  
  func applicationDidFinishLaunching(_ aNotification: Notification) {
    statusBarItem.menu = NSMenu()
    
    notifyToken = NotificationCenter.default
      .addObserver(forName: NSNotification.Name(rawValue: "NSMenuDidBeginTrackingNotification"),
                   object: nil,
                   queue: nil) {[unowned self] _ in self.fresh()}
    
    fresh()
  }

  deinit {
    NotificationCenter.default.removeObserver(notifyToken!)
  }
}

extension AppDelegate {
  @objc func fresh() {
    
    DispatchQueue.global(qos: .userInteractive).async {
      [unowned self] in
      
      var dict = self.services.list()
      
      DispatchQueue.main.sync {
        [unowned self] in
        let menu = self.statusBarItem.menu!
      
        for item in menu.items {

          if let s = dict[item.title] {
            if state(s) != item.state {
              item.state = state(s)
            }
            dict.removeValue(forKey: item.title)
          } else {
            menu.removeItem(item)
          }
        }
        
        for(serviceName, state) in dict {
          let item = NSMenuItem(title: serviceName,
                                action: #selector(AppDelegate.toggole),
                                keyEquivalent: "String")
          
          if state {
            item.state = .onState
          }

          menu.addItem(item)
        }
      } // main queue
    } // global queue
    
  }

  
  @objc func toggole(_ sender: NSMenuItem!) {
    debugPrint("[toggole]: \(sender.title) - \(sender.state)")
    
    DispatchQueue.global(qos: .userInteractive).async {
      [unowned self] in
      if sender.state == .offState {
        self.services.start(sender.title)
      } else if sender.state == .onState {
        self.services.stop(sender.title)
      }
      self.fresh()
    }
  }
}

fileprivate func state(_ s: Bool) -> NSControl.StateValue {
  return s  ? .onState : .offState
}
