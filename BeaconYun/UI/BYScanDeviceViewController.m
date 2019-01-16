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

@interface BYScanDeviceViewController ()<MinewModuleManagerDelegate>

@property (nonatomic, strong) MinewModuleManager *manager;

@property (nonatomic, strong) NSArray *moduleArray;

@property(nonatomic,strong) NSMutableArray *tempArr ;

@property (nonatomic, strong) MinewModuleAPI *api;

@end

@implementation BYScanDeviceViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Fan";
    
    [self initCore];
    
    
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
    BYInfoViewController *bvc = [[BYInfoViewController alloc]init];
    [self.navigationController pushViewController:bvc animated:YES];
}

- (IBAction)sliderMoved:(UISlider *)sender {
    NSInteger index = sender.tag-300;
    float value = sender.value;

    if (0 == index) {
        NSInteger spped = 32.0 * value;
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"您已设定定时时长%ld",spped]];
    }else if (1 == index) {
        NSInteger time = value * 720.0;
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"您已设定风扇转速%ld",time]];
    }
}

- (IBAction)voiceRecognize:(UISwitch *)sender {
    [SVProgressHUD showSuccessWithStatus:@"您已开启语音识别"];
}

- (IBAction)LeftRightRoute:(UISwitch *)sender {
    [SVProgressHUD showSuccessWithStatus:@"您已开启左右摇头"];
    
    [self getDeviceInfo];
}

- (IBAction)UpDownRoute:(UISwitch *)sender {
    [SVProgressHUD showSuccessWithStatus:@"您已开启上下摇头"];
}

- (IBAction)limitTimeSwitch:(UISwitch *)sender {
    [SVProgressHUD showSuccessWithStatus:@"您已开启定时开关功能"];
}

- (IBAction)onOff:(UISwitch *)sender {
    if (sender.isOn) {
        [SVProgressHUD showSuccessWithStatus:@"您已开机"];
    }else {
        [SVProgressHUD showSuccessWithStatus:@"您已关机"];
    }
}

- (void)getDeviceInfo {
    [_api sendData:@"0201" hex:YES completion:^(id result, BOOL keepAlive) {
        NSLog(@"发送设备基本==%@",result);
    }];
}

@end
