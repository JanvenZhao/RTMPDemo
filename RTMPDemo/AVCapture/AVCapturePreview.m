//
//  AVCapturePreview.m
//  InterFace
//
//  Created by Janven Zhao on 14-9-22.
//  Copyright (c) 2014年 Janven Zhao. All rights reserved.
//

#import "AVCapturePreview.h"
#import <AVFoundation/AVFoundation.h>

@implementation AVCapturePreview
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

-(id)init{

    if (self = [super init]) {
        NSLog(@"PreView init");
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame{

    if (self = [super initWithFrame:frame]) {
        NSLog(@"PreView init");
        
        [self setttingTheTopView];
        [self setttingTheBottomView];
    }
    return self;
}

#pragma mark
#pragma mark UI-----LayOut

-(void)setttingTheTopView{
    

}

-(void)setttingTheBottomView{

    
}

#pragma mark
#pragma mark Setting----

+ (Class)layerClass
{
    return [AVCaptureVideoPreviewLayer class];
}

- (AVCaptureSession *)session
{
    return [(AVCaptureVideoPreviewLayer *)[self layer] session];
}

- (void)setSession:(AVCaptureSession *)session
{
    [(AVCaptureVideoPreviewLayer *)[self layer] setSession:session];
    
    [self setViedoGravity:AVLayerVideoGravityResizeAspectFill];
}

-(void)setViedoGravity:(NSString *)_options{
    /*
     Options are AVLayerVideoGravityResize, AVLayerVideoGravityResizeAspect
     and AVLayerVideoGravityResizeAspectFill. AVLayerVideoGravityResizeAspect is default.
     See <AVFoundation/AVAnimation.h> for a description of these options.
     */
    [(AVCaptureVideoPreviewLayer *)[self layer] setVideoGravity:_options];
}


@end
