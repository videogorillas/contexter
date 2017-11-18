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
    
    @IBAction func onDetectButton(_ sender: Any) {
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
