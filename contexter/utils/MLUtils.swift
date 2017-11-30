//
//  MLUtils.swift
//  contexter
//
//  Created by Aleksey Sevruk on 11/19/17.
//  Copyright © 2017 Aleksey Sevruk. All rights reserved.
//

import Foundation
import CoreML
import UIKit

class MLUtils {
    
    static func getFirstMaxLabel(arr: MLMultiArray, dict: [Int: String]) -> Int {
        let shape  = arr.shape
        
        var max = 0.0
        var r_idx = 0
        for idx in 0 ..< dict.count {
            let val = arr[idx].doubleValue
            if (val > max) {
                max = val
                r_idx = idx
//                print("now \(r_idx) \(max) \(dict[r_idx])")
            }
        }
        return r_idx
    }
    
    static func getFirstNLabels(arr: MLMultiArray, dict: [Int: String], classes: Int) -> [(String, Double)] {
        var result: [(String, Double)] = []
        
        for n in 0 ..< classes {
            var max = getFirstMaxLabel(arr: arr, dict: dict)
            result.append((dict[max]!, arr[max].doubleValue))
            arr[max] = 0
        }
        return result
    }
    
    static func rgbaImageToPlusMinusOneRGBArray(image: UIImage) -> MLMultiArray {
        let pixels = ImageUtils.pixelData(image)?.map({ Double($0) / 127.5 - 1 })
        
        let array = try? MLMultiArray(shape: [3, image.size.height as NSNumber, image.size.width as NSNumber], dataType: .float32)
        
        
        let r = pixels!.enumerated().filter { $0.offset % 4 == 0 }.map { $0.element }
        let g = pixels!.enumerated().filter { $0.offset % 4 == 1 }.map { $0.element }
        let b = pixels!.enumerated().filter { $0.offset % 4 == 2 }.map { $0.element }

        for idx in 0..<Int(image.size.height * image.size.width) {
            // r g b r g b r g b
            // 0 1 2 3 4 5 6 7 8
            let rid = idx * 3
            let gid = rid + 1
            let bid = rid + 2

            array![rid] = r[idx] as NSNumber
            array![gid] = g[idx] as NSNumber
            array![bid] = b[idx] as NSNumber
        }
        return array!
    }
    
}


