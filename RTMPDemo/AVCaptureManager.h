//
//  AVCaptureManager.h
//  InterFace
//
//  Created by Janven Zhao on 14-9-22.
//  Copyright (c) 2014年 Janven Zhao. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
@class AVCapturePreview;
@interface AVCaptureManager : NSObject

@property (nonatomic,strong) AVCaptureSession *session;
@property (nonatomic,strong) AVCaptureStillImageOutput *captureOutput;
@property (nonatomic,strong) UIImage *image;
@property (nonatomic,strong) AVCapturePreview   *preview;

+(AVCaptureManager *)sharedInstance;

+(void)startRunning;

+(void)stopRunning;

+(void)captureStillImage;

+(UIImage *)image;

+(AVCapturePreview *)preView;

-(void)embedPreviewInView:(UIView *)aView;

@end
