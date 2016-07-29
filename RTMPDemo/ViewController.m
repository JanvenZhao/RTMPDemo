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

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    if (TARGET_IPHONE_SIMULATOR) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                        message:@"不支持模拟器"
                                                       delegate:nil cancelButtonTitle:@"确定"
                                              otherButtonTitles:nil, nil];
        [alert show];
    }else{
        //[self initInput];
        [AVCaptureManager startRunning];
        [[AVCaptureManager sharedInstance] embedPreviewInView:self.view];
    }

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
