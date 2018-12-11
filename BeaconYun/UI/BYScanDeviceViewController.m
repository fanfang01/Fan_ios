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
    
    //start scan
    [_manager startScan];

}

- (void)reloadTableView
{
    _moduleArray = [_manager.allModules copy];
    
#warning 添加RGB的测试
    //    if (!_tempArr) {
    //        _tempArr = [NSMutableArray array];
    //    }
    //    [_tempArr removeAllObjects];
    //
    //    for (MinewModule *module in _moduleArray) {
    //        if ([module.name isEqualToString:@"Minew_RGB"]) {
    //            [_tempArr addObject:module];
    //        }
    //    }
    //    _sectionModel.rowAtitude = _tempArr.count;
    
}

- (void)infoButtonClick:(UIButton *)sender
{
    BYInfoViewController *bvc = [[BYInfoViewController alloc]init];
    [self.navigationController pushViewController:bvc animated:YES];
}

@end
