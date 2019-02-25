//
//  ViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//

import UIKit
import AVFoundation
import Charts

class MBViewController: UIViewController   {
    
    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    let pinchFilterIndex = 2
    var detector:CIDetector! = nil
    let bridge = OpenCVBridgeSub() // this is the subclassed version
    var chartData:[Double]=[]
    var dataEntries: [ChartDataEntry] = []
    //MARK: Outlets in view
   
    //@IBOutlet weak var flashButton: UIButton!
    
    @IBOutlet weak var lineChartView: LineChartView!
    
    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.back)
        self.videoManager.setFPS(desiredFrameRate: 30)
        // create dictionary for face detection
        // HINT: you need to manipulate these proerties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyLow,CIDetectorTracking:true] as [String : Any]
        
        // setup a detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                   context: self.videoManager.getCIContext(), // perform on the GPU is possible
            options: (optsDetector as [String : AnyObject]))
        
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.turnOffFlash()

    }
    
    
    //MARK: Process image output
    func processImage(inputImage:CIImage) -> CIImage{

        
        var retImage = inputImage
        
        // if you just want to process on separate queue use this code
        // this is a NON BLOCKING CALL, but any changes to the image in OpenCV cannot be displayed real time
        //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) { () -> Void in
        //            self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
        //            self.bridge.processImage()
        //        }
        
        // use this code if you are using OpenCV and want to overwrite the displayed image via OpenCv
        // this is a BLOCKING CALL
        //        self.bridge.setTransforms(self.videoManager.transform)
        //        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
        //        self.bridge.processImage()
        //        retImage = self.bridge.getImage()
        
        //HINT: you can also send in the bounds of the face to ONLY process the face in OpenCV
        // or any bounds to only process a certain bounding region in OpenCV
        self.bridge.setTransforms(self.videoManager.transform)
        self.bridge.setImage(retImage,
                             withBounds: retImage.extent, //f[0].bounds, // the first face bounds
            andContext: self.videoManager.getCIContext())
        
        self.bridge.processImage()
        retImage = self.bridge.getImageComposite() // get back opencv processed part of the image (overlayed on original)
        
        DispatchQueue.main.async{
            if(self.bridge.finger){
                self.videoManager.turnOnFlashwithLevel(1.0)
                
                self.lineChartView.setVisibleXRangeMaximum(100)
                
                
                self.lineChartView.setScaleEnabled(true)
                
                
                self.chartData.append(self.bridge.curRed)
                let dataEntry = ChartDataEntry(x:Double(self.chartData.count),y:self.bridge.curRed)
                self.dataEntries.append(dataEntry)
                
                
                let lineChartDataSet = LineChartDataSet(values: self.dataEntries, label: "Redness")
                lineChartDataSet.drawCirclesEnabled=false
                lineChartDataSet.fillColor=UIColor.blue
                lineChartDataSet.drawValuesEnabled=false
                let lineChartData = LineChartData(dataSet: lineChartDataSet)
                
                self.lineChartView.data = lineChartData
                
                self.lineChartView.autoScaleMinMaxEnabled=true
                
                self.lineChartView.notifyDataSetChanged()
                self.lineChartView.moveViewToX(Double(self.chartData.count)+1)
            }
                
        //******timer
                
        //***The last one cannot be completely realized.When the flash on, the button is also enabled.
                //self.videoManager.turnOnFlashwithLevel(1);
            /*else {
                self.flashButton.isEnabled = true;
               // self.cameraButton.isEnabled = true;
                //self.videoManager.turnOffFlash()
                
                //self.videoManager.turnOffFlash();
            }*/
            
        }
        return retImage
    }
    
    //MARK: Convenience Methods for UI Flash and Camera Toggle
    

    @IBAction func clean(_ sender: Any) {
        self.chartData = []
        self.dataEntries = []
        self.lineChartView.clear()
    }
}


