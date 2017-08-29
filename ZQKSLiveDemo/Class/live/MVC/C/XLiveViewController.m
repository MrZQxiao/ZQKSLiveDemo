//
//  CLiveViewController.m
//  ZQKSLiveDemo
//
//  Created by 肖兆强 on 2017/8/28.
//  Copyright © 2017年 BTV. All rights reserved.
//

#import "XLiveViewController.h"
#import "Masonry.h"
#import "MTBlockAlertView.h"
#import "MBProgressHUD.h"
#import "UIButton+Init.h"
#import "UIViewExt.h"
#import "UINavigationController+Autorotate.h"
#import "UIColor+HEX.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import <objc/runtime.h>
#import <AudioToolbox/AudioToolbox.h> //声音提示
#import "LivePrefixHeader.pch"
#import "StatusBarTool+JWZT.h"
#import <GPUImage/GPUImage.h>
#import <libksygpulive/libksygpulive.h>
#import <libksygpulive/KSYGPUPipStreamerKit.h>
#import "Set.h"





#define  menuSpace   (kScreen_width - 120 - 55 *4) /3.0
#define  menuTop     (100 - 55) /2.0
#define  menuButtonWidth 55
struct config_s {
    CGSize videosize;
//    LIVE_BITRATE vBitRate;
//    LIVE_FRAMERATE fps;
    BOOL voice;
    AVCaptureDevicePosition videoposition;
    
};
@interface XLiveViewController ()<setDelegate>




{
    
    UIView *_bgView;
    /**
     *RIGHT
     */
    UIButton *_reportButton; //直播
    UIButton *_screenshotsButton;//截屏
    UIButton *_setButton; //设置
    
    /**
     *LEFT
     */
    UIView *_leftView;
    UIView *_LeftBGView;//左侧背景
    UIButton *_backButton;//返回按钮
    UIButton *_cameraButton; //摄像头
    UIButton *_torchButton; //闪光灯
    UIButton *_micSwitcButton; //声音
    UIButton *_beautiyButton; //美颜
    
    
    /**
     *TOP
     */

    UIView *_topView;
    UIView *_topBGView;//顶部背景图
    UIImageView *_netImage;//网络状态图片
    UIImageView *_redPoint;//红点
    
    NSTimer *_timer;//
    UILabel *_timelabel;//时间显示
    int _timeNum;//时间值
    UIImageView *_batteryImage;//电量
    
    //码流显示
    UILabel *_streamTitleLable;
    UILabel *_streamValueLable;
    
    //流量显示
    UILabel *_trafficTitleLable;
    UILabel *_trafficValueLable;
    
    
    
    /**
     *beauty
     */
    UIView *_beautySettingView;
    
    UIView *_beautySettingBGView;//底部背景
    
    UILabel *_beautyLabel;//美颜
    UILabel *_beautyValue;
    UILabel *_brightLabel;//亮度
    UILabel *_brightValue;
    UISlider *_beautySlider;//美颜
    UISlider *_brightSlider;//亮度
    
    
   



    //    直播是否开始
    BOOL _isBegin;


    //    设置删除
    UIButton *_deleSet;


    
    
}





/**
 美颜设置
 */
@property (nonatomic, strong)KSYBeautifyFaceFilter *filter;


/**
 直播基类
 */
@property (nonatomic,strong)KSYGPUStreamerKit *pipKit;



/**
 当前总流量
 */
@property (nonatomic,assign)CGFloat dataFlow;


/**
 设置是否变化
 */
@property (nonatomic,assign)BOOL settingIsChanged;



/**
 记录上一次美颜值
 */
@property (nonatomic,assign)CGFloat lastBeautyValue;


/**
 记录上一次亮度值
 */
@property (nonatomic,assign)CGFloat lastBrightValue;



/**
 网络监察定时器
 */
@property (nonatomic,strong)NSTimer *checkTimer;


@end

@implementation XLiveViewController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    
    [self layout];
    [self initNotification];
    [self layoutPreviewBgView];


    [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
 }

//隐藏statusBar
-(BOOL)prefersStatusBarHidden
{
    return YES;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
}
- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
//    [AppDelegate shareAppDelegate].allowRotation = NO;
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];


}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [MBProgressHUD hideHUDForView:self.view animated:YES];
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}
-(void)initNotification{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(WillDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillEnterForegroundNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
    // 接受屏幕改变的通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkBattery) name:UIDeviceBatteryLevelDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onStreamStateChange:) name:KSYStreamStateDidChangeNotification object:nil];
    


}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self requestAccessForVideo];
    [self requestAccessForAudio];
    [self requestAccessForPhoto];
    

    _isBegin = NO; //开始为未直播状态

   
    _bgView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_bgView];


    
    _checkTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(checkStatusBar) userInfo:nil repeats:YES];
    
    [_checkTimer setFireDate:[NSDate distantPast]];
    
    //
    [self RtmpInit];

    [self initRightMenuButton];
    [self initLeftMenuButton];
    [self initTopMenubutton];
    [self initBeautyMenuButton];
    
}

- (void)layoutPreviewBgView{
    // size
    CGFloat minLength = MIN(_bgView.frame.size.width, _bgView.frame.size.height);
    CGFloat maxLength = MAX(_bgView.frame.size.width, _bgView.frame.size.height);
    CGRect newFrame;
    // frame
    CGAffineTransform newTransform;
    
    UIInterfaceOrientation currentInterfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if (currentInterfaceOrientation == UIInterfaceOrientationPortrait) {
        newTransform = CGAffineTransformIdentity;
        newFrame = CGRectMake(0, 0, minLength, maxLength);
    } else {
        newTransform = CGAffineTransformMakeRotation(M_PI_2*(currentInterfaceOrientation == UIInterfaceOrientationLandscapeLeft ? 1 : -1));
        newFrame = CGRectMake(0, 0, maxLength, minLength);
    }
    
    _bgView.transform = newTransform;
    _bgView.frame = newFrame;
}







