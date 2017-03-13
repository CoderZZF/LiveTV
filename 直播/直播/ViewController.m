//
//  ViewController.m
//  直播
//
//  Created by zhangzhifu on 2017/3/13.
//  Copyright © 2017年 seemygo. All rights reserved.
//

#import "ViewController.h"
#import "VideoCapture.h"

@interface ViewController ()
@property (nonatomic, strong) VideoCapture *videoCapture;
@end

@implementation ViewController

- (VideoCapture *)videoCapture {
    if (!_videoCapture) {
        _videoCapture = [[VideoCapture alloc] init];
    }
    return _videoCapture;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)startCapture:(id)sender {
    [self.videoCapture startCapturing:self.view ];
}

- (IBAction)stopCapture:(id)sender {
    [self.videoCapture stopCapturing];
}

@end
