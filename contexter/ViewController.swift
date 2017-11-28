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

//    let mlcontexter = contexter()
//    let mlcontexterClasses = ContexterClasses()
    
    let segnet = segmenter()

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
        let pixelbuffer299x299 = resizedPixelBuffer(image: image, size: CGSize(width: 299, height: 299))

//        guard let mlcontexterOutput = try? mlcontexter?.prediction(image: pixelbuffer299x299) else {
//            print("fatal error :( ")
//            return
//        }
//
//        let mlcontexterLabels = MLUtils.getFirstNLabels(arr: mlcontexterOutput.output1, dict: mlcontexterClasses.dict, classes: 5)
//
//        label1.text = mlcontexterLabels[0]
//        label2.text = mlcontexterLabels[1]
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
                    if (self.imageViewLeft.image != nil) {
                        self.segmentedImageSubject.onNext(self.imageViewLeft.image!)
                        isPipelineStarted = true
                    }

                }
        )
        
        imageDisposible?.insert(
            segmentedImageSubject
                .subscribe { event in
                    let width = 256
                    let height = 256
                    let size = width*height
                    
                    let pixelBuffer = self.resizedPixelBuffer(image: event.element!, size: CGSize(width: width, height: height))
                    let image = UIImage.init(pixelBuffer: pixelBuffer)!

                    let startPredict = DispatchTime.now()
                    guard let unetout = try? self.segnet.prediction(image: pixelBuffer) else {
                        print("fatal error :( ")
                        return
                    }
                    let endPredict = DispatchTime.now()
                    print("predict time: \(endPredict.uptimeNanoseconds - startPredict.uptimeNanoseconds)")
                    
                    let pixels = ImageUtils.pixelData(image)
                    let multiArray = MultiArray<Int32>.init(shape: [3, Int(image.size.height), Int(image.size.width)])

                    let startFillFrame = DispatchTime.now()
                    for i in 0..<size {
                        // r g b a r g b a r g
                        // 0 1 2 3 4 5 6 7 8 9
                        let rid = i*4
                        let mrid = i
                        
                        let gid = rid + 1
                        let mgid = size + i
                        
                        let bid = rid + 2
                        let mbid = 2*size + i
                        
                        let mask = unetout.output1[i]
                        
                        multiArray.array[mrid] = (Double(pixels![rid]) * (1.0 - mask.doubleValue)) as NSNumber    // r
                        multiArray.array[mgid] = (Double(pixels![gid]) * (1.0 - mask.doubleValue)) as NSNumber    // g
                        multiArray.array[mbid] = (Double(pixels![bid]) * (1.0 - mask.doubleValue)) as NSNumber    // b
                    }
                    let endFillFrame = DispatchTime.now()
                    print("frame render time: \(endFillFrame.uptimeNanoseconds - startFillFrame.uptimeNanoseconds)")

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
