//
//  OpenCVWrapper.h
//  qrcode_reader
//
//  Created by 启翔 张 on 2017/11/14.
//  Copyright © 2017年 启翔 张. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>




@interface OpenCVWrapper : NSObject

+(NSString *) openCVVersionString;
+(UIImage *)processImage:(UIImage *)image;
@end
