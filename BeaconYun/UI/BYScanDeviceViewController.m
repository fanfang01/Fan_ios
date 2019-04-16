//
//  BYScanViewController.m
//  BeaconYun
//
//  Created by SACRELEE on 2/24/17.
//  Copyright © 2017 MinewTech. All rights reserved.
//

#import "BYScanDeviceViewController.h"
#import "BYTableViewModel.h"
#import "BYSectionModel.h"
#import "BYHeaderView.h"
#import "BYCommonMacros.h"
#import "BYCellModel.h"
#import <Masonry.h>
#import "BYCommonTools.h"
#import "BYSetDeviceViewController.h"
#import "MinewModuleManager.h"
#import "MinewModule.h"
#import "BYDeviceDetailViewController.h"
#import "MinewModuleAPI.h"
#import "BYInfoViewController.h"

#import "WakeUpManager.h"
#import "RecognizeManager.h"
#import "AudioPlayer.h"

@interface BYScanDeviceViewController ()<MinewModuleManagerDelegate,AudioPlayerDelegate>
@property (nonatomic, strong) AudioPlayer *player;

@property (nonatomic, strong) MinewModuleManager *manager;

@property (nonatomic, strong) NSArray *moduleArray;

@property (nonatomic, strong) NSMutableArray *tempArr;

@property (nonatomic, strong) MinewModuleAPI *api;

@property (nonatomic, assign) WorkMode workMode;
@property (nonatomic, assign) ShakeState shakeState;
@property (nonatomic, assign) DisplayState displayState;

@property (weak, nonatomic) IBOutlet UIButton *speedModeSelectBtn;



@property (weak, nonatomic) IBOutlet UISwitch *shakeSwitch;

@property (nonatomic, strong) UIAlertController *alert;

@property (nonatomic, assign) NSInteger fanSpeed;//风扇速度
@property (nonatomic, assign) NSInteger limitedTime;//定时时间


@property (nonatomic, strong) CustomSlider *timeCusSlider;

//语音识别
@property (nonatomic, strong) WakeUpManager *wakeupManager;

@property (nonatomic, strong) RecognizeManager *recongnizeManager;
@end

@implementation BYScanDeviceViewController
{
    BOOL _isWriting;
    BOOL _isUserCloseTiming;
    BOOL _isShouldINRecognize;
    NSTimer *_recognizeTimer;
    NSInteger _countDown;
}

struct SendDataNodel dataModel = {0,0,0,0,0,0};
struct DeviceBaseInfo deviceBaseInfoModel = {0,0,0};

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Fan";
    _countDown = 0;
    
    _isWriting = NO;
    
    _player = [[AudioPlayer alloc]init];
    _player.immediate = YES;
    _player.delegate = self;
    
    [self timeCusSlider];

    [self initCore];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"更新设备状态" style:UIBarButtonItemStylePlain target:self action:@selector(getDeviceStateInfo)];
    
    [SVProgressHUD showInfoWithStatus:@"设备信息更新中..."];
    

    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
//    [self getDeviceMacAddress];
    
//    [self getDeviceInfo];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_api disconnect:nil];
    
    [SVProgressHUD dismiss];
}

#pragma mark --- 开始识别的倒计时 NSTimer
- (void) initRecognizeTimer {
    [self invalidateTimer];
    
    if (!_recognizeTimer) {
        _recognizeTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(startCountDown) userInfo:nil repeats:YES];
    }
}

- (void) startCountDown {
    _countDown ++;
    if (_countDown > 4) {
        [self invalidateTimer];
        
        [self.recongnizeManager stopRecognize];
        [self wakeupConfiguration];
    }
}

- (void)invalidateTimer {
    
    [_recognizeTimer invalidate];
    _recognizeTimer = nil;
    
    _countDown = 0;
}

- (void)dealloc {
    
    [self invalidateTimer];
}

