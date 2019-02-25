//
//  ViewController.swift
//  ImageLab
//
//  Created by Eric Larson
//  Copyright © 2016 Eric Larson. All rights reserved.
//


//**************************************************
//Module A
//**************************************************
import UIKit
import AVFoundation

class ViewController: UIViewController   {

    //MARK: Class Properties
    var filters : [CIFilter]! = nil
    var videoManager:VideoAnalgesic! = nil
    var detector:CIDetector! = nil

    @IBOutlet weak var faceStatus: UILabel!
    
    let pinchFilterIndex = 2
    let bridge = OpenCVBridge()


    //MARK: ViewController Hierarchy
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = nil
        self.setupFilters()

        self.videoManager = VideoAnalgesic.sharedInstance
        self.videoManager.setCameraPosition(position: AVCaptureDevice.Position.front)

        // create dictionary for face detection
        // HINT: you need to manipulate these proerties for better face detection efficiency
        let optsDetector = [CIDetectorAccuracy:CIDetectorAccuracyLow]
        
        // setup a face detector in swift
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: self.videoManager.getCIContext(), // perform on the GPU is possible
                                  options: optsDetector)
        self.videoManager.setProcessingBlock(newProcessBlock: self.processImage)
        
        if !videoManager.isRunning{
            videoManager.start()
        }

    }

    //MARK: Setup filtering
    func setupFilters(){
        filters = []

//        let filterPinch = CIFilter(name:"CIBumpDistortion")!
//        filterPinch.setValue(-0.3, forKey: "inputScale")
//        filterPinch.setValue(75, forKey: "inputRadius")
//        filters.append(filterPinch)
        
        let filterHole = CIFilter(name:"CIHoleDistortion")!
        filterHole.setValue(30, forKey: "inputRadius")
        filters.append(filterHole)

        let filterPinch = CIFilter(name:"CITorusLensDistortion")!
        filterPinch.setValue(50, forKey: "inputWidth")
        filterPinch.setValue(80, forKey: "inputRadius")
        filterPinch.setValue(0.9, forKey: "inputRefraction")
        filters.append(filterPinch)


    }

    //MARK: Apply filters and apply feature detectors
    func applyFiltersToFaces(inputImage:CIImage,features:[CIFaceFeature])->CIImage{
        var retImage = inputImage
        /*var filterCenter = CGPoint()

        for f in features {
            //set where to apply filter
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY

            //do for each filter (assumes all filters have property, "inputCenter")
            for filt in filters{
                filt.setValue(retImage, forKey: kCIInputImageKey)
                filt.setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
                // could also manipualte the radius of the filter based on face size!
                retImage = filt.outputImage!
            }
        }
        return retImage*/

        var filterCenter = CGPoint()
        var filterCenter1 = CGPoint()
        var filterCenter2 = CGPoint()
        var filterCenter3 = CGPoint()

     
        for f in features {
        // display if the user is smiling or blinking (and with which eye)
            DispatchQueue.main.async{
                if(f.leftEyeClosed){
                    self.faceStatus.text = "Left eye close"
                    NSLog("Left eye close")
                }
                else if(f.rightEyeClosed){
                    self.faceStatus.text = "Right eye close"
                     NSLog("Right eye closed")
                }
                else if(f.hasSmile){
                    self.faceStatus.text = "You are smiling"
                    NSLog("Smiling")
                }
                else {
                    self.faceStatus.text = "No smiling or blinking "
                    NSLog("No smiling or blinking")
                }
            }


            //where to apply filter
            filterCenter1.x = f.leftEyePosition.x
            filterCenter1.y = f.leftEyePosition.y
            filterCenter2.x = f.rightEyePosition.x
            filterCenter2.y = f.rightEyePosition.y
            filterCenter3.x = f.mouthPosition.x
            filterCenter3.y = f.mouthPosition.y
            filterCenter.x = f.bounds.midX
            filterCenter.y = f.bounds.midY
            filters[0].setValue(retImage, forKey: kCIInputImageKey)
            filters[0].setValue(CIVector(cgPoint: filterCenter1), forKey: "inputCenter")
            retImage = filters[0].outputImage!
            filters[0].setValue(retImage, forKey: kCIInputImageKey)
            filters[0].setValue(CIVector(cgPoint: filterCenter2), forKey: "inputCenter")
            retImage = filters[0].outputImage!
            filters[0].setValue(retImage, forKey: kCIInputImageKey)
            filters[0].setValue(CIVector(cgPoint: filterCenter3), forKey: "inputCenter")
            retImage = filters[0].outputImage!
            filters[1].setValue(retImage, forKey: kCIInputImageKey)
            filters[1].setValue(CIVector(cgPoint: filterCenter), forKey: "inputCenter")
            retImage = filters[1].outputImage!
        }
        return retImage
    }

    func getFaces(img:CIImage) -> [CIFaceFeature]{
        // this ungodly mess makes sure the image is the correct orientation
        let optsFace = [CIDetectorImageOrientation:self.videoManager.ciOrientation,CIDetectorEyeBlink:true, CIDetectorSmile:true] as [String : Any]
        // get Face Features
        return self.detector.features(in: img, options: optsFace) as! [CIFaceFeature]

    }

        //MARK: Process image output
        func processImage(inputImage:CIImage) -> CIImage{


            // detect faces
            let f = getFaces(img: inputImage)

            // if no faces, just return original image
            if f.count == 0 { return inputImage }

            return applyFiltersToFaces(inputImage: inputImage, features: f)

            //var retImage = inputImage

            // use this code if you are using OpenCV and want to overwrite the displayed image via OpenCv
            // this is a BLOCKING CALL
            //        self.bridge.setImage(retImage, withBounds: retImage.extent, andContext: self.videoManager.getCIContext())
            //        self.bridge.processImage()
            //        retImage = self.bridge.getImage()
            //
            //HINT: you can also send in the bounds of the face to ONLY process the face in OpenCV
            // or any bounds to only process a certain bounding region in OpenCV

            // return retImage
        }

}


