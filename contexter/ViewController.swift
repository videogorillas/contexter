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
    @IBOutlet weak var imageViewLeft: UIImageView!
    @IBOutlet weak var imageViewRight: UIImageView!

    @IBOutlet weak var label1: UILabel!
    @IBOutlet weak var label2: UILabel!
    @IBOutlet weak var label3: UILabel!
    @IBOutlet weak var label4: UILabel!
    @IBOutlet weak var label5: UILabel!
    @IBOutlet weak var detectButton: UIButton!
    @IBOutlet weak var switchModeButton: UIButton!

    let imageSubject = PublishSubject<UIImage>()
    let segmentedImageSubject = PublishSubject<UIImage>()
    var imageDisposible: CompositeDisposable?

    //Camera Capture requiered properties
    var videoDataOutput: AVCaptureVideoDataOutput!

    var videoDataOutputQueue: DispatchQueue!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var captureDevice: AVCaptureDevice!
    let session = AVCaptureSession()

    let mlcontexter = contexter()
    let mlcontexterClasses = ContexterClasses()

    let imagenet = tiny_imagenet()
    let imagenetClasses = TinyImageNetClasses()

    var oneImageView = false

    @IBAction func onSwitchModeClick(_ sender: Any) {
        oneImageView = !oneImageView
        if oneImageView {
            switchModeButton.setTitle("Contexter mode", for: UIControlState.normal)
        } else {
            switchModeButton.setTitle("Segmenter mode", for: UIControlState.normal)
        }
        switchScreens()
        initImageView()
    }

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
        switchScreens()
        initImageView()
        switchModeButton.isHidden = true
    }

    func initImageView() {
        if imageDisposible == nil {
            imageDisposible = CompositeDisposable()
        } else {
            imageDisposible?.dispose()
            imageDisposible = CompositeDisposable()
        }
        imageDisposible?.insert(imageSubject
                .subscribe { event in
                    if self.oneImageView {
                        DispatchQueue.main.async {
                            self.imageView.image = event.element
                        }
                    } else {
                        let newCGImage = event.element?.cgImage?.copy()
                        let newImage = UIImage(cgImage: newCGImage!, scale: event.element!.scale, orientation: event.element!.imageOrientation)
                        self.segmentedImageSubject.onNext(newImage)
                        
                        DispatchQueue.main.async {
                            self.imageViewLeft.image = event.element
                         }
                    }
                })

        imageDisposible?.insert(segmentedImageSubject
                .subscribe { event in
//                    let pixelData = ImageUtils.pixelData(event.element!)
//                    let cgImage = ImageUtils.cgImageFromPixelData(data: pixelData, size: event.element!.size)
//                    let image = UIImage.init(cgImage: cgImage!)
                    
                    let image = event.element!
                    
                    let pixels = ImageUtils.pixelData(image)
                    let r = pixels!.enumerated().filter { $0.offset % 4 == 0 }.map { $0.element }
                    let g = pixels!.enumerated().filter { $0.offset % 4 == 1 }.map { $0.element * 0 }
                    let b = pixels!.enumerated().filter { $0.offset % 4 == 2 }.map { $0.element * 0 }
//                    let a = pixels!.enumerated().filter { $0.offset % 4 == 3 }.map { $0.element }
                    
                    let multiArray = MultiArray<Int32>.init(shape: [3, Int(image.size.height), Int(image.size.width)])
                    
                    let combination = r + g + b
                    
                    for (index, element) in combination.enumerated() {
                        multiArray.array[index] = element as NSNumber
                    }

                    DispatchQueue.main.async {
                        self.imageViewRight.image = multiArray.image(offset: 0, scale: 1)
                    }
                })
        
    }

    func switchScreens() {
        if oneImageView {
            imageViewLeft.isHidden = true
            imageViewRight.isHidden = true
        } else {
            imageView.isHidden = true
            detectButton.isHidden = true
            label1.isHidden = true
            label2.isHidden = true
            label3.isHidden = true
            label4.isHidden = true
            label5.isHidden = true
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