- (void)wakeupConfiguration {
    _wakeupManager = [WakeUpManager sharedInstance];

    [_wakeupManager startWakeup];

    __weak BYScanDeviceViewController *weakSelf = self;
    _wakeupManager.voiceWakeUp = ^(NSString * _Nonnull keywords) {

        __strong BYScanDeviceViewController *strongSelf = weakSelf;

        NSLog(@"识别到关键词:%@",keywords);
        
        [strongSelf.wakeupManager stopWakeup];
        
        if ([keywords containsString:@"工作模式"]) {
            [SVProgressHUD showSuccessWithStatus:@"您已开机"];
            //to be confirmed
            _workMode = ModeNormal;
            
            [strongSelf setDeveiceState];
            
            [MinewCommonTool onMainThread:^{
                [strongSelf.onOffSwitch setOn:YES];
                [strongSelf playOKAudio];
            }];
        }else if ([keywords containsString:@"关机模式"]) {
            [SVProgressHUD showSuccessWithStatus:@"您已关机"];
            //其他的按钮状态统一关闭
            [strongSelf.timingonOffSwitch setOn:NO];
            [strongSelf.shakeSwitch setOn:NO];
            
            strongSelf.workMode = ModeClose;
            
            [strongSelf setDeveiceState];
            
            [MinewCommonTool onMainThread:^{
                [strongSelf.onOffSwitch setOn:NO];
                [strongSelf playOKAudio];
            }];
        }else {
            [SVProgressHUD showSuccessWithStatus:@"您可以发送命令了"];
            
            [MinewCommonTool onMainThread:^{
                [strongSelf playHereAudio];
            }];
        }

    };
}

- (void)recognizeConfiguration {
    [self initRecognizeTimer];
    
    _recongnizeManager = [RecognizeManager sharedInstance];
    [_recongnizeManager.asrEventManager setParameter:@(NO) forKey:BDS_ASR_ENABLE_LONG_SPEECH];
    [_recongnizeManager.asrEventManager setParameter:@(YES) forKey:BDS_ASR_NEED_CACHE_AUDIO];
    [_recongnizeManager.asrEventManager setParameter:@"3" forKey:BDS_ASR_MFE_MAX_WAIT_DURATION];
    [_recongnizeManager.asrEventManager setParameter:@(6.) forKey:BDS_ASR_MFE_MAX_SPEECH_PAUSE];
    [_recongnizeManager.asrEventManager setParameter:@"" forKey:BDS_ASR_OFFLINE_ENGINE_TRIGGERED_WAKEUP_WORD];
    
    [_recongnizeManager.asrEventManager setDelegate:self];
    [_recongnizeManager.asrEventManager setParameter:nil forKey:BDS_ASR_AUDIO_FILE_PATH];
    [_recongnizeManager.asrEventManager setParameter:nil forKey:BDS_ASR_AUDIO_INPUT_STREAM];
    [_recongnizeManager.asrEventManager sendCommand:BDS_ASR_CMD_START];
    
    __weak BYScanDeviceViewController *weakSelf = self;
    
    _recongnizeManager.voiceReco = ^(NSString * _Nonnull voice) {
        
        __strong BYScanDeviceViewController *strongSelf = weakSelf;
        
        NSLog(@"收到的录音===%@",voice);
        
        [strongSelf invalidateTimer];
        
        [strongSelf recongnizeVoice:voice];
        
//        [strongSelf.recongnizeManager stopRecognize];
        
        
    };
}

