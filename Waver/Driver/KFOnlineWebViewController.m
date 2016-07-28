//
//  KFOnlineWebViewController.m
//  DiSpecialDriver
//
//  Created by Joseph on 16/4/5.
//  Copyright © 2016年 huji. All rights reserved.
//

#import "KFOnlineWebViewController.h"

//#import "KefuMsgClient.h"
#import "WebViewJavascriptBridge.h"
#import "DSWebViewController.h"
//#import "KMMp3Player.h"
////#import "KMFileManaget.h"
//#import "KMRecorderTimer.h"

#import <ISCProject/KefuMsgClient.h>
#import <ISCProject/KMMp3Player.h>
#import <ISCProject/KMFileManager.h>
#import <ISCProject/KMRecorderTimer.h>


#import <NJKWebViewProgress.h>
#import <NJKWebViewProgressView.h>
@interface KFOnlineWebViewController ()<UIWebViewDelegate,DDASRKefuDegegate,KMRecorderTimerDelegate,NJKWebViewProgressDelegate>
{
    
    KefuMsgClient * kefuClient;
    NSMutableDictionary * _pidDic ;
    NSMutableDictionary * _RequestDic;
    NSString * _FileID;
    KMMp3Player * player;
    NSInteger _TimeValue;
    KMRecorderTimer * recountTimer;
    
    
    NJKWebViewProgressView *_progressView;
    NJKWebViewProgress *_progressProxy;
    
    NSInteger  _touchTime;
    
    BOOL KFisFirstStart;
    BOOL GETERRRETURN;
    BOOL GETLOCALRETURN;
    BOOL GETUPLOADRETURN;
}

@property (nonatomic, strong) UIWebView * webView;
@property WebViewJavascriptBridge* bridge;
@property (nonatomic) BOOL loaded;
@end
@implementation KFOnlineWebViewController
- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden=NO;
    
    [_progressView setProgress:0 animated:NO];
    [self.navigationController.navigationBar addSubview:_progressView];
}
-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    // Remove progress view
    // because UINavigationBar is shared with other ViewControllers
    [_progressView removeFromSuperview];
}
- (void)viewDidLoad {
    KFisFirstStart = YES;
    GETUPLOADRETURN = NO;
    GETLOCALRETURN = NO;
    GETERRRETURN = NO;
    self.loaded = NO;
    [super viewDidLoad];
    recountTimer = [[KMRecorderTimer alloc]init];
    recountTimer.delegate = self;
    player = [[KMMp3Player alloc]init];
    kefuClient = [[KefuMsgClient alloc]init];
    kefuClient.delegate = self;
    
    _progressProxy = [[NJKWebViewProgress alloc] init];
    _webView.delegate = _progressProxy;
    _progressProxy.webViewProxyDelegate = self;
    _progressProxy.progressDelegate = self;
    
    CGFloat progressBarHeight = 2.f;
    CGRect navigaitonBarBounds = self.navigationController.navigationBar.bounds;
    CGRect barFrame = CGRectMake(0, navigaitonBarBounds.size.height - progressBarHeight, navigaitonBarBounds.size.width, progressBarHeight);
    _progressView = [[NJKWebViewProgressView alloc] initWithFrame:barFrame];
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
    _progressView.progressBarView.backgroundColor = [UIColor colorWithRed:((float)((0xff8903 & 0xff0000) >> 16))/255.0 \
                                                                    green:((float)((0xff8903 & 0x00ff00) >>  8))/255.0 \
                                                                     blue:((float)((0xff8903 & 0x0000ff) >>  0))/255.0 \
                                                                    alpha:1.0];
    
    [self registBridge];
    // Do any additional setup after loading the view.
}
- (void)registBridge{
    if (_bridge) { return; }
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 64, SCREEN_WIDTH, SCREEN_HEIGHT-64)];
    
    [self.view addSubview:_webView];
    
    [WebViewJavascriptBridge enableLogging];
    
    _bridge = [WebViewJavascriptBridge bridgeForWebView:_webView webViewDelegate:_progressProxy handler:nil];
    
    
    [_bridge registerHandler:@"startRecord" handler:^(id data, WVJBResponseCallback responseCallback) {
        NSLog(@"start");

        if (GETUPLOADRETURN == NO && KFisFirstStart == NO && GETERRRETURN == NO) {
            [_bridge callHandler:@"voiceUploadFinish" data:@{@"err_num":@"5",@"err_info":@"取消上一次操作",@"id":[NSString stringWithFormat:@"%@",_FileID],@"time":[NSString stringWithFormat:@"%zd",_TimeValue]}];
        }
        
        GETUPLOADRETURN = NO;
        GETLOCALRETURN = NO;
        GETERRRETURN = NO;
        
        _TimeValue = 0;
        _touchTime = 0;
        
        NSMutableDictionary *recInfoDic = [data mutableCopy];
        [recInfoDic setObject:@1 forKey:@"newVoice"];
        [kefuClient startRecWithPid:recInfoDic];
        [recountTimer startTimer];
        _FileID = @"";
        NSLog(@"%@",data);
        
    }];
    
    [_bridge registerHandler:@"endRecord" handler:^(id data, WVJBResponseCallback responseCallback) {
//        GETUPLOADRETURN = NO;
//        GETLOCALRETURN = NO;
//        GETERRRETURN = NO;
        [self finishRecord];
    }];
    
    
    [_bridge registerHandler:@"playVoice" handler:^(id data, WVJBResponseCallback responseCallback) {
        
        NSLog(@"datadatadata::LL%@",data);
        
//        NSString * kefuClientPath = [[KMFileManaget shareManager] createFilePath];
        
        NSString * kefuClientPath = [[KMFileManager shareManager]createFilePath];
        
        NSString * keyPath = [kefuClientPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",[NSString stringWithFormat:@"%@.mp3",data[@"id"]]]];
        [player PlayWithContentFile:keyPath];
        
    }];
    
    
    [_bridge registerHandler:@"stopVoice" handler:^(id data, WVJBResponseCallback responseCallback) {
        [player stopPlaying];
    }];
    

}
- (void)isPhoneCallIN{
    [self finishRecord];
    [player stopPlaying];
    [_bridge callHandler:@"voiceLocalFinish" data:@{@"err_num":@"88",@"err_info":@"操作中断",@"id":@"",@"time":@""}];//@{@"id":@"",@"time":@"",@"err_num":@"",@"err_info":@""}];
}