#pragma mark --pipkit
-(void) RtmpInit{
   

    
    _filter = [[KSYBeautifyFaceFilter alloc] init];
    
    if (_pipKit == nil) {
        _pipKit = [[KSYGPUStreamerKit alloc] initWithDefaultCfg];
    }
    
    if (_setting) {
           CGSize videoSize;
        if ([_setting.videoSize isEqualToString:@"640*360"]) {
            videoSize = CGSizeMake(640, 360);
        }else if ([_setting.videoSize isEqualToString:@"960*540"])
        {
            videoSize = CGSizeMake(960, 540);
  
        }else
        {
            videoSize = CGSizeMake(1280, 720);

        }

        _pipKit.previewDimension = videoSize;
        _pipKit.streamDimension = videoSize;
        _pipKit.videoFPS         = _setting.FPS;
        _pipKit.aCapDev.micVolume = _setting.micVolume/100;
        _pipKit.streamerBase.videoInitBitrate = _setting.Bitrate;
        _pipKit.streamerBase.videoMaxBitrate  = _setting.Bitrate *1.5;
        
        _pipKit.streamerBase.videoMinBitrate  = _setting.Bitrate *0.5; //
    }
    
    
    _pipKit.cameraPosition = AVCaptureDevicePositionBack;
    _pipKit.capPreset = AVCaptureSessionPresetiFrame960x540;
    _pipKit.streamerBase.videoCodec=KSYVideoCodec_AUTO;
   
    [_pipKit setupFilter: _filter];
    
    [_pipKit startPreview:_bgView];



}










#pragma mark -- 请求权限
- (void)requestAccessForVideo {

    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                    });
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            // 已经开启授权，可继续
            dispatch_async(dispatch_get_main_queue(), ^{
            });
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            // 用户明确地拒绝授权，或者相机设备无法访问
            
            break;
        default:
            break;
    }
}

- (void)requestAccessForAudio {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted:
            break;
        default:
            break;
    }
}


- (void)requestAccessForPhoto
{
    PHAuthorizationStatus authStatus = [PHPhotoLibrary authorizationStatus];
    switch (authStatus) {
        case PHAuthorizationStatusNotDetermined:
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            }];
            break;
            //无法授权
        case PHAuthorizationStatusRestricted:
            
            break;
            //明确拒绝
        case PHAuthorizationStatusDenied:
            
            break;
            
            //已授权
        case PHAuthorizationStatusAuthorized:
            
            break;
            
        default:
            break;
    }
}


#pragma mark  --初始化UI
- (void)initLeftMenuButton
{
    //   背景
    _leftView = [[UIView alloc] init];
    [self.view addSubview:_leftView];
    
    _LeftBGView = [[UIView alloc] init];
    _LeftBGView.backgroundColor = [UIColor whiteColor];
    _LeftBGView.alpha = .5;
    [_leftView addSubview:_LeftBGView];
    
    
    //    返回按钮
    _backButton = [UIButton buttonWithnormalImg:[UIImage imageNamed:LiveImageName(@"return")] highlightedImg:[UIImage imageNamed:LiveImageName(@"return")]  selector:@selector(topAction:) target:self];
    
    [self.view addSubview:_backButton];
    
    
    
    //    摄像头
    _cameraButton = [UIButton buttonWithnormalImg:[UIImage imageNamed:LiveImageName(@"shot-change")]  highlightedImg:[UIImage imageNamed:LiveImageName(@"shot-change")] selector:@selector(cameraButton:) target:self];
    [_leftView addSubview:_cameraButton];
    
    //    闪光灯
    _torchButton = [UIButton buttonWithnormalImg:[UIImage imageNamed:LiveImageName(@"lamp-closed")] selectedImg:[UIImage imageNamed:LiveImageName(@"lamp-open")] selector:@selector(MenuAction:) target:self];
    _torchButton.tag = 101;
    [_leftView addSubview:_torchButton];
    
    //   声音
    _micSwitcButton = [UIButton buttonWithnormalImg:[UIImage imageNamed:LiveImageName(@"voice-open")] selectedImg:[UIImage imageNamed:LiveImageName(@"voice-closed")] selector:@selector(MenuAction:) target:self];
    _micSwitcButton.tag = 102;
    [_leftView addSubview:_micSwitcButton];
    
    //    美颜
    _beautiyButton = [UIButton buttonWithnormalImg:[UIImage imageNamed:LiveImageName(@"meiyan-open")] selectedImg:[UIImage imageNamed:LiveImageName(@"meiyan-closed")] selector:@selector(MenuAction:) target:self];
    _beautiyButton.tag = 103;
    [_leftView addSubview:_beautiyButton];
    
    

}


- (void)initRightMenuButton
{
    
    //截屏
    _screenshotsButton = [UIButton buttonWithnormalImg:[UIImage imageNamed:LiveImageName(@"photo")] selectedImg:[UIImage imageNamed:LiveImageName(@"photo")] selector:@selector(screenshotsButtonClick) target:self];
    [_screenshotsButton setBackgroundImage:[UIImage imageNamed:LiveImageName(@"photo-round")] forState:UIControlStateNormal];
    [self.view addSubview:_screenshotsButton];
    
    
    //    直播开始
    _reportButton = [UIButton buttonWithnormalImg:[UIImage imageNamed:LiveImageName(@"camera")] selectedImg:[UIImage imageNamed:LiveImageName(@"camera-living")] selector:@selector(reportAction:) target:self];
    [_reportButton setBackgroundImage:[UIImage imageNamed:LiveImageName(@"cemera-round")] forState:UIControlStateNormal];
    _reportButton.selected = NO;
    //    开始直播有延迟。  避开这个之间的延迟时间
    _reportButton.enabled = NO;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        _reportButton.enabled = YES;
    });
    [self.view addSubview:_reportButton];
    
    
    //设置
    _setButton = [UIButton buttonWithnormalImg:[UIImage imageNamed:LiveImageName(@"set")] selectedImg:[UIImage imageNamed:LiveImageName(@"set")] selector:@selector(MenuAction:) target:self];
    [_setButton setBackgroundImage:[UIImage imageNamed:LiveImageName(@"set-round")] forState:UIControlStateNormal];

    _setButton.tag = 104;
    [self.view addSubview:_setButton];
    
}