#pragma mark --- 录音识别结果处理
- (void)recongnizeVoice:(NSString *)voice {
    if ([voice containsString:@"打开摇头"] || [voice containsString:@"开启摇头"]) {
        [SVProgressHUD showSuccessWithStatus:@"您已开启摇头"];
        _shakeState = ShakeYES;
        
        [_shakeSwitch setOn:YES];
        
        [self setDeveiceState];
        [MinewCommonTool onMainThread:^{
            [self playOKAudio];
        }];

    }else if ([voice containsString:@"停止摇头"] || [voice containsString:@"关闭摇头"]) {
        [SVProgressHUD showSuccessWithStatus:@"您已停止摇头"];
        _shakeState = ShakeNo;
        [_shakeSwitch setOn:NO];
        
        [self setDeveiceState];
        [MinewCommonTool onMainThread:^{
            [self playOKAudio];
        }];
    }else if ([voice containsString:@"定时"] && [voice containsString:@"小时"]) {
        NSRange range1 = [voice rangeOfString:@"定时"];
        NSRange range2 = [voice rangeOfString:@"小时"];
        NSString *timeStr = [voice substringWithRange:NSMakeRange(range1.length, range2.location)];
        //            NSInteger fileteredNum = [Tools chineseNumbersReturnArabicNumerals:voice];
        NSInteger fileteredNum = [timeStr integerValue];
        if (fileteredNum > 0) {
            _workMode = ModeLimitedTiming;
            [self.timingonOffSwitch setOn:YES];
            _isUserCloseTiming = NO;
        }
        if (fileteredNum <= 12) {
            _limitedTime = fileteredNum *60;
        }else {
            _limitedTime = 12*60;
            [SVProgressHUD showSuccessWithStatus:@"风扇的最大定时时长为12小时"];
        }
        
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"已定时%ld小时",(long)fileteredNum]];
        [self setDeveiceState];
        
        [MinewCommonTool onMainThread:^{
            self.timeCusSlider.value = _limitedTime/60;
            [self playOKAudio];
        }];
        
        NSLog(@"定时得到的时长为：%d 分钟",fileteredNum*60);
        
    }else if ([voice containsString:@"第"] && [voice containsString:@"档"]) {
        NSRange firstRange = [voice rangeOfString:@"第"];
        NSRange secondRange = [voice rangeOfString:@"档"];
        NSString *speedStr = [voice substringWithRange:NSMakeRange(firstRange.length, secondRange.location-firstRange.length)];
        NSInteger speed = [Tools chineseNumbersReturnArabicNumerals:speedStr];
        
#warning 这个地方需要好好测试
        
        if (speed == 0) {
            //判断是否纯数字
            if ([MinewCommonTool isNum:speedStr]) {
                speed = [speedStr integerValue];
            }
        }
        NSLog(@"第 速度为:%ld",speed);

        NSInteger fileteredNum = speed;
        [self setSpeedNumber:fileteredNum];
        
    }else if ([voice containsString:@"d"] && [voice containsString:@"档"]) {
        NSRange firstRange = [voice rangeOfString:@"d"];
        NSRange secondRange = [voice rangeOfString:@"档"];
        NSString *speedStr = [voice substringWithRange:NSMakeRange(firstRange.length, secondRange.location-firstRange.length)];
        NSInteger speed = [Tools chineseNumbersReturnArabicNumerals:speedStr];
        if (speed == 0) {
            //判断是否纯数字
            if ([MinewCommonTool isNum:speedStr]) {
                speed = [speedStr integerValue];
            }
        }
        NSLog(@"d 速度为:%ld",speed);
        NSInteger fileteredNum = speed;
        [self setSpeedNumber:fileteredNum];

    } else if ([voice containsString:@"上一档"] || [voice containsString:@"上一当"]) {
        _fanSpeed -= 1;
        
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"您已设定风扇转速%ld",(long)_fanSpeed]];
        _currentSpeedLabel.text = [NSString stringWithFormat:@"当前风速:%ld",(long)_fanSpeed];
        
        [self setDeveiceState];
        [MinewCommonTool onMainThread:^{
            [self playOKAudio];
        }];
    }else if ([voice containsString:@"下一档"]) {
        _fanSpeed += 1;
        
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"您已设定风扇转速%ld",(long)_fanSpeed]];
        _currentSpeedLabel.text = [NSString stringWithFormat:@"当前风速:%ld",(long)_fanSpeed];
        
        [self setDeveiceState];

        [MinewCommonTool onMainThread:^{
            [self playOKAudio];
        }];
        
    }else if ([voice containsString:@"增加定时"]) {
        NSInteger value = _limitedTime+60;
        NSLog(@"增加定时");
        if (value < 60*12) {
            _workMode = ModeLimitedTiming;
            [_timingonOffSwitch setOn:YES];
            _isUserCloseTiming = NO;
            [MinewCommonTool onMainThread:^{
                _limitedTime = value;
                self.timeCusSlider.value = value/30;
                [self playOKAudio];
            }];
        }
        
        [self setDeveiceState];
        
    }else if ([voice containsString:@"减小定时"] || [voice containsString:@"减少定时"]) {
        NSInteger value = _limitedTime-60;
        NSLog(@"减小定时");
        if (value < 0) {
            value = 0;
        }
        _workMode = ModeLimitedTiming;
        [_timingonOffSwitch setOn:YES];
        _isUserCloseTiming = NO;
        [self setDeveiceState];
        
        [MinewCommonTool onMainThread:^{
            _limitedTime = value;
            self.timeCusSlider.value = value/30;
            [self playOKAudio];
        }];
        
    }else if ([[MinewCommonTool transformPinYinWithString:voice] containsString:@"xiaoaoxiaoao"]) {
        [MinewCommonTool onMainThread:^{
            [self playHereAudio];
        }];
    }
    else {
        
        [self wakeupConfiguration];
    }
}

