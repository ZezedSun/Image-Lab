//
//  OpenCVBridgeSub.m
//  ImageLab
//
//  Created by Eric Larson on 10/4/16.
//  Copyright © 2016 Eric Larson. All rights reserved.
//

#import "OpenCVBridgeSub.h"

#import "AVFoundation/AVFoundation.h"


using namespace cv;

#include<vector>

using namespace cv;

@interface OpenCVBridgeSub()
@property (nonatomic) cv::Mat image;
//@property (nonatomic)BOOL finger;
@end

@implementation OpenCVBridgeSub
@dynamic image;
//@dynamic just tells the compiler that the getter and setter methods are implemented not by the class itself but somewhere else (like the superclass or will be provided at runtime).

vector<float> blue;
vector<float> green;
vector<float> red;
int windowSize = 10;
int count=0;
vector<int> countArr;
-(void)processImage{
    
    _finger=false;
    _rawData=0;
    cv::Mat frame_gray,image_copy;
    char text[50];
    char print[50];
    char arrayprint[50];
    char countShow[50];
    Scalar avgPixelIntensity;
    cv::Mat image = self.image;
    
    cvtColor(image, image_copy, CV_BGRA2BGR); // get rid of alpha for processing
    avgPixelIntensity = cv::mean( image_copy );
    sprintf(text,"Avg. B: %.0f, G: %.0f, R: %.0f", avgPixelIntensity.val[0],avgPixelIntensity.val[1],avgPixelIntensity.val[2]);
    if(avgPixelIntensity.val[0]>150&&avgPixelIntensity.val[1]<30&&avgPixelIntensity.val[2]<45){
        
        
        _finger=true;
        sprintf(print, "This is finger!");
        blue.push_back(avgPixelIntensity.val[0]);
        green.push_back(avgPixelIntensity.val[1]);
        red.push_back(avgPixelIntensity.val[2]);
        _rawData = red[red.size()-1];
        
        vector<float> arr1;
        vector<float> arr2;
        int divisor=int(red.size()/300);
        int remain=red.size()%300;
        
        if(remain==0){
            // peak value
            count=0;
            if(divisor==1){
                return;
            }
            else{
                for(int i = (divisor-1)*300;i<(divisor-1)*300+(300-windowSize);i++){
                    float max = red[i];
                    for(int j=i;j<i+windowSize;j++){
                        if(red[j]>max)
                            max=red[j];
                    }
                    arr1.push_back(max);
                }
                for(int i=1;i<arr1.size();i++){
                    if(arr1[i]!=arr1[i-1]){
                        arr2.push_back(arr1[i]);
                    }
                }
                for(int i=1;i<arr2.size();i++){
                    if(arr2[i]>arr2[i-1]&&arr2[i]>arr2[i+1]){
                        count++;
                    }
                }
            }
            
            std::cout<<count;
            countArr.push_back(count*6);
            
        }
        
    }
    else{
        count=0;
        red.clear();
        blue.clear();
        green.clear();
        countArr.clear();
    }
    
    sprintf(countShow,"Heart rate:");
    
    if(countArr.size()==1){
        sprintf(countShow,"Heart rate: %.0d",countArr[countArr.size()-1]);
    }
    else if(countArr.size()==2){
        sprintf(countShow,"Heart rate: %.0d",int(countArr[countArr.size()-1]+countArr[countArr.size()-2])/2);
    }
    else if(countArr.size()==3){
        sprintf(countShow,"Heart rate: %.0d",int(countArr[countArr.size()-1]+countArr[countArr.size()-2]+countArr[countArr.size()-3])/3);
    }
    else if(countArr.size()==4){
        sprintf(countShow,"Heart rate: %.0d",int(countArr[countArr.size()-1]+countArr[countArr.size()-2]+countArr[countArr.size()-3]+countArr[countArr.size()-4])/4);
    }
    else if(countArr.size()==5){
        sprintf(countShow,"Heart rate: %.0d",int(countArr[countArr.size()-1]+countArr[countArr.size()-2]+countArr[countArr.size()-3]+countArr[countArr.size()-4]+countArr[countArr.size()-5])/5);
    }
    else if(countArr.size()>=6){
        sprintf(countShow,"Heart rate: %.0d",int(countArr[countArr.size()-1]+countArr[countArr.size()-2]+countArr[countArr.size()-3]+countArr[countArr.size()-4]+countArr[countArr.size()-5]+countArr[countArr.size()-6])/6);
    }
    
    cv::putText(image, countShow, cv::Point(200, 70),FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
    cv::putText(image, text, cv::Point(60, 100), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
    cv::putText(image, print, cv::Point(80, 70), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
    cv::putText(image, arrayprint, cv::Point(100, 100), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
    self.image = image;
}

@end
