//
//  ViewController.m
//  RTMPDemo
//
//  Created by Janven on 16/7/28.
//  Copyright © 2016年 Janven. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "AVCaptureManager.h"
#import "PublicDefine.h"
#import "AudioManager.h"
#import "rtmpManager.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[rtmpManager getInstance] startRtmpConnect:@"rtmp://192.168.5.119:1935/zbcs/room"];
    
    [[AudioManager getInstance] initRecording];

    
    if (TARGET_IPHONE_SIMULATOR) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"不支持模拟器"
                                                       delegate:nil cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }else{
        
        [[AVCaptureManager sharedInstance] initialize];
        [AVCaptureManager sharedInstance].preview_View = self.view;
    }
    
    
    UIButton *btn_switch = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn_switch setFrame:CGRectMake(SCREEN_WEIGHT/2, SCREEN_HEIGHT-100, SCREEN_WEIGHT/2, 40)];
    [btn_switch setTitle:@"切换摄像头" forState:UIControlStateNormal];
    [btn_switch setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn_switch.layer.borderWidth = 2.0f;
    [btn_switch addTarget:self action:@selector(switchTheCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn_switch];
    
    
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn setFrame:CGRectMake(0, SCREEN_HEIGHT-50, SCREEN_WEIGHT/2, 40)];
    [btn setTitle:@"开启摄像头" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn.layer.borderWidth = 2.0f;
    [btn addTarget:self action:@selector(openTheCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn];
    
    
    
    UIButton *btn_close = [UIButton buttonWithType:UIButtonTypeSystem];
    [btn_close setFrame:CGRectMake(btn.frame.size.width,btn.frame.origin.y, SCREEN_WEIGHT/2, 40)];
    [btn_close setTitle:@"关闭摄像头" forState:UIControlStateNormal];
    [btn_close setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    btn_close.layer.borderWidth = 2.0f;
    [btn_close addTarget:self action:@selector(closeTheCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn_close];
    
    
    

}

-(void)closeTheCamera{

    [[AVCaptureManager sharedInstance] stopCamera];
    [[AudioManager getInstance] pauseRecording];
}

-(void)openTheCamera{
    
    [[AVCaptureManager sharedInstance] startCamera];
    [[AudioManager getInstance] startRecording];
}


-(void)switchTheCamera{

    [[AVCaptureManager sharedInstance] switchTheCamera];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