//语音识别风速
- (void)setSpeedNumber:(NSInteger)fileteredNum {
    NSLog(@"设定风速为：%ld",(long)fileteredNum);
    _fanSpeed = fileteredNum;
    if (fileteredNum > 32) {
        [SVProgressHUD showSuccessWithStatus:@"风速的最大速度为32"];
        _fanSpeed = 32;
    }
    
    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"您已设定风扇转速%ld",(long)self.fanSpeed]];
    self.currentSpeedLabel.text = [NSString stringWithFormat:@"当前风速:%ld",(long)self.fanSpeed];
    
    [self setDeveiceState];
    if (_fanSpeed > 0) {
        [MinewCommonTool onMainThread:^{
            [self playOKAudio];
        }];
    }
}

- (void)setWorkMode:(WorkMode)workMode
{
    _workMode = workMode;
    [self setDeveiceState];
    
    NSString *title = @"";
    switch (_workMode) {
        case ModeSleepWind:
            title = @"睡眠风";
            break;
        case ModeNatureWind:
            title = @"自然风";
            break;
        case ModeSuperStrongWind:
            title = @"超强风";
            break;
        case ModeSuperWeakWind:
            title = @"超微风";
            break;
        default:
            title = @"风行模式选择";
            break;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [_speedModeSelectBtn setTitle:title forState:UIControlStateNormal];
        [_speedModeSelectBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    });

}

#pragma mark --- 设定风扇的转速
- (IBAction)speedSliderMoved:(UISlider *)sender {
    float value = sender.value;
    
    NSInteger speed = value ;
    _fanSpeed = speed;
    
    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"您已设定风扇转速%ld",(long)speed]];
    _currentSpeedLabel.text = [NSString stringWithFormat:@"当前风速:%ld",(long)_fanSpeed];
    
    [self setDeveiceState];

}

#pragma mark ---- Getter
- (CustomSlider *)timeCusSlider
{
    if (!_timeCusSlider) {
        CustomSlider *slider = [[CustomSlider alloc] initWithFrame:CGRectMake(0, 250, CGRectGetWidth(self.view.frame), 80)];
        _timeCusSlider = slider;

        [self.view addSubview:slider];

        slider.backgroundColor = [UIColor clearColor];
        slider.sliderBarHeight = 10;
        slider.numberOfPart = 13;
        slider.partColor = [UIColor cyanColor];
        slider.sliderColor = [UIColor lightGrayColor];
        slider.thumbImage = [UIImage imageNamed:@"4.png"];
        slider.partNameOffset = CGPointMake(0, -30);
        slider.thumbSize = CGSizeMake(12, 10);
        slider.partSize = CGSizeMake(20, 24);
        slider.partNameArray = @[@"0",@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"11",@"12"];
        [slider addTarget:self action:@selector(timeValuechange:) forControlEvents:UIControlEventValueChanged];
        [self.view addSubview:slider];
    }
    return _timeCusSlider;
}