- (void)initTopMenubutton {
    
    
    
    //顶部背景图
    
    _topView = [[UIView alloc] init];
    [self.view addSubview:_topView];
    
    
    _topBGView = [[UIView alloc] init];
    _topBGView.backgroundColor = [UIColor whiteColor];
    _topBGView.alpha = .5;
    [self.view addSubview:_topBGView];
    
    //网络状态图片
    _netImage = [[UIImageView alloc] init];
    _netImage.image = [UIImage imageNamed:LiveImageName(@"net")];
    [self.view addSubview:_netImage];
    
    

    //网络状态图片
    _redPoint = [[UIImageView alloc] init];
    _redPoint.image = [UIImage imageNamed:LiveImageName(@"count")];
    [self.view addSubview:_redPoint];

    

    //        定时器
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timeAction) userInfo:nil repeats:YES];
    [_timer setFireDate:[NSDate distantFuture]];
    
//        时间显示
        _timelabel =[[UILabel alloc] init];
        _timelabel.text = @"00:00:00";
        _timelabel.textAlignment = NSTextAlignmentCenter;
        _timelabel.textColor = [UIColor whiteColor];
        _timelabel.font = [UIFont systemFontOfSize:14];
        [self.view addSubview:_timelabel];

    //电量
    _batteryImage = [[UIImageView alloc] init];
    _batteryImage.image = [UIImage imageNamed:LiveImageName(@"100-ttery")];
    [self checkBattery];
    [self.view addSubview:_batteryImage];

    
    
    //码流显示
    _streamTitleLable =[[UILabel alloc] init];
    _streamTitleLable.text = @"实时码流";
    _streamTitleLable.textAlignment = NSTextAlignmentLeft;
    _streamTitleLable.textColor = [UIColor colorWithHexString:@"#dddce3"];
    _streamTitleLable.font = [UIFont systemFontOfSize:14];
    [_topView addSubview:_streamTitleLable];

    
    _streamValueLable =[[UILabel alloc] init];
    _streamValueLable.text = @"";
    _streamValueLable.textAlignment = NSTextAlignmentCenter;
    _streamValueLable.textColor = [UIColor colorWithHexString:@"#fd0303"];
    _streamValueLable.font = [UIFont systemFontOfSize:14];
    [_topView addSubview:_streamValueLable];

    //流量显示
    _trafficTitleLable =[[UILabel alloc] init];
    _trafficTitleLable.text = @"总流量";
    _trafficTitleLable.textAlignment = NSTextAlignmentLeft;
    _trafficTitleLable.textColor = [UIColor colorWithHexString:@"#dddce3"];
    _trafficTitleLable.font = [UIFont systemFontOfSize:14];
    [_topView addSubview:_trafficTitleLable];
    
    
    _trafficValueLable =[[UILabel alloc] init];
    _trafficValueLable.text = @"";
    _trafficValueLable.textAlignment = NSTextAlignmentLeft;
    _trafficValueLable.textColor = [UIColor colorWithHexString:@"#dddce3"];
    _trafficValueLable.font = [UIFont systemFontOfSize:14];
    [_topView addSubview:_trafficValueLable];
    
    
    _topView.hidden = YES;
    
}


- (void)initBeautyMenuButton {
  
    _beautySettingView = [[UIView alloc] init];
    _beautySettingView.backgroundColor = [UIColor clearColor];
    _beautySettingView.layer.cornerRadius = 5;
    _beautySettingView.clipsToBounds = YES;
    
    _beautySettingBGView = [[UIView alloc] init];
    _beautySettingBGView.backgroundColor = [UIColor whiteColor];
    _beautySettingBGView.alpha = .5;
    _beautySettingBGView.layer.cornerRadius = 5;
    _beautySettingBGView.clipsToBounds = YES;
    
    [self.view addSubview:_beautySettingView];
    
    
    [_beautySettingView addSubview:_beautySettingBGView];
    
    
    
    
    //美颜
    _beautyLabel =[[UILabel alloc] init];
    _beautyLabel.text = @"美颜调节";
    
    _beautyLabel.textColor = [UIColor blackColor];
    _beautyLabel.font = [UIFont systemFontOfSize:14];
    [_beautySettingView addSubview:_beautyLabel];
    
    
    //亮度
    _brightLabel = [[UILabel alloc] init];
    _brightLabel.text = @"亮度调节";
    
    _brightLabel.textColor = [UIColor blackColor];
    _brightLabel.font = [UIFont systemFontOfSize:14];
    [_beautySettingView addSubview:_brightLabel];
    
    
    //美颜
    _beautySlider =[[UISlider alloc] init];
    _beautySlider.tag = 105;
    _beautySlider.minimumValue = 0.0;
    _beautySlider.maximumValue = 100.0;
    _beautySlider.value = 50;
    _lastBeautyValue = 50;
    _beautySlider.minimumTrackTintColor = RGB(17, 195, 236);
    [_beautySlider setThumbImage:[UIImage imageNamed:LiveImageName(@"Handle")] forState:UIControlStateNormal];
    
    [_beautySlider addTarget:self action:@selector(sliderValueChage:) forControlEvents:UIControlEventValueChanged];
    [_beautySettingView addSubview:_beautySlider];
    
    _beautyValue = [[UILabel alloc] init];
    _beautyValue.text = @"50";
    _beautyValue.textColor = [UIColor blackColor];
    _beautyValue.font = [UIFont systemFontOfSize:10];
    _beautyValue.textAlignment = NSTextAlignmentCenter;
    [_beautySettingView addSubview:_beautyValue];
    
    
    //亮度
    _brightSlider = [[UISlider alloc] init];
    _brightSlider.minimumValue = 0.0;
    _brightSlider.maximumValue = 100.0;
    _brightSlider.value = 50;
    _lastBrightValue = 50;
    _brightSlider.tag = 106;
    _brightSlider.minimumTrackTintColor = RGB(17, 195, 236);
    [_brightSlider setThumbImage:[UIImage imageNamed:LiveImageName(@"Handle")] forState:UIControlStateNormal];
    
    [_brightSlider addTarget:self action:@selector(sliderValueChage:) forControlEvents:UIControlEventValueChanged];
    [_beautySettingView addSubview:_brightSlider];
    
    _brightValue = [[UILabel alloc] init];
    _brightValue.text = @"50";
    _brightValue.textColor = [UIColor blackColor];
    _brightValue.font = [UIFont systemFontOfSize:10];
    _brightValue.textAlignment = NSTextAlignmentCenter;
    [_beautySettingView addSubview:_brightValue];
    
    
    _beautySettingView.hidden = YES;
    
}




