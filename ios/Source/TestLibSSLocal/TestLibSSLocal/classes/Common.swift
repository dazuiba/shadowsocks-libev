//
//  Utils.swift
//  TestLibSSLocal
//
//  Created by Zhanggy on 21.09.24.
//

import UIKit
 

func fileInDocument(_ name:String,createIfNotExsit:Bool = false) -> String {
    let fs = FileManager.default
    var logPath = fs.urls(for: .documentDirectory, in: .userDomainMask).first!
    logPath.append(component: name)
    let path = logPath.path()
    if createIfNotExsit && !fs.fileExists(atPath: path) {
        fs.createFile(atPath: path, contents: nil)
    }
    return path
}

enum SSLocalError : Error {
    case configNotSet
    case common(String)
}

func printObjectAsJSON(obj:Codable,format:Bool = false) -> String {
    do {
        let encoder = JSONEncoder()
        if format {
            encoder.outputFormatting = .prettyPrinted
        }
        let jsonData = try encoder.encode(obj)
        return String(data: jsonData, encoding: .utf8) ?? "invalid_json"
    } catch {
        return "Failed to encode config: \(error)"
    }
}
//func logTry<T>(_ block:(() throws ->T)) -> T {
//    return  try! block()
//}
func logTry<T>(_ block:(() throws ->T)) -> T? {
    do {
        return try block()
    } catch {
        SSLogger.info("error:\(error)")
        return nil
    }
}