#pragma mark ---- 改变定时时间
- (void)timeValuechange:(CustomSlider*)sender {
    NSLog(@"current index = %ld",(long)sender.value);
    NSInteger value = sender.value;
    if (value > 0) {
        _workMode = ModeLimitedTiming;
        [_timingonOffSwitch setOn:YES];
        _isUserCloseTiming = NO;
    }
    _limitedTime = value *30;

    [self setDeveiceState];
}

- (UIAlertController *)alert
{
    if (!_alert) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请选择风的模式" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *sleep = [UIAlertAction actionWithTitle:@"睡眠风" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.workMode = ModeSleepWind;
        }];
        UIAlertAction *natural = [UIAlertAction actionWithTitle:@"自然风" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.workMode = ModeNatureWind;
        }];
        UIAlertAction *strong = [UIAlertAction actionWithTitle:@"超强风" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.workMode = ModeSuperStrongWind;
        }];
        UIAlertAction *weak = [UIAlertAction actionWithTitle:@"超微风" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.workMode = ModeSuperWeakWind;
        }];
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
        
        [alert addAction:sleep];
        [alert addAction:natural];
        [alert addAction:strong];
        [alert addAction:weak];
        [alert addAction:cancel];
        
        [self.navigationController presentViewController:alert animated:YES completion:nil];
    }
    return _alert;
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [_manager stopScan];
    
    [_manager startScan];
}

//隐藏导航栏的黑线
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (@available (iOS 10, *)) {
            if ([obj isKindOfClass:NSClassFromString(@"_UIBarBackground")]) {
                [obj.subviews firstObject].hidden = YES;
                
            }else {
                //iOS10之前使用的是_UINavigationBarBackground
                if ([obj isKindOfClass:NSClassFromString(@"_UINavigationBarBackground")]) {
                    [obj.subviews firstObject].hidden = YES;
                }
            }
        }
    }];
}

- (void)initCore
{
    _manager = [MinewModuleManager sharedInstance];
//    _manager.delegaate = self;
    
    _api = [MinewModuleAPI sharedInstance];
    
//    [_api dataReceive:^(id result, BOOL keepAlive) {
//        NSLog(@"receive==%@",result);
//    }];
    
    [_api dataNotify:^(id result, BOOL keepAlive) {
        NSLog(@"notify==%@",result);
        NSData *notifyData = (NSData *)result;
        if (notifyData.length) {
            Byte *testByte = (Byte *)[notifyData bytes];
            dataModel.key = testByte[1];
            dataModel.mode = testByte[2];
            dataModel.Wind_Speed = testByte[3];
            dataModel.Hand_Flag = testByte[4];
            dataModel.Dispaly_Flag = testByte[5];
            NSString *timingStr = [NSString stringWithFormat:@"%02x%02x",testByte[7],testByte[6]];
            uint16_t timing =  [[MinewCommonTool numberHexString:timingStr] integerValue];
            dataModel.Timing = timing;
            NSLog(@"得到的设备状态信息===%02x %02x %02x %02x %04x",dataModel.mode,dataModel.Wind_Speed,dataModel.Hand_Flag,dataModel.Dispaly_Flag,dataModel.Timing);
            
            [MinewCommonTool onMainThread:^{
                if (dataModel.key == 1) {
                    return ;
                }
                if (_isWriting) {
                    return ;
                }
                //更新风扇的状态
                [self updateViewState];
            }];
        }
    }];
    //start scan
    [_manager startScan];
    
    //获取设备的基本信息
    [self getBasicDeviceInfo];
}