#pragma mark - layout
- (void) layout
{
    
    [_topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(395 , 39));
        make.centerX.equalTo(self.view.mas_centerX).with.offset(0);
        make.top.equalTo(self.view.mas_top).with.offset(0);
    }];
    [_topBGView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(395 , 39));
        make.centerX.equalTo(self.view.mas_centerX).with.offset(0);
        make.top.equalTo(self.view.mas_top).with.offset(0);
    }];
    
    UIImage *netImage = [UIImage imageNamed:LiveImageName(@"net")];
    [_netImage mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(netImage.size.width ,netImage.size.height));
        make.top.equalTo(self.view.mas_top).with.offset(11);
        make.left.equalTo(_topBGView.mas_left).with.offset(20);
        
        
    }];
    
    UIImage *count = [UIImage imageNamed:LiveImageName(@"count")];
    [_redPoint mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(count.size.width ,count.size.height));
        make.centerY.equalTo(_netImage.mas_centerY).with.offset(0);
        make.left.equalTo(_netImage.mas_right).with.offset(115);
    }];
    
    
    
    [_timelabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(70 ,30));
        make.centerY.equalTo(_netImage.mas_centerY).with.offset(0);
        make.left.equalTo(_redPoint.mas_right).with.offset(6);
    }];
    
    
    UIImage *batteryImage = [UIImage imageNamed:LiveImageName(@"100-ttery")];
    [_batteryImage mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(batteryImage.size.width ,batteryImage.size.height));
        make.centerY.equalTo(_netImage.mas_centerY).with.offset(0);
        make.right.equalTo(_topBGView.mas_right).with.offset(-20);
    }];
    
    [_streamTitleLable mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(60 ,20));
        make.left.equalTo(self.view.mas_left).with.offset(180);
        make.top.equalTo(_topBGView.mas_bottom).with.offset(10);
        
    }];
    
    [_streamValueLable mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(80 ,20));
        make.centerY.equalTo(_streamTitleLable.mas_centerY).with.offset(0);
        make.left.equalTo(_streamTitleLable.mas_right).with.offset(10);
        
        
    }];
    
    
    [_trafficTitleLable mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(50 ,20));
        make.centerY.equalTo(_streamTitleLable.mas_centerY).with.offset(0);
        make.left.equalTo(_streamValueLable.mas_right).with.offset(70);
        
        
    }];
    
    
    
    [_trafficValueLable mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(80 ,20));
        make.centerY.equalTo(_streamTitleLable.mas_centerY).with.offset(0);
        make.left.equalTo(_trafficTitleLable.mas_right).with.offset(19);
        
        
    }];
    
    UIImage *screenshotsimage = [UIImage imageNamed:LiveImageName(@"photo-round")];
    
    [_screenshotsButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(screenshotsimage.size.width ,screenshotsimage.size.height));
        make.top.equalTo(self.view.mas_top).with.offset(15);
        make.right.equalTo(self.view.mas_right).with.offset(-15);
        
    }];
    
    UIImage *reportimage = [UIImage imageNamed:LiveImageName(@"cemera-round")];
    
    [_reportButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(reportimage.size.width ,reportimage.size.height));
        make.right.equalTo(self.view.mas_right).with.offset(-10);
        make.top.equalTo(_screenshotsButton.mas_bottom).with.offset(95);
    }];
    
    UIImage *setimage = [UIImage imageNamed:LiveImageName(@"set-round")];
    [_setButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(setimage.size.width ,setimage.size.height));
        make.right.equalTo(self.view.mas_right).with.offset(-15);
        make.top.equalTo(_reportButton.mas_bottom).with.offset(95);
    }];
    
    
        
    [_leftView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(49 , IphoneHeight));
        make.left.equalTo(self.view.mas_left).with.offset(0);
        make.top.equalTo(self.view.mas_top).with.offset(0);
    }];
    
    [_LeftBGView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(49 , IphoneHeight));
        make.left.equalTo(self.view.mas_left).with.offset(0);
        make.top.equalTo(self.view.mas_top).with.offset(0);
    }];
    
    UIImage *backImage = [UIImage imageNamed:LiveImageName(@"return")];
    
    [_backButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(49 ,backImage.size.height));
        make.centerX.equalTo(_LeftBGView.mas_centerX);
        
        //        make.left.equalTo(self.view.mas_left).with.offset(15);
        make.top.equalTo(self.view.mas_top).with.offset(15);
    }];
    
    UIImage *micSwitcImage = [UIImage imageNamed:LiveImageName(@"lamp-open")];
    
    [_micSwitcButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(49,micSwitcImage.size.height));
        make.centerX.equalTo(_LeftBGView.mas_centerX);
        
        //        make.right.equalTo(_menuBGImg.mas_right).with.offset(- 66);
        make.top.equalTo(_backButton.mas_bottom).with.offset(47);
    }];
    
    
    UIImage *cameraImage = [UIImage imageNamed:LiveImageName(@"shot-change")];
    [_cameraButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(49 ,cameraImage.size.height));
        make.centerX.equalTo(_LeftBGView.mas_centerX);
        //        make.left.equalTo(self.view.mas_left).with.offset(15);
        make.top.equalTo(_micSwitcButton.mas_bottom).with.offset(47);
    }];
    
    
    UIImage *torchImage = [UIImage imageNamed:LiveImageName(@"lamp-open")];
    
    [_torchButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(49,torchImage.size.height));
        make.centerX.equalTo(_LeftBGView.mas_centerX);
        
        //        make.right.equalTo(_menuBGImg.mas_right).with.offset( - 10);
        make.top.equalTo(_cameraButton.mas_bottom).with.offset(47);
    }];
    
    
    UIImage *beautiyImage = [UIImage imageNamed:LiveImageName(@"lamp-open")];
    
    [_beautiyButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(49 ,beautiyImage.size.height));
        make.centerX.equalTo(_LeftBGView.mas_centerX);
        
        //        make.right.equalTo(_menuBGImg.mas_right).with.offset(- 66);
        make.top.equalTo(_torchButton.mas_bottom).with.offset(47);
    }];
    
    
    
    [_beautySettingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(310 , 100));
        make.left.equalTo(_LeftBGView.mas_right).with.offset(20);
        make.bottom.equalTo(self.view.mas_bottom).with.offset(-20);
    }];
    
    [_beautySettingBGView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(310 , 100));
        make.left.equalTo(_LeftBGView.mas_right).with.offset(20);
        make.bottom.equalTo(self.view.mas_bottom).with.offset(-20);
    }];
    
    [_beautyLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(70 ,20));
        make.left.equalTo(_beautySettingView.mas_left).with.offset(10);
        make.top.equalTo(_beautySettingView.mas_top).with.offset(10);
        
        
    }];
    
    
    [_brightLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(70 ,20));
        
        make.left.equalTo(_beautySettingView.mas_left).with.offset(10);
        
        make.bottom.equalTo(_beautySettingView.mas_bottom).with.offset(-20);
        
        
    }];
    
    [_beautySlider mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(200 ,20));
        make.left.equalTo(_beautyLabel.mas_right).with.offset(10);
        make.top.equalTo(_beautySettingView.mas_top).with.offset( 10);
        
        
    }];
    [_beautyValue mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(20 ,10));
        make.centerX.equalTo(_beautySlider.mas_centerX).with.offset(0);
        make.top.equalTo(_beautySlider.mas_bottom).with.offset(0);
        
        
    }];
    
    
    [_brightSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(200 ,20));
        make.left.equalTo(_brightLabel.mas_right).with.offset(10);
        make.bottom.equalTo(_beautySettingView.mas_bottom).with.offset(-20);
        
    }];
    [_brightValue mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.size.mas_equalTo(CGSizeMake(20 ,10));
        make.centerX.equalTo(_brightSlider.mas_centerX).with.offset(0);
        make.top.equalTo(_brightSlider.mas_bottom).with.offset(0);
        
        
    }];
    
    
}

