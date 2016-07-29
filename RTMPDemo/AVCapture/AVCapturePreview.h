//
//  AVCapturePreview.h
//  InterFace
//
//  Created by Janven Zhao on 14-9-22.
//  Copyright (c) 2014年 Janven Zhao. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVCaptureSession;
@interface AVCapturePreview : UIView

@property (nonatomic) AVCaptureSession *session;
@end
