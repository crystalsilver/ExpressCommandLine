//===--- SubTask.swift ----------------------------------------------------===//
//Copyright (c) 2015-2016 Daniel Leping (dileping)
//
//This file is part of Swift Express Command Line
//
//Swift Express Command Line is free software: you can redistribute it and/or modify
//it under the terms of the GNU General Public License as published by
//the Free Software Foundation, either version 3 of the License, or
//(at your option) any later version.
//
//Swift Express Command Line is distributed in the hope that it will be useful,
//but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//GNU General Public License for more details.
//
//You should have received a copy of the GNU General Public License
//along with Swift Express Command Line. If not, see <http://www.gnu.org/licenses/>.
//
//===----------------------------------------------------------------------===//

import Foundation
import SwiftTryCatch

extension dispatch_data_t {
    func toArray() -> [UInt8] {
        var bytes: UnsafePointer<Void> = nil
        var bytesLength:Int = 0
        guard dispatch_data_create_map(self, &bytes, &bytesLength) != nil else {
            return [UInt8]()
        }
        return Array<UInt8>(UnsafeMutableBufferPointer<UInt8>(start: UnsafeMutablePointer<UInt8>(bytes), count: bytesLength))
    }
}

class SubTask {
    private let task: String
    private let arguments: [String]
    private let useAppOutput: Bool
    private let finishCb: ((SubTask, Int32) -> ())?
    private var env:[String:String]?
    private let workingDirectory: String?
    
    private let nTask : NSTask
    
    init(task: String, arguments: [String]? = nil, workingDirectory: String? = nil, environment:[String:String]? = nil, useAppOutput: Bool = false, finishCallback: ((task:SubTask, status:Int32) -> ())? = nil) {
        self.task = task
        if arguments != nil {
            self.arguments = arguments!
        } else {
            self.arguments = [String]()
        }
        self.useAppOutput = useAppOutput
        self.finishCb = finishCallback
       
        self.env = environment
        self.workingDirectory = workingDirectory
        
        nTask = NSTask()
    }
    
    func run() throws {
        nTask.launchPath = task
        nTask.arguments = arguments
        if env != nil {
            nTask.environment = env
        }
        if workingDirectory != nil {
            nTask.currentDirectoryPath = workingDirectory!
        }
        
        nTask.standardInput = NSPipe()
        
        
        nTask.terminationHandler = { (fTask : NSTask) -> Void in
            if self.finishCb != nil {
                self.finishCb!(self, fTask.terminationStatus)
            }
        }
        
        if useAppOutput {
            nTask.standardOutput = NSFileHandle.fileHandleWithStandardOutput()
            nTask.standardError = NSFileHandle.fileHandleWithStandardError()
        } else {
            nTask.standardOutput = NSPipe()
            nTask.standardError = NSPipe()
        }
        
        
        var exception:NSException? = nil
        
        SwiftTryCatch.tryBlock({ () -> Void in
            self.nTask.launch()
        }, catchBlock: { (exc) -> Void in
            exception = exc
        }, finallyBlock: {})
        if exception != nil {
            throw SwiftExpressError.SubtaskError(message: "Task launch error: \(exception!)")
        }
    }
    
    func runAndWait() throws -> Int32 {
        try run()
        nTask.waitUntilExit()
        return nTask.terminationStatus
    }
    
    func writeData(data: [UInt8]) {
        (nTask.standardInput! as! NSPipe).fileHandleForWriting.writeData(data.toData())
    }
    
    func readData() -> [UInt8] {
        if !useAppOutput {
            return (nTask.standardOutput! as! NSPipe).fileHandleForReading.readDataToEndOfFile().toArray()
        }
        return []
    }
    
    func readErrorData() -> [UInt8] {
        if !useAppOutput {
            return (nTask.standardError! as! NSPipe).fileHandleForReading.readDataToEndOfFile().toArray()
        }
        return []
    }
    
    func terminate() {
        nTask.terminate()
    }
    
    func interrupt() {
        nTask.interrupt()
    }
}


