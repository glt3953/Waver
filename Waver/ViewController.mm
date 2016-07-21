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
#import "KefuMsgClient.h"
#import "KMFileManager.h"
#import "KMMp3Player.h"
#import "KMRecorderTimer.h"

static float percent = 0;

@interface ViewController () <KMRecorderTimerDelegate, DDASRKefuDegegate>

@property (nonatomic, strong) AVAudioRecorder *recorder;
@property (nonatomic, strong) CircleProgressView *circleProgressView;
@property (nonatomic, strong) KefuMsgClient *kefuClient;
@property (nonatomic, strong) KMMp3Player *mp3Player;
@property (nonatomic, strong) KMRecorderTimer *recountTimer;
@property (nonatomic) NSInteger timeValue;
@property (nonatomic) NSInteger touchTime;
@property (nonatomic, copy) NSDictionary *userInfoDic;

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self setupRecorder];
    
    self.view.backgroundColor = [UIColor whiteColor];
    _kefuClient = [[KefuMsgClient alloc] init];
    _kefuClient.delegate = self;
    _mp3Player = [[KMMp3Player alloc] init];
    _userInfoDic = @{@"chatInfo":@{@"businessType":@1, @"cell":@18800000004, @"cityId":@1, @"message":@"", @"mid":@"462d7806-3295-4355-a719-1c4a71e0bf7b", @"msgType":@0, @"orderId":@0, @"roleType":@3, @"skillType":@"common", @"source":@-1, @"uid":@564069099110401}, @"pid":@10001};
    _recountTimer = [[KMRecorderTimer alloc] init];
    _recountTimer.delegate = self;
    
    _circleProgressView = [[CircleProgressView alloc] initWithFrame:CGRectMake(100, 50, 100, 100)];
    [self.view addSubview:_circleProgressView];
    
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
    
    UIButton *startRecButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [startRecButton setFrame:(CGRect){20, 240 + 150, 80, 30}];
    [startRecButton setTitle:@"开始录音" forState:UIControlStateNormal];
    [startRecButton addTarget:self action:@selector(startRecButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startRecButton];
    
    UIButton *stopRecButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [stopRecButton setFrame:(CGRect){150, 240 + 150, 80, 30}];
    [stopRecButton setTitle:@"结束录音" forState:UIControlStateNormal];
    [stopRecButton addTarget:self action:@selector(stopRecButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopRecButton];
    
    UIButton *playRecButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [playRecButton setFrame:(CGRect){20, 240 + 200, 80, 30}];
    [playRecButton setTitle:@"播放录音" forState:UIControlStateNormal];
    [playRecButton addTarget:self action:@selector(playRecButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playRecButton];
    
    UIButton *stopPlayButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [stopPlayButton setFrame:(CGRect){150, 240 + 200, 80, 30}];
    [stopPlayButton setTitle:@"停止播放" forState:UIControlStateNormal];
    [stopPlayButton addTarget:self action:@selector(stopPlayButtonDidClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:stopPlayButton];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    do {
        [_circleProgressView setPercent:percent animated:YES];
        percent += 0.1;
    } while (percent<=100);
    percent = 0;
}

- (IBAction)startRecButtonDidClick:(id)sender {
    _timeValue = 0;
    _touchTime = 0;
    
    [_kefuClient startRecWithPid:_userInfoDic];
    [_recountTimer startTimer];
}

- (IBAction)stopRecButtonDidClick:(id)sender {
    [NSThread sleepForTimeInterval:0.1];
    [_recountTimer stopTimer];
    [_kefuClient finishSpeak];
}

- (IBAction)playRecButtonDidClick:(id)sender {
    NSString *kefuClientPath = [[KMFileManager shareManager] createFilePath];
    
    NSString *keyPath = [kefuClientPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",[NSString stringWithFormat:@"%@.mp3", _userInfoDic[@"id"]]]];
    [_mp3Player PlayWithContentFile:keyPath];
}

- (IBAction)stopPlayButtonDidClick:(id)sender {
    [_mp3Player stopPlaying];
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

#pragma -mark KMRecorderTimerDelegate
- (void)TimerActionValueChange:(int)time {
    _timeValue = time / 10;
    _touchTime = time;
    if (_timeValue <= 1) {
        _timeValue = 1;
    }
    NSLog(@"------------%zd-------", _timeValue);
    if (_timeValue > 9) {
        [_kefuClient finishSpeak];
        [_mp3Player stopPlaying];
        [_recountTimer stopTimer];
        
        //        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"说话时间过长～" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        //        [alert show];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
