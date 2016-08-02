//
//  AVCaptureManager.m
//  InterFace
//
//  Created by Janven Zhao on 14-9-22.
//  Copyright (c) 2014年 Janven Zhao. All rights reserved.
//

#import "AVCaptureManager.h"
#import <ImageIO/ImageIO.h>
#import <AudioToolbox/AudioToolbox.h>
#import "H264HwEncoderImpl.h"
#import "H264HwDecoderImpl.h"
#import "AAPLEAGLLayer.h"
#import "config.h"
#import "PublicDefine.h"

@interface AVCaptureManager ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,H264HwEncoderImplDelegate,H264HwDecoderImplDelegate>{
    
    //后置
    AVCaptureDevice *cameraDeviceB;
    //前置
    AVCaptureDevice *cameraDeviceF;
    
    BOOL cameraDeviceIsF;
    
    
    AVCaptureSession *_session;
    
    //视频采集
    dispatch_queue_t    _videoQueue;
    AVCaptureVideoDataOutput *_videoOutput;
    AVCaptureConnection *_videoConnection;
    
    //音频采集
    dispatch_queue_t    _audioQueue;
    AVCaptureAudioDataOutput *_audioOutput;
    AVCaptureConnection *_audioConnection;
 
    //h264编码
    H264HwEncoderImpl *h264Encoder;
    //h264解码
    H264HwDecoderImpl *h264Decoder;
    
    //采集摄像头显示
    AVCaptureVideoPreviewLayer *recordLayer;
    //解码展示
    AAPLEAGLLayer *playLayer;

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
        
    }
    return self;
}

-(void)initialize{

    cameraDeviceIsF = NO;
    
    NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in videoDevices) {
        if (device.position == AVCaptureDevicePositionFront) {
            cameraDeviceF = device;
        }
        else if(device.position == AVCaptureDevicePositionBack)
        {
            cameraDeviceB = device;
        }
    }


    [self initH264];

    playLayer = [[AAPLEAGLLayer alloc] initWithFrame:CGRectMake(180, 20, 160,300)];
    playLayer.backgroundColor = [UIColor blackColor].CGColor;
    
    
    [self cofigTheCamera:cameraDeviceIsF];
}