#pragma mark --- 获取设备的基本信息
- (void)getBasicDeviceInfo {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self getDeviceMacAddress];
        [self getDeviceInfo];
        
        [self getDeviceStateInfo];
    });
}

- (void)showInfoViewVC
{
    BYInfoViewController *bvc = [[BYInfoViewController alloc] init];
    [self.navigationController pushViewController:bvc animated:YES];
}

#pragma mark --- 开启语音识别功能
- (IBAction)voiceRecognize:(UISwitch *)sender {
    if (sender.isOn) {
        [SVProgressHUD showSuccessWithStatus:@"您已开启语音识别"];
        [self wakeupConfiguration];

    }else {
        [SVProgressHUD showSuccessWithStatus:@"您已关闭语音识别"];
        
        [self.wakeupManager stopWakeup];
        [self.recongnizeManager stopRecognize];
    }
}

#pragma mark --- 摇头功能
- (IBAction)LeftRightRoute:(UISwitch *)sender {
    if (sender.isOn) {
        [SVProgressHUD showSuccessWithStatus:@"您已开启摇头功能"];
        _shakeState = ShakeYES;
    }else {
        [SVProgressHUD showSuccessWithStatus:@"您已关闭摇头功能"];
        _shakeState = ShakeNo;
    }
    
    [self setDeveiceState];
}

#pragma mark --- 定时开关
- (IBAction)limitTimeSwitch:(UISwitch *)sender {
    if (sender.isOn) {
        _workMode = ModeLimitedTiming;
        [SVProgressHUD showSuccessWithStatus:@"您已开启定时开关功能"];
        _isUserCloseTiming = NO;
    }else {
        _workMode = ModeNormal;
//        _limitedTime = 0;
        [SVProgressHUD showSuccessWithStatus:@"您已关闭定时开关功能"];
        _isUserCloseTiming = YES;

    }
    
    [self setDeveiceState];
}

#pragma mark --- 风扇总开关
- (IBAction)onOff:(UISwitch *)sender {
    if (sender.isOn) {
        [SVProgressHUD showSuccessWithStatus:@"您已开机"];
        //to be confirmed
        //需要恢复上次的状态吗？ 由notify给我的状态去设备吧!
        _workMode = ModeNormal;
        if (_limitedTime > 0) {
            if (!_isUserCloseTiming) {
                _workMode = ModeLimitedTiming;
                [_timingonOffSwitch setOn:YES];
                
            }
        }
    }else {
        [SVProgressHUD showSuccessWithStatus:@"您已关机"];
        //其他的按钮状态统一关闭
        [self.timingonOffSwitch setOn:NO];
        [_shakeSwitch setOn:NO];
        [_voiceSwitch setOn:NO];
        _workMode = ModeClose;
    }
    [self setDeveiceState];

}

#pragma mark ---- 获取设备的基本信息
- (void)getDeviceInfo {
    [_api sendData:@"0201" hex:YES completion:^(id result, BOOL keepAlive) {
        //when write with response,you can receive a result
//        NSLog(@"发送设备基本信息==%@,发送结果===%u",result,keepAlive);
        
        NSObject *data = result;
        NSString *dataString = [MinewCommonTool getDataString:data];
        NSRange range = NSMakeRange(4, 18);
        NSString *deviceInfoString = [dataString substringWithRange:range];
        NSString *device_id = [deviceInfoString substringWithRange:NSMakeRange(0, 8)];
        _api.lastModule.device_id = [MinewCommonTool reverseString:device_id];

        NSString *version = [deviceInfoString substringWithRange:NSMakeRange(8, 8)];
        _api.lastModule.version = [MinewCommonTool reverseString:version];

        NSString *pair_flag = [deviceInfoString substringWithRange:NSMakeRange(16, 2)];
        _api.lastModule.pair_flag = [[MinewCommonTool reverseString:pair_flag] boolValue];
        NSLog(@"测试设备基本信息===%@  %@  %@  %lu",deviceInfoString,_api.lastModule.device_id,_api.lastModule.version,_api.lastModule.pair_flag);

//        NSData *deviceData = (NSData *)result;
        
//        deviceBaseInfoModel.deviceId =
        
    }];
}

