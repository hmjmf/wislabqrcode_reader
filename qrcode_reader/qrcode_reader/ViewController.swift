//
//  ViewController.swift
//  qrcode_reader
//
//  Created by 启翔 张 on 2017/11/14.
//  Copyright © 2017年 启翔 张. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    var session = AVCaptureSession()
    var previewImage = UIImage()
  
    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        print(OpenCVWrapper.openCVVersionString())
        
        startQR()
//        startLiveVideo()
        _ = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.setPreviewImage), userInfo: nil, repeats: true)
    }
    func startQR(){
        session.sessionPreset = AVCaptureSession.Preset.photo
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let qrcodeCaptureOutput = AVCaptureMetadataOutput()
        qrcodeCaptureOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        
        
        let wislabcodeCaptureOutput = AVCaptureVideoDataOutput()
        wislabcodeCaptureOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        wislabcodeCaptureOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        
        
        session.addInput(deviceInput)
        session.addOutput(qrcodeCaptureOutput)
        session.addOutput(wislabcodeCaptureOutput)
        qrcodeCaptureOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        session.startRunning()

    }
    func startLiveVideo() {
        session.sessionPreset = AVCaptureSession.Preset.photo
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        
        let deviceInput = try! AVCaptureDeviceInput(device: captureDevice!)
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        session.startRunning()
    }
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        connection.videoOrientation = AVCaptureVideoOrientation.portrait;
        updatePreviewImage(sampleBuffer:sampleBuffer)
        
    }
    func updatePreviewImage(sampleBuffer: CMSampleBuffer){
        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
        let ciimage : CIImage = CIImage(cvPixelBuffer: imageBuffer)
        previewImage = self.convertCIImageToUIImage(cmage: ciimage)
    }
    func convertCIImageToUIImage(cmage:CIImage) -> UIImage {
        let context:CIContext = CIContext.init(options: nil)
        let cgImage:CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage, scale: 1.0, orientation: UIImageOrientation.right)
        return image
    }
    
    @objc func setPreviewImage(){
        let image = OpenCVWrapper.processImage(previewImage)
        imageView.image = image
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
extension ViewController:AVCaptureMetadataOutputObjectsDelegate{
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection){
        var stringValue:String?
        if metadataObjects.count > 0 {
            let metadataObject = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
            stringValue = metadataObject.stringValue
            print(stringValue)
        }
    }
}