#pragma mark --美颜效果调节
- (void)sliderValueChage:(id)slider
{
    UISlider *searchSlider = slider;
    
    switch (searchSlider.tag) {
        case 105:
        {
            [_filter setGrindRatio:searchSlider.value/100];
            
            NSString *voiceValue = [NSString stringWithFormat:@"%.0f",searchSlider.value];
            _beautyValue.text = voiceValue;
            
            CGFloat change = (_lastBeautyValue - searchSlider.value) *2;
            
            if (searchSlider.value < 20) {
                _beautyValue.textAlignment = NSTextAlignmentRight;
                
            }else if (searchSlider.value>80)
            {
                _beautyValue.textAlignment = NSTextAlignmentLeft;
            }else
            {
                _beautyValue.textAlignment = NSTextAlignmentCenter;
                
            }
            [UIView animateWithDuration:0.1 animations:^{
                _beautyValue.x -= change;
            }];
            _lastBeautyValue = searchSlider.value;
        }
            
            break;
        case 106:
        {
            [_filter setWhitenRatio:searchSlider.value/50];
            
            NSString *voiceValue = [NSString stringWithFormat:@"%.0f",searchSlider.value];
            _brightValue.text = voiceValue;
            
            CGFloat change = (_lastBrightValue - searchSlider.value) *2;
            
            if (searchSlider.value < 20) {
                _brightValue.textAlignment = NSTextAlignmentRight;
                
            }else if (searchSlider.value>80)
            {
                _brightValue.textAlignment = NSTextAlignmentLeft;
            }else
            {
                _brightValue.textAlignment = NSTextAlignmentCenter;
                
            }
            
            
            [UIView animateWithDuration:0.1 animations:^{
                _brightValue.x -= change;
            }];
            _lastBrightValue = searchSlider.value;
            
            
        }
            
            break;
            
            
        default:
            break;
    }
    
}


#pragma mark --截屏
- (void)screenshotsButtonClick
{
    UIView *view = [[UIView alloc] initWithFrame:self.view.bounds];
    view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:view];
    AudioServicesPlaySystemSound(1108);
    
    
    [UIView animateWithDuration:0.2 animations:^{
        view.alpha = 0;
    } completion:^(BOOL finished) {
        [view removeFromSuperview];
    }];
    
    GPUImageOutput *filter = _pipKit.vStreamMixer;
    if (filter){
        [filter useNextFrameForImageCapture];
        UIImage * image =filter.imageFromCurrentFramebuffer;
        ALAssetsLibrary * library = [ALAssetsLibrary new];
        
        NSData * data = UIImageJPEGRepresentation(image, 1.0);
        
        
        [library writeImageDataToSavedPhotosAlbum:data metadata:nil completionBlock:^(NSURL *assetURL, NSError *error) {
            
            if (!error) {
                
                
                
            }
        }];
        
    }

   
}