-(void)cofigTheCamera:(BOOL)type{

    
    NSError *error = nil;

    NSError *deviceError;
    AVCaptureDeviceInput *inputCameraDevice;
    if (type==false)
    {
        inputCameraDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDeviceB error:&deviceError];
    }
    else
    {
        inputCameraDevice = [AVCaptureDeviceInput deviceInputWithDevice:cameraDeviceF error:&deviceError];
    }

    
    /*截屏使用
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
    NSString* key = (NSString*)kCVPixelBufferPixelFormatTypeKey;
    NSNumber* val = [NSNumber numberWithUnsignedInt:kCVPixelFormatType_420YpCbCr8BiPlanarFullRange];
    NSDictionary* videoSettings = [NSDictionary dictionaryWithObject:val forKey:key];
    
    _videoOutput.videoSettings = videoSettings;
    
    _session = [[AVCaptureSession     alloc] init];
    
    if ([_session canAddInput:inputCameraDevice]) {
        [_session addInput:inputCameraDevice];
    }
    
    if ([_session canAddOutput:_videoOutput]) {
        [_session addOutput:_videoOutput];
    }
    
    
    //音频采集
    
     //音频 捕获设备
     AVCaptureDevice *audio_device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
     //输入
     AVCaptureDeviceInput *audio_input = [AVCaptureDeviceInput   deviceInputWithDevice:audio_device error:&error];
     
     if (error) {
     NSLog(@"Error happens when you try to get AVCaptureDeviceInput");
     }
     
     if ([_session canAddInput:audio_input]) {
     [_session addInput:audio_input];
     }
     
     
     
     _audioQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
     
     _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
     [_audioOutput setSampleBufferDelegate:self queue:_audioQueue];
     
     
     if ([_session canAddOutput:_audioOutput]) {
     [_session addOutput:_audioOutput];  // 添加到Session
     }
    
    
    [_session beginConfiguration];
    // 保存Connection，用于在SampleBufferDelegate中判断数据来源
    _session.sessionPreset = AVCaptureSessionPreset1280x720;
    // 保存Connection，用于在SampleBufferDelegate中判断数据来源（是Video/Audio？）
    _videoConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
     _audioConnection = [_audioOutput connectionWithMediaType:AVMediaTypeAudio];
    
    //!!!
    [self setRelativeVideoOrientation];
    
    [_session commitConfiguration];
    
    
    recordLayer = [AVCaptureVideoPreviewLayer    layerWithSession:_session];
    [recordLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    

}


-(void)initH264{

    h264Encoder = [H264HwEncoderImpl alloc];
    [h264Encoder initWithConfiguration];
    [h264Encoder initEncode:h264outputWidth height:h264outputHeight];
    h264Encoder.delegate = self;
    
    h264Decoder = [[H264HwDecoderImpl alloc] init];
    h264Decoder.delegate = self;
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


- (void) startCamera{
    
    if (_session.isRunning) {
        return;
    }
    
    recordLayer = [AVCaptureVideoPreviewLayer    layerWithSession:_session];
    [recordLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    recordLayer.frame = CGRectMake(0, 20, 160, 300);
    [self.preview_View.layer addSublayer:recordLayer];
    [_session startRunning];
    [self.preview_View.layer addSublayer:playLayer];
    
}
- (void) stopCamera
{
    if (_session.isRunning) {
        [_session stopRunning];
        [recordLayer removeFromSuperlayer];
        [playLayer removeFromSuperlayer];
    }
}

-(void)switchTheCamera{

    if (_session.isRunning==YES)
    {
        cameraDeviceIsF = !cameraDeviceIsF;
        [self stopCamera];
        [self cofigTheCamera:cameraDeviceIsF];
        [self startCamera];

    }
}

#pragma mark
#pragma mark Open InterFace


+(void)captureStillImage{

    [[AVCaptureManager   sharedInstance] captureImage];
}


#pragma mark - 音视频采集回调

- (void) captureOutput:(AVCaptureOutput *)captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
    // 这里的sampleBuffer就是采集到的数据了，但它是Video还是Audio的数据，得根据connection来判断
    if (connection == _videoConnection) {  // Video
        
        //NSLog(@"在这里获得video sampleBuffer，做进一步处理（编码H.264）");
        [h264Encoder encode:sampleBuffer];

        
    } else if (connection == _audioConnection) {
        // Audio
        //NSLog(@"这里获得audio sampleBuffer，做进一步处理（编码AAC）");
        
        
    }
}

/*
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
*/


#pragma mark -  H264编码回调  H264HwEncoderImplDelegate
- (void)gotSpsPps:(NSData*)sps pps:(NSData*)pps
{
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    //发sps
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:sps];
    [h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
    //发pps
    [h264Data resetBytesInRange:NSMakeRange(0, [h264Data length])];
    [h264Data setLength:0];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:pps];
    //解码
    [h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
}

- (void)gotEncodedData:(NSData*)data isKeyFrame:(BOOL)isKeyFrame
{
    const char bytes[] = "\x00\x00\x00\x01";
    size_t length = (sizeof bytes) - 1;
    NSData *ByteHeader = [NSData dataWithBytes:bytes length:length];
    NSMutableData *h264Data = [[NSMutableData alloc] init];
    [h264Data appendData:ByteHeader];
    [h264Data appendData:data];
    [h264Decoder decodeNalu:(uint8_t *)[h264Data bytes] withSize:(uint32_t)h264Data.length];
}

#pragma mark -  H264解码回调  H264HwDecoderImplDelegate delegare
- (void)displayDecodedFrame:(CVImageBufferRef )imageBuffer
{
    if(imageBuffer)
    {
        playLayer.pixelBuffer = imageBuffer;
        CVPixelBufferRelease(imageBuffer);
    }
}


#pragma mark -  方向设置

#if TARGET_OS_IPHONE

- (void)statusBarOrientationDidChange:(NSNotification*)notification {
    [self setRelativeVideoOrientation];
}

- (void)setRelativeVideoOrientation {
    switch ([[UIDevice currentDevice] orientation]) {
        case UIInterfaceOrientationPortrait:
#if defined(__IPHONE_8_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_8_0
        case UIInterfaceOrientationUnknown:
#endif
            recordLayer.connection.videoOrientation = AVCaptureVideoOrientationPortrait;
            _videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            recordLayer.connection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            _videoConnection.videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            recordLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            _videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
            break;
        case UIInterfaceOrientationLandscapeRight:
            recordLayer.connection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            _videoConnection.videoOrientation = AVCaptureVideoOrientationLandscapeRight;
            break;
        default:
            break;
    }
}
#endif
@end
