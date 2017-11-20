//
//  ViewController.swift
//  contexter
//
//  Created by Aleksey Sevruk on 11/18/17.
//  Copyright © 2017 Aleksey Sevruk. All rights reserved.
//

import UIKit
import AVFoundation
import RxSwift
import CoreML

class ViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var label4: UILabel!
    @IBOutlet weak var label5: UILabel!
    
    let imageSubject = PublishSubject<UIImage>()
    
    //Camera Capture requiered properties
    var videoDataOutput: AVCaptureVideoDataOutput!
    
    var videoDataOutputQueue: DispatchQueue!
    var previewLayer:AVCaptureVideoPreviewLayer!
    var captureDevice : AVCaptureDevice!
    let session = AVCaptureSession()
    
    let mlcontexter = contexter()
    let mlcontexterClasses = ContexterClasses()
    
    let imagenet = tiny_imagenet()
    let imagenetClasses = TinyImageNetClasses()
    
    @IBAction func onDetectButton(_ sender: Any) {
        let image = imageView.image!
        let pixelbuffer64x64 = resizedPixelBuffer(image: image, size: CGSize(width: 64, height: 64))
        let pixelbuffer299x299 = resizedPixelBuffer(image: image, size: CGSize(width: 299, height: 299))
        
        guard let tinyImageNetOutput = try? imagenet.prediction(image: pixelbuffer64x64) else {
            print("fatal error :( ")
            return
        }
        
        guard let mlcontexterOutput = try? mlcontexter.prediction(image: pixelbuffer299x299) else {
            print("fatal error :( ")
            return
        }
        
        let tinyImageNetLabels = MLUtils.getFirstNLabels(arr: tinyImageNetOutput.output1, dict: imagenetClasses.dict, classes: 5)
        
        let mlcontexterLabels = MLUtils.getFirstNLabels(arr: mlcontexterOutput.output1, dict: mlcontexterClasses.dict, classes: 5)
        
        label1.text = mlcontexterLabels[0]
        label2.text = mlcontexterLabels[1]
        
        label4.text = tinyImageNetLabels[0]
        label5.text = tinyImageNetLabels[1]
    }
    
    func resizedPixelBuffer(image: UIImage, size: CGSize) -> CVPixelBuffer {
        let resizedImage = ImageUtils.resizeImage(image: image, scaledToSize: size)
        let pixelBuffer = ImageUtils.getPixelBuffer(from: resizedImage)
        return pixelBuffer!
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupAVCapture()
        
        imageSubject.subscribe { event in
            DispatchQueue.main.async {
                self.imageView.image = event.element
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
