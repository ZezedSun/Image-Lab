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

@interface OpenCVBridgeSub()
@property (nonatomic) cv::Mat image;
@end

@implementation OpenCVBridgeSub
@dynamic image;
//@dynamic just tells the compiler that the getter and setter methods are implemented not by the class itself but somewhere else (like the superclass or will be provided at runtime).

vector<double> blue;
vector<double> green;
vector<double> red;
vector<int>countArray;
//double intervaler=0;
int count = 0;
double intervaler =0;

//Override the process Image Function
-(void)processImage{
    //using namespace std;
    _curRed = 0;
    _finger = false;
    using namespace std::chrono;
    cv::Mat frame_gray,image_copy;
    char text[50];
    char print[50];
    char heartRate[50];
    //const int frameRate = 30;
    static std::vector<int> maxindexes;
    static std::vector<double> maxes;
    static std::vector<int64> maxtimes;
    static std::vector<int> indexes;
    static std::vector<double> heartbeat;
    static std::vector<int> heartbeatIndex;
    static std::vector<int64> heartbeatMilliseconds;
    static std::list<std::tuple<double, int,int64>> buf;
    static bool raise = false;
    static double preheartRate = -1;
    static double curheartRate;
    
    //static std::
    static const std::size_t windowSize = 10;
    static int index =0;
    //static double preRed =0;
    static float coefficeint = 0.5;
    static double max = -1;
    static int maxIndex =-1;
    static int64 maxTime;
    Scalar avgPixelIntensity;
    static std::vector<int> heartRates;
    // copy over the image pointer so that the c++ compiler
    // recognizes this as a valid cvMat
    cv::Mat image = self.image; // why does this need to happen? For the compiler... yeah
    
    cvtColor(image, image_copy, CV_BGRA2BGR); // get rid of alpha for processing
    avgPixelIntensity = cv::mean( image_copy );
    sprintf(text,"Avg. B: %.0f, G: %.0f, R: %.0f", avgPixelIntensity.val[2],avgPixelIntensity.val[1],avgPixelIntensity.val[0]);
    //std::cout<<"B "<<avgPixelIntensity.val[2]<<" G "<<avgPixelIntensity.val[1]<<" R "<<avgPixelIntensity.val[0]<<std::endl;
    //cv::putText(image, text, cv::Point(40, 60), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
    
    if(avgPixelIntensity.val[2]<45&&avgPixelIntensity.val[1]<30&&avgPixelIntensity.val[0]>150){
        
        
        // peak value
        
        int64 ms = duration_cast< milliseconds >(system_clock::now().time_since_epoch()).count();
        
        _finger=true;
        sprintf(print, "finger!");
        _curRed =avgPixelIntensity.val[0];
        //create a window to peak max value of red
        red.push_back(_curRed);
        indexes.push_back(index);
        //std::cout<<"index "<<index<<" red "<<_curRed<<std::endl;
        if(index <windowSize){
            
            buf.push_back(std::tuple<double,int,int64>(_curRed,index,ms));
            if(max<_curRed){ max = _curRed; maxIndex = index; maxTime = ms;}
        }
        
        else {
            buf.pop_front();
            buf.push_back(std::tuple<double,int,int64>(_curRed,index,ms));
            //std::cout<<"max index "<<maxIndex<<" max "<<max<<std::endl;
            if(max<_curRed){ max = _curRed; maxIndex = index;}
            else if (maxIndex == index-windowSize){
                //std::cout<<"here"<<std::endl;
                int _maxindex=0;
                double _max=-1;
                //Based on the output value of red,we found that output frame will decrease beacuse we analyze and choose peak red value at the same time. So we analyze every frame of value and calculate the heart rate using time.
                int64 _maxtime=0;
                for(auto x : buf){
                    double r = std::get<0>(x);
                    int i = std::get<1>(x);
                    int64 time = std::get<2>(x);
                    //std::cout<<" i "<<i<<" r "<<r<<" ";
                    if(_max<r){
                        _max = r;
                        _maxindex = i;
                        _maxtime =time;
                    }
                }
                max = _max;
                maxIndex = _maxindex;
                maxTime =_maxtime;
                //std::cout<<std::endl;
                //std::cout<<"now max "<<max<<" maxindex "<<maxIndex<<std::endl;
            }
            //if(maxIndex == index - windowSize)
            //std::cout<<"raise "<<raise<<" current max "<<max<<" current maxIndex "<<maxIndex<<std::endl;
            /*for(int i =0;i<maxes.size();i++){
             std::cout<<"(value "<<maxes[i]<<" , index "<<maxindexes[i]<<") ";
             }*/
            std::cout<<std::endl;
            if(maxindexes.size()>0){
                double preMax = maxes.back();
                int preMaxIndex = maxindexes.back();
                int64 preMaxTime = maxtimes.back();
                //std::cout<<" preMax "<<preMax<<" preMaxIndex "<<preMaxIndex<<std::endl;
                if(raise && max < preMax){
                    raise = false;
                    //std::cout<<"change raise to 0 "<<std::endl;
                    if(heartbeatIndex.size()>0){
                        std::cout<<"from "<<heartbeatIndex.back()<<" to "<<preMaxIndex<<std::endl;
                        std::cout<<"from time "<<heartbeatMilliseconds.back()<<" to "<<preMaxTime<<std::endl;
                        intervaler = (double)(preMaxTime - heartbeatMilliseconds.back())/1000;
                        std::cout<<" intervaler "<<intervaler<<std::endl;
                        
                        if(preheartRate > 0){
                            curheartRate = coefficeint*60/intervaler + (1-coefficeint)*preheartRate;}
                        else{
                            curheartRate = 60/intervaler;
                        }
                        //intervaler = (double)(preMaxIndex - heartbeatIndex.back())*1.27/frameRate;
                        
                        std::cout<<" heart rate "<<curheartRate<<std::endl;
                        
                        //sprintf(heartRate, "heart rate:%d",int(60/intervaler));
                    }
                    //std::cout<<"add index "<<preMaxIndex<<" to heart Beat"<<std::endl;
                    heartbeat.push_back(preMax);
                    heartbeatIndex.push_back(preMaxIndex);
                    heartbeatMilliseconds.push_back(preMaxTime);
                    
                }
                else if(!raise && max > preMax){
                    raise = true;
                }
                
            }
            //find max value and calculate the heart rate
            if(maxindexes.size()>0){
                if(maxIndex!=maxindexes.back()){
                    maxindexes.push_back(maxIndex);
                    maxes.push_back(max);
                    maxtimes.push_back(ms);
                    std::cout<<"max index "<<maxIndex<<" max "<<max<<std::endl;
                }
                
            }
            else {
                maxindexes.push_back(maxIndex);
                maxes.push_back(max);
                maxtimes.push_back(ms);
            }
            
            
            
            
        }
        
        sprintf(heartRate, "heart Rate: %d",int(curheartRate));
        preheartRate = curheartRate;
        heartRates.push_back(int(curheartRate));
        cv::putText(image, text, cv::Point(60, 40), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
        cv::putText(image, print, cv::Point(50, 50), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255), 1, 2);
        cv::putText(image, heartRate, cv::Point(80,80), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255),1,2);
        //cv::putText(image, countArray, cv::Point(100,100), FONT_HERSHEY_PLAIN, 0.75, Scalar::all(255),1,2);
        
        
        
        self.image = image;
        //}
        index++;
    }
}
@end

