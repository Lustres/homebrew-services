//
//  Service.swift
//  homebrew-services
//
//  Created by Lustres on 8/9/17.
//  Copyright © 2017 Lustres. All rights reserved.
//

import Foundation

class Services {
  
  static let sharedInstance = Services()
  
  let brew_path = "/usr/local/bin/brew"
  
  let start_cmd = ["/usr/local/bin/brew", "services", "start"]
  
  let stop_cmd = ["/usr/local/bin/brew", "services", "stop"]
  
  let list_cmd = ["/usr/local/bin/brew", "services", "list"]
  
  func start(_ name: String) -> Bool {
    return (start_cmd + [name]).run() != nil
  }
  
  func stop(_ name: String) -> Bool {
    return (stop_cmd + [name]).run() != nil
  }
  
  func list() -> [String: Bool] {
    var services = [String: Bool]()
    
    guard let table = list_cmd.run()?.splitAfterTrim(splitBy: .newlines) else {
      return services
    }
    
    for i in 1..<table.count {
      let tuple = table[i].components(separatedBy: .whitespaces)
      services[tuple[0]] = tuple[1] == "started"
    }
    
    debugPrint("[list]: \(services)")
    
    return services;
  }
}

fileprivate extension String {
  func splitAfterTrim(splitBy: CharacterSet) -> [String] {
   return self.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: splitBy)
  }
}

fileprivate extension Array where Element == String {
  func run() -> String? {
    
    let task = Process()
    
    let outPipe = Pipe()
    let errPipe = Pipe()
    
    task.standardOutput = outPipe
    task.standardError = errPipe
    
    task.launchPath = "/bin/bash"
    task.arguments = self
    
    let outFileHandler = outPipe.fileHandleForReading
    let errFileHandler = errPipe.fileHandleForReading
    
    task.launch()
    task.waitUntilExit()
    
    let outData = outFileHandler.readDataToEndOfFile()
    let output = NSString(data: outData, encoding: String.Encoding.utf8.rawValue)!
    
    let errData = errFileHandler.readDataToEndOfFile()
    let errput = NSString(data: errData, encoding: String.Encoding.utf8.rawValue)!
    
    debugPrint("[shell]: \(output)")
    if errput != "" {
      debugPrint("[error]: \(errput)")
    }
    
    return task.terminationStatus == 0 ? output as String: nil
  }
}
