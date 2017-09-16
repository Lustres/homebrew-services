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
    
    statusBarItem.button?.image = #imageLiteral(resourceName: "StatusBarButtonIcon")
      
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
                                keyEquivalent: "")
          
          if state {
            item.state = .on
          }

          menu.addItem(item)
        }
      } // main queue
    } // global queue
    
  }

  
  @objc func toggole(_ sender: NSMenuItem!) {
    debugPrint("[toggole]: \(sender.title) - \(sender.state)")
    sender.action = nil
    DispatchQueue.global(qos: .userInteractive).async {
      [unowned self] in
      
      var actionName = ""
      var r = false
      
      switch sender.state {
      case .off:
        actionName = "Start"
        r = self.services.start(sender.title)
        
      case .on:
        actionName = "Stop"
        r = self.services.stop(sender.title)
        
      default:
        break
      }
      
      
      let post = (r ? succPost : failPost)(actionName, sender.title)
      
      DispatchQueue.main.async {
        NSUserNotificationCenter.default.deliver(post)
      }
      
      self.fresh()
      
      DispatchQueue.main.sync {
        sender.action = #selector(AppDelegate.toggole)
      }
    }
  }
}

fileprivate func succPost(action: String, name: String) -> NSUserNotification {
  let post = NSUserNotification()
  post.title = "\(action) \(name) Succeeded"
  return post;
}

fileprivate func failPost(action: String, name: String) -> NSUserNotification {
  let post = NSUserNotification()
  post.title = "\(action) \(name) Failed"
  post.soundName = "Funk"
  return post;
}

fileprivate func state(_ s: Bool) -> NSControl.StateValue {
  return s  ? .on : .off
}