#pragma mark - 计时器
- (void)timeAction {
    _timeNum ++;
    //shi
    NSInteger hour= _timeNum/3600;
    NSString *hourText = hour <10 ? [NSString stringWithFormat:@"0%ld",(long)hour] :[NSString stringWithFormat:@"%ld",(long)hour];
    //   fen
    NSInteger minute = ( _timeNum -hour *3600)/60;
    NSString *minuteText = minute <10 ? [NSString stringWithFormat:@"0%ld",(long)minute] :[NSString stringWithFormat:@"%ld",(long)minute];
    //miao
    NSInteger second = (_timeNum -hour *3600 -minute *60);
    NSString *secondText = second <10 ? [NSString stringWithFormat:@"0%ld",(long)second] :[NSString stringWithFormat:@"%ld",(long)second];
    _timelabel.text = [NSString stringWithFormat:@"%@:%@:%@",hourText,minuteText,secondText];
    
    
    NetWorkType status = [StatusBarTool_JWZT currentNetworkType];
    
    
    
    
    if (!(status == NetWorkTypeNone)) {
        
        CGFloat FrameRate = _pipKit.streamerBase.encodeVKbps;
        NSString *gaugeText = [NSString stringWithFormat:@"%.0fKps",FrameRate];
        
        
        if (FrameRate>1000) {
            gaugeText = [NSString stringWithFormat:@"%.2fMps",FrameRate/1000];
        }
        
        CGFloat dataflow = _pipKit.streamerBase.uploadedKByte;
        NSString *Bandwidth = [NSString stringWithFormat:@"%.0fK",dataflow];
        if (dataflow > 1024) {
            Bandwidth = [NSString stringWithFormat:@"%.2fM",dataflow/1024];
        }else if (dataflow > 1024 *1024)
        {
            Bandwidth = [NSString stringWithFormat:@"%.2fG",dataflow/(1024 * 1024)];
            
        }
        
        
        _streamValueLable.text = gaugeText;
        _trafficValueLable.text = Bandwidth;
    }
    
    
    

    
}

#pragma mark - 摄像头切换按钮
- (void)cameraButton:(UIButton *)button {
    button.selected = !button.selected;
    
    [_pipKit switchCamera];
    
}

#pragma mark -开始直播
- (void)reportAction:(UIButton *)button {
    
    
    _beautySettingView.hidden = YES;
    _beautiyButton.enabled = YES;
    
    NetWorkType status = [StatusBarTool_JWZT currentNetworkType];
    
    if (!(status == NetWorkTypeNone)) {
    
    button.selected = !button.selected;
    
    if (!_isBegin) {
        [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    }
    
    
    if (button.selected == NO) {
        MTBlockAlertView *alertview = [[MTBlockAlertView alloc] initWithTitle:@"是否结束直播" message:nil
    completionHanlder:^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [_pipKit.streamerBase stopStream];                                                                    _isBegin = NO;
            _setButton.enabled = YES;

            
        }else if(buttonIndex == 1){
            _reportButton.selected = YES;
        }
    }
                                                            cancelButtonTitle:nil
                                                            otherButtonTitles: @"确定", @"取消" , nil];
        [alertview show];
    }else {

        _isBegin = YES;
        _reportButton.enabled = YES;
        _setButton.enabled = NO;
        NSURL *pushUrl = [NSURL URLWithString:RTMP_URL_1];
        [_pipKit.streamerBase startStream:pushUrl];
        
    }
    }else
    {
        MTBlockAlertView *alertview = [[MTBlockAlertView alloc] initWithTitle:@"当前网络断开连接，请检查网络" message:nil completionHanlder:nil                                                        cancelButtonTitle:@"确定" otherButtonTitles:  nil];
        [alertview show];

    }
    
        
}

