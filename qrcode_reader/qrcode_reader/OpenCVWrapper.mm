//
//  OpenCVWrapper.m
//  qrcode_reader
//
//  Created by 启翔 张 on 2017/11/14.
//  Copyright © 2017年 启翔 张. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "OpenCVWrapper.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
using namespace cv;


@implementation OpenCVWrapper : NSObject 



+(NSString *) openCVVersionString{
    return [NSString stringWithFormat:@"opencv cersion %s", CV_VERSION]; 
}

cv::Point2f cross_point(std::vector<cv::Point> line1, std::vector<cv::Point> line2){
    if (!(line1.size() == 2 && line2.size() == 2)){
        return cv::Point();
    }
    //double X1=line1->pEnd.x-line1->pStart.x;//b1
    double X1=line1[1].x - line1[0].x;
    
    //double Y1=line1->pEnd.y-line1->pStart.y;//a1
    double Y1=line1[1].y - line1[0].y;
    
    //double X2=line2->pEnd.x-line2->pStart.x;//b2
    double X2=line2[1].x - line2[0].x;
    
    //double Y2=line2->pEnd.y-line2->pStart.y;//a2
    double Y2=line2[1].y - line2[0].y;
    
    //double X21=line2->pStart.x-line1->pStart.x;
    double X21=line2[0].x - line1[0].x;
    
    //double Y21=line2->pStart.y-line1->pStart.y;
    double Y21=line2[0].y - line1[0].y;
    
    double D=Y1*X2-Y2*X1;// a1b2-a2b1
    if(D==0) return cv::Point2f();
    cv::Point2f pt = cv::Point2f();
    //pt.x=(X1*X2*Y21 + Y1*X2*line1->pStart.x - Y2*X1*line2->pStart.x)/D;
    pt.x = (X1*X2*Y21 + Y1*X2*line1[0].x - Y2*X1*line2[0].x)/D;
    //pt.y=-(Y1*Y2*X21 + X1*Y2*line1->pStart.y - X2*Y1*line2->pStart.y)/D;
    pt.y=-(Y1*Y2*X21 + X1*Y2*line1[0].y - X2*Y1*line2[0].y)/D;
    
    
    if ((abs(pt.x-line1[0].x-X1/2) <= abs(X1/2)) &&
        (abs(pt.y-line1[0].y-Y1/2) <= abs(Y1/2)) &&
        (abs(pt.x-line2[0].x-X2/2) <= abs(X2/2)) &&
        (abs(pt.y-line2[0].y-Y2/2) <= abs(Y2/2)) )
    {
        return pt;
    }
    return cv::Point2f();
    
  
}
void sort_cross_point(std::vector<cv::Point>& points){
    if (points.size() != 4) {return;}
    std::vector<cv::Point> sort_points = points;
    std::vector<float> xsort;
    std::vector<float> ysort;
    
    for(int i = 0;i < points.size();i++){
        xsort.push_back(points[i].x);
        ysort.push_back(points[i].y);
    }
    std::sort(xsort.begin(),xsort.end(),std::less<float>());
    std::sort(ysort.begin(),ysort.end(),std::less<float>());
    cv::Point top_left,bottom_left,top_right,bottom_right;
    for(int i = 0;i < points.size();i++){
        cv::Point point = points[i];
        if(point.x <= xsort[1]){
            
        }
    }
    
}
+(UIImage *)processImage:(UIImage *)image {
    cv::Mat mat;
    UIImageToMat(image, mat);
    if (mat.step[0] <= 0){
        return MatToUIImage(mat);
    }
    
    cv::Mat original = mat;
    //灰度
    cv::cvtColor(mat, mat, CV_RGB2GRAY);
    
    //二值
    cv::threshold(mat, mat, 0, 255, cv::THRESH_BINARY | cv::THRESH_OTSU);
    cv::Mat threshold_mat;
    mat.copyTo(threshold_mat);
    //膨胀
//    cv::Mat element = getStructuringElement(MORPH_RECT, cv::Size(2,2));
//    cv::dilate(mat, mat, element);
    
    //边缘
    cv::Canny(mat, mat, 100, 200);

    std::vector<std::vector<cv::Point>> contours;

    //轮廓
    cv::findContours(mat, contours, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_NONE);

    //最大轮廓
    double maxArea = 0;
    int maxContourIndex = -1;
    int secondContourIndex = -1;
    std::vector<cv::Point> maxContour;
    std::vector<cv::Point> secondContour;
    for(size_t i = 0; i < contours.size(); i++)
    {
        double area = cv::contourArea(contours[i]);
        if (area > maxArea)
        {
            maxArea = area;
            secondContourIndex = maxContourIndex;
            maxContourIndex = i;
        }
    }
    
    if (maxContourIndex >= 0 && secondContourIndex >= 0){
        cv::Mat result;
        mat.copyTo(result);
//        cv::cvtColor(result,result,CV_GRAY2RGB);
//        maxContour = contours[maxContourIndex];
//        for(auto i = maxContour.begin(); i != maxContour.end(); i++){
//            cv::circle(result, *i, 2, cv::Scalar(0, 255, 0));
//        }
//        cv::Rect maxRect = cv::boundingRect(maxContour);
//        cv::rectangle(result, maxRect, cv::Scalar(0, 0, 255));
//
//        //掩码
//        Mat mask2(result.size(), CV_8U, Scalar(0));
//        cv::drawContours(mask2, contours, maxContourIndex, Scalar(255), CV_FILLED);
//
//
//        result = result(maxRect);
//
//        return MatToUIImage(result);
        
        maxContour = contours[maxContourIndex];
        secondContour = contours[secondContourIndex];
        
        
      
        //掩码
        Mat mask(result.size(), CV_8U, Scalar(0));
        cv::drawContours(mask, contours, maxContourIndex, Scalar(255), CV_FILLED);
        
        Mat crop(result.rows, result.cols, CV_8UC3);
        original.copyTo(crop, mask);
      
        //边缘
        Mat quad;
        cv::Canny(mask, quad, 100, 200);
        std::vector<Vec2f> lines;
        //霍夫
        HoughLines(quad, lines, 1, CV_PI/180, 150, 0, 0 );
        std::cout<<lines.size()<<std::endl;
        
        cv::cvtColor(quad,quad,CV_GRAY2RGB);
        
        if (lines.size() != 4) {
            return MatToUIImage(quad);
        }
        //交点
        std::vector<std::vector<cv::Point>> line_Points;
        for( size_t i = 0; i < lines.size(); i++ )
        {
            float rho = lines[i][0], theta = lines[i][1];
            cv::Point pt1, pt2;
            double a = cos(theta), b = sin(theta);
            double x0 = a*rho, y0 = b*rho;
            pt1.x = cvRound(x0 + 1000*(-b));
            pt1.y = cvRound(y0 + 1000*(a));
            pt2.x = cvRound(x0 - 1000*(-b));
            pt2.y = cvRound(y0 - 1000*(a));
            std::vector<cv::Point> points = std::vector<cv::Point>();
            points.push_back(pt1);
            points.push_back(pt2);
            line_Points.push_back(points);
            line(quad, pt1, pt2, Scalar(0,255,0), 1, CV_AA);
        }
        std::vector<cv::Point2f> cross_points_vector;
        for(auto i = line_Points.begin();i!=line_Points.end();i++){
            for(auto j = line_Points.begin();j!=line_Points.end();j++){
                if (i!=j){
                    auto p = cross_point(*i,*j);
                    if ( p.x != 0 && std::find(cross_points_vector.begin(), cross_points_vector.end(), p) == cross_points_vector.end() ){
                        cross_points_vector.push_back(p);
                    }
                }
            }
        }
        for(auto i = cross_points_vector.begin(); i != cross_points_vector.end(); i++){
            cv::circle(quad, *i, 15, cv::Scalar(255, 0, 0));
            std::cout<< *i <<std::endl;
        }
        std::cout<< "END" <<std::endl;
        if(cross_points_vector.size() != 4){
            return MatToUIImage(quad);
        }
        //矫正
        std::vector<cv::Point2f> dst;
        dst.push_back(cv::Point2f(0,600));
        dst.push_back(cv::Point2f(0,0));
        dst.push_back(cv::Point2f(600,600));
        dst.push_back(cv::Point2f(600,0));
        //todo crop截取顶点内图
        cv::Mat transmtx = cv::getPerspectiveTransform(cross_points_vector, dst);
        cv::warpPerspective(threshold_mat, threshold_mat, transmtx, crop.size());
        
        
//        cv::cvtColor(result,result,CV_GRAY2RGB);
//
//        for(auto i = maxContour.begin(); i != maxContour.end(); i++){
//            cv::circle(result, *i, 2, cv::Scalar(0, 255, 0));
//        }
//        for(auto i = secondContour.begin(); i != maxContour.end(); i++){
//            cv::circle(result, *i, 2, cv::Scalar(255, 0, 0));
//        }
      
     


        return MatToUIImage(threshold_mat);
    } else {
        return MatToUIImage(mat);
    }
    
    //cv::rectangle(result, maxRect, color);
    
    
   

}

@end
