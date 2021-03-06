//===--- RunSPM.swift ----------------------------------------------------------===//
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
//===---------------------------------------------------------------------------===//

import Foundation
import Result

infix operator ++ {}

func ++ <K,V> (left: Dictionary<K,V>, right: Dictionary<K,V>?) -> Dictionary<K,V> {
    guard let right = right else { return left }
    return left.reduce(right) {
        var new = $0 as [K:V]
        new.updateValue($1.1, forKey: $1.0)
        return new
    }
}

struct RunSPMStep : RunSubtaskStep {
    let dependsOn:[Step] = []
    
    func run(params: [String: Any], combinedOutput: StepResponse) throws -> [String: Any] {
        guard let path = params["path"] as? String else {
            throw SwiftExpressError.BadOptions(message: "RunSPM: No path option.")
        }
        guard let buildType = params["buildType"] as? BuildType else {
            throw SwiftExpressError.BadOptions(message: "RunSPM: No buildType option.")
        }
        
        print ("Running app...")
        
        let binaryPath = path.addPathComponent(".build").addPathComponent(buildType.spmValue).addPathComponent("app")
        
        try executeSubtaskAndWait(SubTask(task: binaryPath, arguments: nil, workingDirectory: path, environment: nil, useAppOutput: true))
        
        return [String:Any]()
    }
    
    func cleanup(params: [String : Any], output: StepResponse) throws {
        
    }
    
//    func callParams(ownParams: [String : Any], forStep: Step, previousStepsOutput: StepResponse) throws -> [String : Any] {
//        return ownParams ++ ["force": false, "dispatch": DEFAULTS_BUILD_DISPATCH]
//    }
}