#pragma mark - 菜单栏按钮点击
- (void)MenuAction:(UIButton *)button {
    
    
    switch (button.tag) {
        case 101:
            if ([_pipKit isTorchSupported]) {
                [_pipKit toggleTorch];
            
            
                UIView *alertView = [[UIView alloc] init];
                alertView.backgroundColor = [UIColor whiteColor];
                alertView.alpha = .5;
                [self.view addSubview:alertView];
                UILabel *alertLabel = [[UILabel alloc] init];
                alertLabel.textColor = [UIColor whiteColor];
                alertLabel.font = [UIFont systemFontOfSize:14];
                alertLabel.textAlignment = NSTextAlignmentCenter;
                [self.view addSubview:alertLabel];
                
                
                if (_torchButton.selected) {
                    
                    alertLabel.text = @"闪光灯已关闭!";
                    
                }else
                {
                    alertLabel.text = @"闪关灯已开启!";
                }
                
                button.selected = !button.selected;
                
                [alertView mas_makeConstraints:^(MASConstraintMaker *make) {
                    make.size.mas_equalTo(CGSizeMake(100 , 30));
                    make.centerX.equalTo(self.view.mas_centerX).with.offset(0);
                    make.centerY.equalTo(self.view.mas_centerY).with.offset(0);
                }];
                [alertLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                    
                    make.size.mas_equalTo(CGSizeMake(90 , 20));
                    make.centerX.equalTo(self.view.mas_centerX).with.offset(0);
                    make.centerY.equalTo(self.view.mas_centerY).with.offset(0);

                    
                }];
                
                [UIView animateWithDuration:1.0 delay:1.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    alertLabel.alpha = 0;
                    alertView.alpha =0;
                } completion:^(BOOL finished) {
                    
                    [alertView removeFromSuperview];
                    [alertLabel removeFromSuperview];

                }];
            }

            
                       break;
        case 102:
            //        语音开关,默认是trun。 当直播开始录制的时候endle = no 不可以调节。
            //       关闭_>打开
            
            
        {
            button.selected = !button.selected;

            UIView *alertView = [[UIView alloc] init];
            alertView.backgroundColor = [UIColor whiteColor];
            alertView.alpha = .5;
            [self.view addSubview:alertView];
            UILabel *alertLabel = [[UILabel alloc] init];
            alertLabel.textColor = [UIColor whiteColor];
            alertLabel.font = [UIFont systemFontOfSize:14];
            alertLabel.textAlignment = NSTextAlignmentCenter;
            [self.view addSubview:alertLabel];
            
            
            
            if (button.selected == YES) {
                //       关闭_>打开
                _pipKit.aCapDev.micVolume = 0.0;
                alertLabel.text = @"语音已关闭!";
            }else {
                
                _pipKit.aCapDev.micVolume = 1.0;
                 alertLabel.text = @"语音已开启!";
            }

            
            
           
            [alertView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.size.mas_equalTo(CGSizeMake(100 , 30));
                make.centerX.equalTo(self.view.mas_centerX).with.offset(0);
                make.centerY.equalTo(self.view.mas_centerY).with.offset(0);
            }];
            [alertLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                
                make.size.mas_equalTo(CGSizeMake(90 , 20));
                make.centerX.equalTo(self.view.mas_centerX).with.offset(0);
                make.centerY.equalTo(self.view.mas_centerY).with.offset(0);
            }];
            
            [UIView animateWithDuration:1.0 delay:1.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                alertLabel.alpha = 0;
                alertView.alpha =0;
            } completion:^(BOOL finished) {
                
                [alertView removeFromSuperview];
                [alertLabel removeFromSuperview];
                
            }];
    }
            break;
            //美颜
        case 103:
        {
            _beautySettingView.hidden = !_beautySettingView.hidden;

        }
            break;
            
            //设置按钮
        case 104:
        {
            
            if (_setView ==nil) {
                _setView = [[Set alloc] initWithFrame:CGRectMake(100, 50, IphoneWidth - 200, IphoneHeight - 100)];
            }
            _setView.delegate = self;
            _setView.isBegin = _isBegin;
            _setView.recognizeSegment_selected = _setting.videoSize;
            _setView.fpsSegment_selected = _setting.FPS;
            _setView.rateValue = _setting.Bitrate;
            
            if (_deleSet == nil) {
                _deleSet = [UIButton buttonWithnormalImg:[UIImage imageNamed:LiveImageName(@"close.png")] highlightedImg:[UIImage imageNamed:LiveImageName(@"close_highlight.png")] selector:@selector(deleset) target:self];
            }
            _deleSet.frame = CGRectMake(_setView.right - menuButtonWidth/2.0, _setView.y - menuButtonWidth/2.0, menuButtonWidth, menuButtonWidth);
            
            _setView.hidden = NO;
            _deleSet.hidden = NO;
            [self.view addSubview:_setView];
            [self.view addSubview:_deleSet];

            
        }
            break;
            
        default:
            break;
    }
}


#pragma mark - 删除设置界面
- (void)deleset {
    [_setView removeFromSuperview];
    _setView = nil;
    [_deleSet removeFromSuperview];
    _deleSet =nil;
    if (_settingIsChanged) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self RtmpInit];
            
        });
        
    }

}

#pragma mark- setDelegate

-(void)setDelegate:(UIView *)set withRecognize:(NSString *)recognize
{
    if ([_setting.videoSize isEqualToString:recognize]) {
        return;
    }else
    {
        _settingIsChanged = YES;
        _setting.videoSize = recognize;
    }
    
}

-(void)setDelegate:(UIView *)set withFps:(int)fps
{
    if (_setting.FPS == fps) {
        return;
    }else
    {
        _setting.FPS = fps;
        _settingIsChanged = YES;

    }
    
    
    
    
}
- (void)setDelegate:(UIView *)set withRate:(int)rate {
    
    
    
    if (!(_setting.Bitrate == rate)) {
        _setting.Bitrate = rate;
        _settingIsChanged = YES;
               
    }
}



#pragma mark -  pop
- (void)topAction:(UIButton *)button {
        MTBlockAlertView *alertview = [[MTBlockAlertView alloc] initWithTitle:@"是否退出直播？" message:nil
        completionHanlder:^(UIAlertView *alertView, NSInteger buttonIndex) {
            if (buttonIndex == 0) {
                    [_timer invalidate];
                [_checkTimer invalidate];
                [_pipKit.streamerBase stopStream];
                [_pipKit stopPreview];
                [self dismissViewControllerAnimated:YES completion:^{
                }];
            }
        }
                                                            cancelButtonTitle:nil
                                                            otherButtonTitles: @"确定", @"取消" , nil];
        [alertview show];
    }

#pragma  maek - kvo（屏幕旋转通知）
-(void)orientationChanged:(NSNotification*)notification{

    UIDeviceOrientation currentOrientation = [[UIDevice currentDevice] orientation];
    
    if (currentOrientation == UIDeviceOrientationPortrait){
        
        DebugLog(@"UIDeviceOrientationPortrait");
        
    }else if (UIDeviceOrientationLandscapeRight) {
     
        DebugLog(@"UIDeviceOrientationLandscapeRight");
    }
}

//强制旋转某个方向
- (void)screenRotationStatus:(UIInterfaceOrientation)interfaceOrientation {
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = interfaceOrientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];//删除去激活界面的回调
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];//删除激活界面的回调
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}




