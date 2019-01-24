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

//#import "WakeUpManager.h"

@interface BYScanDeviceViewController ()<MinewModuleManagerDelegate>

@property (nonatomic, strong) MinewModuleManager *manager;

@property (nonatomic, strong) NSArray *moduleArray;

@property (nonatomic, strong) NSMutableArray *tempArr;

@property (nonatomic, strong) MinewModuleAPI *api;

@property (nonatomic, assign) WorkMode workMode;
@property (nonatomic, assign) WorkSpeed workSpeed;
@property (nonatomic, assign) ShakeState shakeState;
@property (nonatomic, assign) DisplayState displayState;


@property (weak, nonatomic) IBOutlet UIButton *SpeedmodeSelect;
@property (weak, nonatomic) IBOutlet UISwitch *shakeSwitch;

@property (nonatomic, strong) UIAlertController *alert;

@property (nonatomic, assign) NSInteger fanSpeed;
@property (nonatomic, assign) NSInteger limitedTime;

@property (nonatomic, strong) CustomSlider *speedCusSlider;

@property (nonatomic, strong) CustomSlider *timeCusSlider;

//@property (nonatomic, strong) WakeUpManager *wakeupManager;
@end

@implementation BYScanDeviceViewController



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Fan";
    
    [self initCore];
    
    
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self timeCusSlider];
    
//    [self getDeviceMacAddress];
    
//    [self getDeviceInfo];
    
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [_api disconnect:nil];
}

//- (void)wakeupConfiguration {
//    _wakeupManager = [WakeUpManager sharedInstance];
//
//    [_wakeupManager startWakeup];
//
//    __weak BYScanDeviceViewController *weakSelf = self;
//    _wakeupManager.voiceWakeUp = ^(NSString * _Nonnull keywords) {
//
//        __strong BYScanDeviceViewController *strongSelf = weakSelf;
//
//        NSLog(@"识别到关键词:%@",keywords);
//        [strongSelf voiceToAdvertise:keywords];
//
//    };
//}

#pragma mark --- 语音发送广播
//后续 还可以更精准一点过滤   语音发送广播
- (void)voiceToAdvertise:(NSString *)key {
//    NSMutableArray *keyArr = [self getALLKeys];
//    NSString *recordKey = @"";
//    for (NSString *okey in keyArr) {
//        if ([okey containsString:key] || [key containsString:okey]) {
//            recordKey = okey;
//            NSInteger index = [keyArr indexOfObject:recordKey];
//
//
//        }
//    }
}


- (void)setWorkSpeed:(WorkSpeed)workSpeed
{
    _workSpeed = workSpeed;
    [self setDeveiceState];
    
    NSString *title = @"";
    switch (_workSpeed) {
        case SpeedSleepWind:
            title = @"睡眠风";
            break;
        case SpeedNatureWind:
            title = @"自然风";
            break;
        case SpeedSuperStrongWind:
            title = @"超强风";
            break;
        case SpeedSuperWeakWind:
            title = @"超微风";
            break;
        default:
            title = @"风行模式选择";
            break;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [_SpeedmodeSelect setTitle:title forState:UIControlStateNormal];
        [_SpeedmodeSelect setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    });

}

- (IBAction)speedSliderMoved:(UISlider *)sender {
    NSInteger index = sender.tag-300;
    float value = sender.value;
    
    NSInteger speed = value * 32;
    _fanSpeed = speed;
    
    _workSpeed = SpeedRealWind;
    [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"您已设定风扇转速%ld",speed]];

    [self setDeveiceState];

}

