//
//  ViewController.m
//  Waver
//
//  Created by kevinzhow on 14/12/14.
//  Copyright (c) 2014年 Catch Inc. All rights reserved.
//

#import "ViewController.h"
#import "WaverView.h"
#import <AVFoundation/AVFoundation.h>
#import "CircleProgressView.h"

static float percent = 0;

@interface ViewController ()

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) CircleProgressView *circleProgressView;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setupRecorder];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    WaverView *waverView = [[WaverView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds)/2.0 - 50.0, CGRectGetWidth(self.view.bounds), 100.0)];
    //定制
    waverView.numberOfWaves = 4;
    __block AVAudioRecorder *weakRecorder = self.recorder;
    waverView.waverLevelCallback = ^(WaverView *waverView) {
        [weakRecorder updateMeters];
        //double pow (double base, double exponent);求base的exponent次方值
        CGFloat normalizedValue = pow(10, [weakRecorder averagePowerForChannel:0] / 40);
        waverView.level = normalizedValue;
    };
    [self.view addSubview:waverView];
    // Do any additional setup after loading the view, typically from a nib.
    
    _circleProgressView = [[CircleProgressView alloc]initWithFrame:CGRectMake(100, 50, 100, 100)];
    [self.view addSubview:_circleProgressView];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    do {
        [_circleProgressView setPercent:percent animated:YES];
        percent += 0.1;
    } while (percent<=100);
    percent = 0;
}

- (void)setupRecorder  {
    NSURL *url = [NSURL fileURLWithPath:@"/dev/null"];
    
    NSDictionary *settings = @{AVSampleRateKey:          [NSNumber numberWithFloat:44100.0],
                               AVFormatIDKey:            [NSNumber numberWithInt:kAudioFormatAppleLossless],
                               AVNumberOfChannelsKey:    [NSNumber numberWithInt:2],
                               AVEncoderAudioQualityKey: [NSNumber numberWithInt:AVAudioQualityMin]};
    
    NSError *error;
    self.recorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:&error];
    
    if(error) {
        NSLog(@"Ups, could not create recorder %@", error);
        return;
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
    
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
    }
    
    [self.recorder prepareToRecord];
    [self.recorder setMeteringEnabled:YES];
    [self.recorder record];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