#pragma mark 获取设备的Mac地址
- (void)getDeviceMacAddress {
    [_api sendData:@"0204" hex:YES completion:^(id result, BOOL keepAlive) {
        //when write with response,you can receive a result
//        NSLog(@"发送设备基本信息==%@,发送结果===%u",result,keepAlive);
        NSObject *data = result;
        NSString *dataString = [MinewCommonTool getDataString:data];
        NSRange range = NSMakeRange(4, 12);
        NSString *macString = [dataString substringWithRange:range];
        NSString *reverseStr = [MinewCommonTool reverseString:macString];
        NSLog(@"得到的Mac===%@",reverseStr);
        _api.lastModule.macString = reverseStr;
    }];
}

#pragma mark --- 得到设备的状态信息
- (void)getDeviceStateInfo {
    
    [_api sendData:@"0202" hex:YES completion:^(id result, BOOL keepAlive) {
        //when write with response,you can receive a result
//        NSLog(@"发送设备状态信息==%@,发送结果===%u",result,keepAlive);
        [SVProgressHUD dismiss];
        NSData *data = (NSData *)result;
        Byte *testByte = (Byte *)[data bytes];
        dataModel.mode = testByte[2];
        dataModel.Wind_Speed = testByte[3];
        dataModel.Hand_Flag = testByte[4];
        dataModel.Dispaly_Flag = testByte[5];
        NSString *timingStr = [NSString stringWithFormat:@"%02x%02x",testByte[7],testByte[6]];
        uint16_t timing =  [[MinewCommonTool numberHexString:timingStr] integerValue];
        dataModel.Timing = timing;
//        NSLog(@"testByte[4]==%02x  testByte[5]==%02x",testByte[4],testByte[5]);
        NSLog(@"得到的设备状态信息===%02x %02x %02x %02x %04x ",dataModel.mode,dataModel.Wind_Speed,dataModel.Hand_Flag,dataModel.Dispaly_Flag,dataModel.Timing);
        
        [MinewCommonTool onMainThread:^{
            [self updateViewState];
        }];
    }];

}

#pragma mark --- 收到notify设备的信息时，更新设备的状态
- (void)updateViewState {
    _workMode = dataModel.mode ;
    _shakeState = dataModel.Hand_Flag;
    switch (dataModel.mode) {
        case ModeClose: // 关闭
        {
            [_timingonOffSwitch setOn:NO];
            [_onOffSwitch setOn:NO];
            _timeCusSlider.value = 0;
        }
            break;
        case ModeLimitedTiming: // 定时
        {
            _limitedTime = dataModel.Timing;//记录定时时间
            [_timingonOffSwitch setOn:YES];
            [_onOffSwitch setOn:YES];
        }
            break;
        case ModeNormal: // 正常
        {
            [_timingonOffSwitch setOn:NO];
            [_onOffSwitch setOn:YES];
            _timeCusSlider.value = 0;
        }
            break;
        case ModeSleepWind: // 睡眠风
        {
            [_speedModeSelectBtn setTitle:@"睡眠风" forState:UIControlStateNormal];
            _timeCusSlider.value = 0;
        }
            break;
        case ModeNatureWind: // 自然风
        {
            [_speedModeSelectBtn setTitle:@"自然风" forState:UIControlStateNormal];
            _timeCusSlider.value = 0;
        }
            break;
        case ModeSuperStrongWind: // 超强风
        {
            [_speedModeSelectBtn setTitle:@"超强风" forState:UIControlStateNormal];
            _timeCusSlider.value = 0;
        }
            break;
        case ModeSuperWeakWind: // 超微风
        {
            [_speedModeSelectBtn setTitle:@"超微风" forState:UIControlStateNormal];
            _timeCusSlider.value = 0;
        }
            break;
            
        default:
            break;
    }
    
    _fanSpeed = dataModel.Wind_Speed ;
    [MinewCommonTool onMainThread:^{
        _speedSlider.value = dataModel.Wind_Speed;
        _currentSpeedLabel.text = [NSString stringWithFormat:@"当前风速:%ld",(long)self.fanSpeed];
    }];
    
    switch (dataModel.Hand_Flag) {
        case ShakeYES:
        {
            [_shakeSwitch setOn:YES];
        }
            break;
        case ShakeNo:
        {
            [_shakeSwitch setOn:NO];
        }
            break;
        default:
            break;
    }
    
    if (dataModel.Timing) {
        
        NSInteger index = dataModel.Timing/30;
        if (dataModel.Timing % 30 >= 10) {
            index += 1;
        }
        if (index >= 12) {
            index = 12;
        }
        _timeCusSlider.value = index;
    }
    
}