#pragma mark ---- Getter
- (CustomSlider *)timeCusSlider
{
    if (!_timeCusSlider) {
        CustomSlider *slider = [[CustomSlider alloc] initWithFrame:CGRectMake(0, 250, CGRectGetWidth(self.view.frame), 80)];
//
        [self.view addSubview:slider];
//        [slider mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.left.equalTo(self.timeLabel.mas_right).offset(30);
//            make.centerY.equalTo(self.timeLabel.mas_centerY);
//            make.right.equalTo(self.view.mas_right).offset(-15);
////            make.height.mas_equalTo(50);
//        }];

        _timeCusSlider = slider;
        slider.backgroundColor = [UIColor clearColor];
        slider.sliderBarHeight = 10;
        slider.numberOfPart = 13;
        slider.partColor = [UIColor cyanColor];
        slider.sliderColor = [UIColor redColor];
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
    if (value>0) {
        [_timingonOffSwitch setOn:YES];
    }
    _limitedTime = value *60;

    [self setDeveiceState];
}

- (UIAlertController *)alert
{
    if (!_alert) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请选择风的模式" message:@"" preferredStyle:UIAlertControllerStyleActionSheet];
        
        UIAlertAction *sleep = [UIAlertAction actionWithTitle:@"睡眠风" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.workSpeed = SpeedSleepWind;
            
        }];
        UIAlertAction *natural = [UIAlertAction actionWithTitle:@"自然风" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.workSpeed = SpeedNatureWind;
        }];
        UIAlertAction *strong = [UIAlertAction actionWithTitle:@"超强风" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.workSpeed = SpeedSuperStrongWind;
        }];
        UIAlertAction *weak = [UIAlertAction actionWithTitle:@"超微风" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            self.workSpeed = SpeedSuperWeakWind;
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
    _manager.delegaate = self;
    
    _api = [MinewModuleAPI sharedInstance];
    
    [_api dataReceive:^(id result, BOOL keepAlive) {
        NSLog(@"receive==%@",result);
    }];
    
    //start scan
    [_manager startScan];

}

- (void)infoButtonClick:(UIButton *)sender
{
    BYInfoViewController *bvc = [[BYInfoViewController alloc] init];
    [self.navigationController pushViewController:bvc animated:YES];
}

#pragma mark --- 开启语音识别功能
- (IBAction)voiceRecognize:(UISwitch *)sender {
    if (sender.isOn) {
        [SVProgressHUD showSuccessWithStatus:@"您已开启语音识别"];
        [self getDeviceInfo];
    }else {
        [SVProgressHUD showSuccessWithStatus:@"您已关闭语音识别"];
        [self getDeviceMacAddress];
    }
    //to be confirmed
}

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

- (IBAction)limitTimeSwitch:(UISwitch *)sender {
    if (sender.isOn) {
        _workMode = ModeLimitedTiming;
        [SVProgressHUD showSuccessWithStatus:@"您已开启定时开关功能"];

    }else {
        _workMode = ModeNormal;
        [SVProgressHUD showSuccessWithStatus:@"您已关闭定时开关功能"];

    }
}

#pragma mark --- 风扇总开关
- (IBAction)onOff:(UISwitch *)sender {
    if (sender.isOn) {
        [SVProgressHUD showSuccessWithStatus:@"您已开机"];
        //to be confirmed
        //需要恢复上次的状态吗？ 由notify给我的状态去设备吧!
        _workMode = ModeNormal;
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
        //when write with response,you can receive a result
        NSLog(@"发送设备基本信息==%@,发送结果===%u",result,keepAlive);
    }];
    
}

//获取设备的Mac地址
- (void)getDeviceMacAddress {
    [_api sendData:@"0204" hex:YES completion:^(id result, BOOL keepAlive) {
        //when write with response,you can receive a result
        NSLog(@"发送设备基本信息==%@,发送结果===%u",result,keepAlive);
        NSObject *data = result;
        NSString *dataString = [MinewCommonTool getDataString:data];
        NSRange range = NSMakeRange(4, 12);
        NSString *macString = [dataString substringWithRange:range];
        NSString *reverseStr = [MinewCommonTool reverseString:macString];
        NSLog(@"得到的Mac===%@",reverseStr);
        _api.lastModule.macString = reverseStr;
    }];
}


//风的模式选择
- (IBAction)SpeedModeSelectAction:(UIButton *)sender {
    [self alert];
    
}

- (void)setDeveiceState {
    struct SendDataNodel dataModel = {0,0,0};
    dataModel.Command_id = 2;
    dataModel.key = 3;
    dataModel.mode = _workMode;
    if (_workSpeed != SpeedRealWind) {
        dataModel.Wind_Speed = _workSpeed;
    }else {
        dataModel.Wind_Speed = _fanSpeed;
    }
    dataModel.Hand_Flag = _shakeSwitch.isOn?ShakeYES:ShakeNo;
    dataModel.Dispaly_Flag = DisplayNO;//to be confirmed  不确定是做什么用的
    dataModel.Timing = _timingonOffSwitch.isOn?_limitedTime:0;
    
    NSString *dataString = [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%04x",dataModel.Command_id,dataModel.key,dataModel.mode,dataModel.Wind_Speed
                            ,dataModel.Hand_Flag,dataModel.Dispaly_Flag,dataModel.Timing];
    NSLog(@"你发送的数据===%@",dataString);
    [_api sendData:dataString hex:YES completion:^(id result, BOOL keepAlive) {
        //如果有回调的话
        NSLog(@"在此处判断写入是否成功!");
    }];
}

@end
