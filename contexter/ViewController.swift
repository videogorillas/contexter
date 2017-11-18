//
//  ViewController.swift
//  contexter
//
//  Created by Aleksey Sevruk on 11/18/17.
//  Copyright © 2017 Aleksey Sevruk. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var label4: UILabel!
    @IBOutlet weak var label5: UILabel!
    
    //Camera Capture requiered properties
    var videoDataOutput: AVCaptureVideoDataOutput!
    
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let session = AVCaptureSession()
    
    @IBAction func onDetectButton(_ sender: Any) {
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.setupAVCapture()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

extension ViewController:  AVCaptureVideoDataOutputSampleBufferDelegate {
    func setupAVCapture(){
        self.session.sessionPreset = AVCaptureSessionPreset640x480
        guard let device = AVCaptureDevice
            .defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back)
            else { return }
        captureDevice = device
//        captureDevice.activeColorSpace = AVCaptureColorSpace.sRGB
        beginSession()
    }
    
    func beginSession(){
        var err : NSError? = nil
        var deviceInput:AVCaptureDeviceInput?
        do {
            deviceInput = try AVCaptureDeviceInput(device: captureDevice)
        } catch let error as NSError {
            err = error
            deviceInput = nil
        }
        if err != nil {
            print("error: \(String(describing: err?.localizedDescription))");
        }
        if self.session.canAddInput(deviceInput!){
            self.session.addInput(deviceInput!);
        }
        
        videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.alwaysDiscardsLateVideoFrames=true
        videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey: kCVPixelFormatType_32BGRA]
        
        videoDataOutputQueue = DispatchQueue(label: "VideoDataOutputQueue")
        videoDataOutput.setSampleBufferDelegate(self, queue:self.videoDataOutputQueue)
        videoDataOutput.connection(withMediaType: AVMediaTypeVideo)?.isEnabled = true
        
        if self.session.canAddOutput(self.videoDataOutput){
            self.session.addOutput(self.videoDataOutput)
        }
        
        session.startRunning()
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                       from connection: AVCaptureConnection!) {
        // Get a CMSampleBuffer's Core Video image buffer for the media data
        let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        // Lock the base address of the pixel buffer
        CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
        
        
        // Get the number of bytes per row for the pixel buffer
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!);
        
        // Get the number of bytes per row for the pixel buffer
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!);
        // Get the pixel buffer width and height
        let width = CVPixelBufferGetWidth(imageBuffer!);
        let height = CVPixelBufferGetHeight(imageBuffer!);
        
        // Create a device-dependent RGB color space
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        
        // Create a bitmap graphics context with the sample buffer data
        var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
        bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
        //let bitmapInfo: UInt32 = CGBitmapInfo.alphaInfoMask.rawValue
        let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        // Create a Quartz image from the pixel data in the bitmap graphics context
        let quartzImage = context?.makeImage();
        // Unlock the pixel buffer
        CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
        
        if quartzImage != nil {
            // Create an image object from the Quartz image
            let image = UIImage.init(cgImage: quartzImage!);
            DispatchQueue.main.async {
                self.imageView.image = image
            }
        }

        
    }
    
    // clean up AVCapture
    func stopCamera(){
        session.stopRunning()
    }
    
    func startCamera() {
        session.startRunning()
    }
}
