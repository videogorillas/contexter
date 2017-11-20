//
//  FileUtils.swift
//  contexter
//
//  Created by Aleksey Sevruk on 11/19/17.
//  Copyright © 2017 Aleksey Sevruk. All rights reserved.
//

import Foundation
import CoreML

class FileUtils {
    
    static func saveMLArrayToFile(_ arr: MLMultiArray, _ filename: String) -> Bool {
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(filename)
        print("\(fileURL.absoluteString)")
        
        var resultString = ""
        do {
            try resultString.write(to: fileURL, atomically: true, encoding: String.Encoding.ascii)
        } catch {
            print("Error writing to file \(error)")
            return false
        }
        
        for i in 0 ..< arr.count {
            let val = String(arr[i].doubleValue)
            resultString = resultString + " " + val
            
            if (i % 20000 == 0) {
                print(val)
                appendToFile(value: resultString, file: fileURL)
                resultString = ""
            }
        }
        appendToFile(value: resultString, file: fileURL)
        return true
    }
    
    static func appendToFile(value: String, file: URL) -> Bool {
        do {
            let fileHandle = try FileHandle(forWritingTo: file)
            fileHandle.seekToEndOfFile()
            fileHandle.write(value.data(using: .ascii)!)
            fileHandle.closeFile()
        } catch {
            print("Error writing to file \(error)")
            return false
        }
        return true
    }
}
