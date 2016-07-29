//
//  AVCaptureManager.m
//  InterFace
//
//  Created by Janven Zhao on 14-9-22.
//  Copyright (c) 2014年 Janven Zhao. All rights reserved.
//

#import "AVCaptureManager.h"
#import <ImageIO/ImageIO.h>

#import "AVCapturePreview.h"

@interface AVCaptureManager ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>{
    
    //视频采集
    
    dispatch_queue_t    _videoQueue;
    
    AVCaptureVideoDataOutput *_videoOutput;
    
    AVCaptureConnection *_videoConnection;
    
    //音频采集
    dispatch_queue_t    _audioQueue;
    AVCaptureAudioDataOutput *_audioOutput;
    AVCaptureConnection *_audioConnection;
    
}
@end

@implementation AVCaptureManager

+(AVCaptureManager *)sharedInstance{
    static AVCaptureManager *manager = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        manager = [[AVCaptureManager alloc] init];
    });
    return manager;
}

/*
 初始化
 **/

-(id)init{
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

-(void)initialize{

    NSError *error = nil;
    
    self.session = [[AVCaptureSession     alloc] init];
    self.session.sessionPreset = AVCaptureSessionPreset640x480;
    
    //视频 捕获设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //输入
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput   deviceInputWithDevice:device error:&error];
    
    if (error) {
        NSLog(@"Error happens when you try to get AVCaptureDeviceInput");
    }
    
    if ([self.session canAddInput:input]) {
        [self.session addInput:input];
    }
    
    /*    截屏使用
    self.captureOutput = [[AVCaptureStillImageOutput alloc] init];
    
    NSDictionary *setting = @{AVVideoCodecKey:AVVideoCodecJPEG};
    
    self.captureOutput.outputSettings = setting;
    
    if ([self.session canAddOutput:self.captureOutput]) {
        [self.session addOutput:self.captureOutput];
    }
    */
    
    // 配置采集输出，即我们取得视频图像的接口
    _videoQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
    
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoOutput setSampleBufferDelegate:self queue:_videoQueue];
    
    // 配置输出视频图像格式
    NSDictionary *captureSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    
    _videoOutput.videoSettings = captureSettings;
    _videoOutput.alwaysDiscardsLateVideoFrames = YES;
    
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];  // 添加到Session
    }
    
    // 保存Connection，用于在SampleBufferDelegate中判断数据来源（是Video/Audio？）
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
    
    //音频采集
    
    //音频 捕获设备
    AVCaptureDevice *audio_device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    //输入
    AVCaptureDeviceInput *audio_input = [AVCaptureDeviceInput   deviceInputWithDevice:audio_device error:&error];
    
    if (error) {
        NSLog(@"Error happens when you try to get AVCaptureDeviceInput");
    }
    
    if ([self.session canAddInput:audio_input]) {
        [self.session addInput:audio_input];
    }
    

    
    
    _audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
    
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioOutput setSampleBufferDelegate:self queue:_audioQueue];
    
    
    if ([_session canAddOutput:_audioOutput]) {
        [_session addOutput:_audioOutput];  // 添加到Session
    }
    
    // 保存Connection，用于在SampleBufferDelegate中判断数据来源
    _audioConnection = [_audioOutput connectionWithMediaType:AVMediaTypeAudio];
}

//捕获照片
-(void)captureImage{
    
    //捕获连接
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.captureOutput.connections) {
        for (AVCaptureInputPort *port in connection.inputPorts) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                videoConnection = connection;
                break;
            }
        }
        
        if (videoConnection) {
            break;
        }
    }
    
    //捕获图片
    [self.captureOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer,NSError *error){
        CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, nil);
        if (exifAttachments) {
            //Do something with the attachments
        }
        
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
        self.image = [[UIImage alloc] initWithData:imageData];
        
    }];
}

-(void)embedPreviewInView:(UIView *)aView{

    if (!self.session) {
        return;
    }

    CGRect frame = CGRectMake(0, 0, aView.frame.size.width, aView.frame.size.height);
    self.preview= [[AVCapturePreview alloc] initWithFrame:frame];
    [self.preview setSession:self.session];
    [aView addSubview:self.preview];
    
}

#pragma mark
#pragma mark Open InterFace

+(void)startRunning{

    [[[AVCaptureManager sharedInstance] session] startRunning];

}

+(void)stopRunning{
    [[[AVCaptureManager sharedInstance] session] stopRunning];
}

+(void)captureStillImage{

    [[AVCaptureManager   sharedInstance] captureImage];
}

+(UIImage *)image{

    return [[AVCaptureManager sharedInstance] image];
}


+(AVCapturePreview *)preView{
    return [self preView];
}

- (void) captureOutput:(AVCaptureOutput *)captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
    // 这里的sampleBuffer就是采集到的数据了，但它是Video还是Audio的数据，得根据connection来判断
    if (connection == _videoConnection) {  // Video
        
         // 取得当前视频尺寸信息
         CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
         int width = CVPixelBufferGetWidth(pixelBuffer);
         int height = CVPixelBufferGetHeight(pixelBuffer);
         NSLog(@"video width: %d  height: %d", width, height);
         
        NSLog(@"在这里获得video sampleBuffer，做进一步处理（编码H.264）");
        
    } else if (connection == _audioConnection) {
        // Audio
        NSLog(@"这里获得audio sampleBuffer，做进一步处理（编码AAC）");
        
        
    }
}


-(void)checkTheAVAuthorizationStatus:(NSString * const)media_Type{

    if([[UIDevice currentDevice].systemVersion floatValue]>= 7.0) {
        
        NSString *mediaType = media_Type;// Or AVMediaTypeAudio
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
        NSLog(@"---cui--authStatus--------%d",authStatus);
        // This status is normally not visible—the AVCaptureDevice class methods for discovering devices do not return devices the user is restricted from accessing.
        
        if(authStatus ==AVAuthorizationStatusRestricted){
            NSLog(@"Restricted");
        }else if(authStatus == AVAuthorizationStatusDenied){
            // The user has explicitly denied permission for media capture.
            NSLog(@"Denied");     //应该是这个，如果不允许的话
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                            message:@"请在设备的\"设置-隐私-相机\"中允许访问相机。"
                                                           delegate:self
                                                  cancelButtonTitle:@"确定"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
        else if(authStatus == AVAuthorizationStatusAuthorized){//允许访问
            // The user has explicitly granted permission for media capture, or explicit user permission is not necessary for the media type in question.
            NSLog(@"Authorized");
            
        }else if(authStatus == AVAuthorizationStatusNotDetermined){
            // Explicit user permission is required for media capture, but the user has not yet granted or denied such permission.
            [AVCaptureDevice requestAccessForMediaType:mediaType completionHandler:^(BOOL granted) {
                if(granted){//点击允许访问时调用
                    //用户明确许可与否，媒体需要捕获，但用户尚未授予或拒绝许可。
                    NSLog(@"Granted access to %@", mediaType);
                }
                else {
                    NSLog(@"Not granted access to %@", mediaType);
                }
                
            }];
        }else {
            NSLog(@"Unknown authorization status");
        }
    }
    
}


@end
