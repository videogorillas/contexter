//
//  ImageUtils.swift
//  contexter
//
//  Created by Aleksey Sevruk on 11/18/17.
//  Copyright © 2017 Aleksey Sevruk. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import CoreML

class ImageUtils {

    static func getPixelBuffer(from image: UIImage) -> CVPixelBuffer? {
        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
        var pixelBuffer : CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(image.size.width), Int(image.size.height), kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
        guard (status == kCVReturnSuccess) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pixelData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
        
        context?.translateBy(x: 0, y: image.size.height)
        context?.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context!)
        image.draw(in: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
        
        return pixelBuffer
    }

    static func resizeImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    static func rgbaImageToPlusMinusOneBGRArray(pixelBuffer: CVPixelBuffer, size: CGSize) -> MLMultiArray {
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        guard var res = try? MLMultiArray.init(shape: [3, size.height as NSNumber, size.width as NSNumber], dataType: MLMultiArrayDataType.float32) else {
            fatalError()
        }
        
        let int32Buffer = unsafeBitCast(CVPixelBufferGetBaseAddress(pixelBuffer), to: UnsafeMutablePointer<UInt32>.self)
        let int32PerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        let blueChannel = 0 as NSNumber
        let greenChannel = 1 as NSNumber
        let redChannel = 2 as NSNumber
        
        for y in 0 ..< Int(size.height) {
            for x in 0 ..< Int(size.width) {
                // RGBA
                let data = int32Buffer[y * Int(size.height) + x]
                let redComponent = (data & 0xFF000000) >> 24
                let greenComponent = (data & 0x00FF0000) >> 16
                let blueComponent = (data & 0x0000FF00) >> 8
                
                let normalizedRed = normalizedPlusMinusOne(redChannel)
                let normalizedGreen = normalizedPlusMinusOne(greenChannel)
                let normalizedBlue = normalizedPlusMinusOne(blueChannel)
                
                let yy = y as NSNumber
                let xx = x as NSNumber
                
                res[[blueChannel, yy, xx]] = normalizedBlue as NSNumber
                res[[greenChannel, yy, xx]] = normalizedGreen as NSNumber
                res[[redChannel, yy, xx]] = normalizedRed as NSNumber
            }
        }
        
        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        return res
    }
    
    static func normalizedPlusMinusOne(_ value :NSNumber) -> Float32 {
        return Float32(value) / 127.5 - 1
    }
    
    static func normalizedResNetInput(_ value: Int, _ channel: Int) -> Float32 {
        // channel: 0 - red, 1 - green, 2 - blue
        switch channel {
        case 0:
            return Float32(value) - 123.68
        case 1:
            return Float32(value) - 116.779
        case 2:
            return Float32(value) - 103.939
        default:
            return 0
        }
    }

}