//停止定时器，结束录音，避免界面卡死
- (void)finishRecord {
    [NSThread sleepForTimeInterval:0.1];
    [recountTimer stopTimer];
    [kefuClient finishSpeak];
}

#pragma mark - DDASRKefuDegegate
- (void)getStatuesWhenFinishRecord:(int)astatues errorMsg:(NSString *)errorMsg {
    [self finishRecord];
}

- (void)getFileName:(NSString *)str AndPath:(NSString *)path AndERRORNumber:(NSString *)number AndStatus:(NSInteger)astatus {
    [self finishRecord];
    
    GETLOCALRETURN = YES;
    NSLog(@"%@---------fafa------------%zd",number,astatus);
    _FileID = str;
    NSLog(@"getCopy fileName,%@,%@",str,path);
    
    [_bridge callHandler:@"voiceLocalFinish" data:@{@"id":[NSString stringWithFormat:@"%@",_FileID],@"time":[NSString stringWithFormat:@"%zd",_TimeValue],@"err_num":[NSString stringWithFormat:@"%zd",astatus],@"err_info":number} responseCallback:^(id responseData) {
        GETLOCALRETURN = YES;
        NSLog(@"%@",@"callchenggong ");
    }];
}

-(void)getErrorMsgWhenFinishTranslate:(NSString *)str withErrornum:(NSString *)number AndStatus:(NSInteger)astatus{
    GETERRRETURN = YES;
    [_bridge callHandler:@"voiceUploadFinish" data:@{@"id":_FileID,@"word":str,@"err_num":[NSString stringWithFormat:@"%zd",astatus],@"err_info":number}];
}
-(void)getFinishMsgWhenFinishTranslate:(NSString *)str withErrornum:(NSString *)number AndStatus:(NSInteger)astatus{
    GETUPLOADRETURN = YES;
    [_bridge callHandler:@"voiceUploadFinish" data:@{@"id":_FileID,@"word":str,@"err_num":[NSString stringWithFormat:@"%zd",astatus],@"err_info":number}];
    
}

- (void)TimerActionValueChange:(int)time{
    _TimeValue = time/10;
    _touchTime = time;
    if (_TimeValue<=1) {
        _TimeValue=1;
    }
    NSLog(@"------------%zd-------",_TimeValue);
    if (_TimeValue>59) {
        [self finishRecord];
        [player stopPlaying];
        
//        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"提示" message:@"说话时间过长～" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
//        [alert show];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(isPhoneCallIN) name:@"PHONECALLDDIALING" object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(isPhoneCallIN) name:@"PHONECALLCONNECTED" object:nil];
    if (self.url&&!self.loaded) {
        NSURLRequest * request = [[NSURLRequest alloc]initWithURL:self.url];
        [self.webView loadRequest:request];
        
        self.loaded = YES;
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"PHONECALLDDIALING" object:nil];
    [[NSNotificationCenter defaultCenter]removeObserver:self name:@"PHONECALLCONNECTED" object:nil];
    [_progressView removeFromSuperview];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)leftBarButtonClick{
    if (self.webView.canGoBack) {
        [self.webView goBack];
        [self isPhoneCallIN];
    }else{
        [self isPhoneCallIN];
        [self.navigationController popViewControllerAnimated:YES];
    }
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
