//
//  Service.swift
//  homebrew-services
//
//  Created by Lustres on 8/9/17.
//  Copyright © 2017 Lustres. All rights reserved.
//

import Foundation
fileprivate extension Array where Element == String {
  @discardableResult
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