#pragma mark -- LFStreamingSessionDelegate
/** live status changed will callback */
- (void) onStreamStateChange:(NSNotification *)notification {
    if ( _pipKit.streamerBase.streamState == KSYStreamStateIdle) {
        NSLog(@"idle");
    }
    else if ( _pipKit.streamerBase.streamState == KSYStreamStateConnected){
        [_timer setFireDate:[NSDate date]];
        _topView.hidden = NO;
        [MBProgressHUD hideHUDForView:self.view animated:YES];
        _isBegin = YES;
        _setButton.enabled = NO;

        _beautiyButton.enabled = NO;
            _reportButton.selected = YES;
            _reportButton.enabled = YES;
            


        
        NSLog(@"开始直播connected");
        
        
            
        
        
    }
    else if (_pipKit.streamerBase.streamState == KSYStreamStateConnecting ) {
        NSLog(@"kit 开始直播connecting");
        
        
    }
    else if (_pipKit.streamerBase.streamState == KSYStreamStateDisconnecting ) {
        NSLog(@"断开直播disconnecting");
        
       
        _setButton.enabled = YES;
        _trafficValueLable.text = @"";
        _streamValueLable.text = @"";
        [_timer setFireDate:[NSDate distantFuture]];
        _reportButton.selected = NO;
        _timelabel.text = @"00:00:00";
        _timeNum =0;
        _topView.hidden = YES;

    }
    else if (_pipKit.streamerBase.streamState == KSYStreamStateError ) {
        
        _reportButton.enabled = YES;
        _reportButton.selected = NO;
        _setButton.enabled = YES;
        _topView.hidden = YES;

        [MBProgressHUD hideHUDForView:self.view animated:YES];
        

    }
}


#pragma mark --获取电池电量
- (void)checkBattery
{
    NSString *str = [StatusBarTool_JWZT currentBatteryPercent];
    CGFloat batteryLevel = [str intValue];
    if (batteryLevel >0&&batteryLevel<=10) {
        _batteryImage.image = [UIImage imageNamed:LiveImageName(@"10-ttery")];
    }else if (batteryLevel >10&&batteryLevel<=20){
        _batteryImage.image = [UIImage imageNamed:LiveImageName(@"20-ttery")];
    }else if (batteryLevel >20&&batteryLevel<=30){
        _batteryImage.image = [UIImage imageNamed:LiveImageName(@"30-ttery")];
    }else if (batteryLevel >30&&batteryLevel<=40){
        _batteryImage.image = [UIImage imageNamed:LiveImageName(@"40-ttery")];
    }else if (batteryLevel >40&&batteryLevel<=50){
        _batteryImage.image = [UIImage imageNamed:LiveImageName(@"50-ttery")];
    }else if (batteryLevel >50&&batteryLevel<=60){
        _batteryImage.image = [UIImage imageNamed:LiveImageName(@"60-ttery")];
    }else if (batteryLevel >60&&batteryLevel<=70){
        _batteryImage.image = [UIImage imageNamed:LiveImageName(@"70-ttery")];
        
    }else if (batteryLevel >70&&batteryLevel<=80){
        _batteryImage.image = [UIImage imageNamed:LiveImageName(@"80-ttery")];
        
    }else if (batteryLevel >80&&batteryLevel<=90){
        _batteryImage.image = [UIImage imageNamed:LiveImageName(@"90-ttery")];
        
    }else if (batteryLevel >90&&batteryLevel<=100){
        _batteryImage.image = [UIImage imageNamed:LiveImageName(@"100-ttery")];
    }
    
}

#pragma mark --获取网络信号强度

- (void)checkStatusBar
{
    int wifiStrength = [StatusBarTool_JWZT getSignalStrength];
    
    NSLog(@"%d",wifiStrength);
    switch (wifiStrength) {
            
        case 0:
            _netImage.image = [UIImage imageNamed:LiveImageName(@"net3")];
            break;
            
        case 1:
            _netImage.image =[UIImage imageNamed:LiveImageName(@"net3")];
            break;
        case 2:
            _netImage.image = [UIImage imageNamed:LiveImageName(@"net6")];
            
            break;
        case 3:
            _netImage.image =[UIImage imageNamed:LiveImageName(@"net")];
            
            break;
            
        default:
            break;
    }
    
}







- (void) appWillEnterForegroundNotification{
    NSLog(@"trigger event when will enter foreground.");
    if (![self hasPermissionOfCamera]) {
        return;
    }
    
}
- (void)WillDidBecomeActiveNotification{
    NSLog(@"CameraViewController: WillDidBecomeActiveNotification");
    
}
- (BOOL)hasPermissionOfCamera
{
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus != AVAuthorizationStatusAuthorized){
        
        NSLog(@"相机权限受限");
        return NO;
    }
    return YES;
}



- (void)WillResignActiveNotification{
    NSLog(@"LiveShowViewController: WillResignActiveNotification");
    
    if (![self hasPermissionOfCamera]) {
        return;
    }
    //得到当前应用程序的UIApplication对象
    UIApplication *app = [UIApplication sharedApplication];
    
    //一个后台任务标识符
    UIBackgroundTaskIdentifier taskID = 0;
    taskID = [app beginBackgroundTaskWithExpirationHandler:^{
        //如果系统觉得我们还是运行了太久，将执行这个程序块，并停止运行应用程序
        [app endBackgroundTask:taskID];
    }];
    //UIBackgroundTaskInvalid表示系统没有为我们提供额外的时候
    if (taskID == UIBackgroundTaskInvalid) {
        NSLog(@"Failed to start background task!");
        return;
    }
    
    
//    告诉系统我们完成了
    [app endBackgroundTask:taskID];
}

#pragma mark -shouldAutorotate (类目)
//返回最上层的子Controller的supportedInterfaceOrientations


//不自动旋转
- (BOOL)shouldAutorotate {
    
    return NO;
}


- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return YES;
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    _beautySettingView.hidden = YES;
    
}


@end
