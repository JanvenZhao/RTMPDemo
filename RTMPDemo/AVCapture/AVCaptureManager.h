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

@property (nonatomic,strong) AVCaptureStillImageOutput *captureOutput;
@property (nonatomic,strong) UIImage *image;

@property (nonatomic,assign) UIView *preview_View;

+(AVCaptureManager *)sharedInstance;

/**
 *  初始化 主要是h264
 */
-(void)initialize;

+(void)captureStillImage;
/**
 *  开始录制
 */
- (void) startCamera;
/**
 *  停止录制
 */
- (void) stopCamera;
/**
 *  切换摄像头
 */
-(void)switchTheCamera;

@end
