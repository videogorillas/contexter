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
    let readyOnNewDataSubject = BehaviorSubject<Bool>(value: true)
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
        var isPipelineStarted = false
        imageDisposible?.insert(imageSubject
            .subscribe { event in
                    let image = event.element
                    if self.oneImageView {
                        DispatchQueue.main.async {
                            self.imageView.image = image
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.imageViewLeft.image = image
                            if (self.imageViewLeft.image != nil && !isPipelineStarted ) {
                                self.readyOnNewDataSubject.onNext(true)
                            }
                         }
                    }
                }
            )
        
        self.imageDisposible?.insert(
            self.readyOnNewDataSubject.subscribe { event in
                DispatchQueue.main.async {
                    if (self.imageViewLeft.image != nil) {
                        self.segmentedImageSubject.onNext(self.imageViewLeft.image!)
                        isPipelineStarted = true
                    }
                }
                
            }
        )
        
        imageDisposible?.insert(
            segmentedImageSubject
                .subscribe { event in
                    let image = event.element!
                    
                    let pixels = ImageUtils.pixelData(image)
                    let multiArray = MultiArray<Int32>.init(shape: [3, Int(image.size.height), Int(image.size.width)])

                    var rcount = 0
                    var gcount = Int(1 * image.size.width * image.size.height)
                    var bcount = Int(2 * image.size.width * image.size.height)
                    for (index, element) in pixels!.enumerated() {
                        if index % 4 == 0 {
                            multiArray.array[rcount] = element as NSNumber
                            rcount += 1
                        }
                        
                        if index % 4 == 1 {
                            multiArray.array[gcount] = element * 0 as NSNumber
                            gcount += 1
                        }
                        
                        if index % 4 == 2 {
                            multiArray.array[bcount] = element * 0 as NSNumber
                            bcount += 1
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.imageViewRight.image = multiArray.image(offset: 0, scale: 1)
                        self.readyOnNewDataSubject.onNext(true)
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