#pragma mark --- 风的模式选择
- (IBAction)SpeedModeSelectAction:(UIButton *)sender {
    
    [self alert];
    
}

- (void)setDeveiceState {
    
    struct SendDataNodel dataModel = {0,0,0};
    dataModel.Command_id = 2;
    dataModel.key = 3;
    dataModel.mode = _workMode;
    dataModel.Wind_Speed = _fanSpeed;
    //当开关为关闭的状态时
//    if (_onOffSwitch.isOn == NO) {
//        dataModel.Wind_Speed = 0;
//    }
    dataModel.Hand_Flag = _shakeSwitch.isOn?ShakeYES:ShakeNo;
    dataModel.Dispaly_Flag = DisplayNO;//to be confirmed  不确定是做什么用的
//    dataModel.Timing = _timingonOffSwitch.isOn?_limitedTime:0;
    dataModel.Timing = _limitedTime;
    
    NSString *timing = [NSString stringWithFormat:@"%04x",dataModel.Timing];
    timing = [MinewCommonTool reverseString:timing];
    
    NSString *dataString = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%@",dataModel.Command_id,dataModel.key,dataModel.mode,dataModel.Wind_Speed
                            ,dataModel.Hand_Flag,dataModel.Dispaly_Flag,timing];
    NSLog(@"你发送的数据===%@",dataString);
    _isWriting = YES;
    [_api sendData:dataString hex:YES completion:^(id result, BOOL keepAlive) {
        //如果有回调的话
        _isWriting = NO;
        NSLog(@"在此处判断写入是否成功!");
    }];
}


#pragma mark ---- 语音相关操作
- (void)playOKAudio {
    NSLog(@"播放OK的语音");

    _isShouldINRecognize = NO;
    //    [self.recognizeManager stopListening];
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"ok" ofType:@"mp3"];
    self.player.soundPath = soundPath;
    [self.player startPlayingAlarmSound];
}

- (void)playHereAudio {
    NSLog(@"播放here的语音");
    _isShouldINRecognize = YES;

    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"im_here" ofType:@"mp3"];
    self.player.soundPath = soundPath;
    [self.player startPlayingAlarmSound];
}

- (void)audioPlayerDidFinished
{
    NSLog(@"完成播放");
    __weak BYScanDeviceViewController *weakSelf = self;
    [MinewCommonTool onMainThread:^{
        __strong BYScanDeviceViewController *strongSelf = weakSelf;
        
        if (_isShouldINRecognize) {
            NSLog(@"播放完here后的唤醒");
            [strongSelf.wakeupManager stopWakeup];
            
            [strongSelf recognizeConfiguration];
        }else {
            NSLog(@"播放完OK后的唤醒");
             [strongSelf wakeupConfiguration];
        }
    }];
    
}

//进入设置详情界面
- (IBAction)setupAction:(UIButton *)sender {
    
    [self showInfoViewVC];
}


@end
