//
//  BYInfoViewController.m
//  BeaconYun
//
//  Created by SACRELEE on 3/9/17.
//  Copyright © 2017 MinewTech. All rights reserved.
//

#import "BYInfoViewController.h"
#import "BYCommonMacros.h"

@interface BYInfoViewController ()

@end

@implementation BYInfoViewController
{
    UIScrollView *_scrollView;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initGUI];
    //隐藏返回按钮文字 此处会导致self.title不居中 有偏移
    //    [[UIBarButtonItem appearance] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, -60) forBarMetrics:UIBarMetricsDefault];
}

- (void)initGUI
{
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    _scrollView = scrollView;
    scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:scrollView];
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = NSLocalizedString(@"About us", nil);
    
    UIImageView *logoView = [[UIImageView alloc]init];
    [scrollView addSubview:logoView];
    [logoView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(128.f, 128.f));
        make.center.equalTo(self.view).centerOffset(CGPointMake(0, -sScreenHeight / 3));
    }];
    logoView.image = [UIImage imageNamed:@"info_logo_socket_128dp_"];
    logoView.layer.cornerRadius = 10;
    logoView.layer.masksToBounds = YES;
    
    UILabel *appNameLabel = [[UILabel alloc]init];
    [scrollView addSubview:appNameLabel];
    [appNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.top.equalTo(logoView.mas_bottom).offset(24.f);
        make.centerX.equalTo(logoView.mas_centerX);
        make.height.mas_equalTo(35);
    }];
    appNameLabel.text = NSLocalizedString(@"ASK Bluetooth Switch", nil);
    appNameLabel.textColor = [BYCommonTools colorWithRgb:@"#212121"];
    appNameLabel.font = [UIFont systemFontOfSize:20];
    appNameLabel.textAlignment = NSTextAlignmentCenter;
    
    UILabel *versionLabel = [[UILabel alloc] init];
    [scrollView addSubview:versionLabel];
    [versionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.centerX.equalTo(appNameLabel.mas_centerX);
        make.top.equalTo(appNameLabel.mas_bottom).offset(5.f);
        make.height.mas_equalTo(30);
    }];
    versionLabel.text = [@"Version:" stringByAppendingFormat:@"%@",[NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"]];
    versionLabel.textColor = [BYCommonTools colorWithRgb:@"#999999"];
    versionLabel.textAlignment = NSTextAlignmentCenter;
    
    
    //    NSString *stringPart = NSLocalizedString(@"本应用的可交互唤醒词\n\r1.hello light\n2.小可小可\n\r唤醒后，支持的命令词\n1.打开灯光:(turn on the light);\n2.关闭灯光:(turn off the light);\n3.增大亮度:(increase the brightness);\n4.减小亮度:(reduce the brightness)\n5.打开某个具体的灯光（灯光的名字必须是能识别的英文单词,eg,turn on the bedroom light）;", nil);
    //    NSRange firstRange = [stringPart rangeOfString:@"1."];
    //
    //    NSMutableAttributedString *attPart = [[NSMutableAttributedString alloc] initWithString:stringPart];
    //    NSMutableParagraphStyle *paragraph = [[NSMutableParagraphStyle alloc] init];
    //    [paragraph setFirstLineHeadIndent:10];
    //
    //    [attPart addAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:20],NSForegroundColorAttributeName:[BYCommonTools colorWithRgb:@"#212121"],NSParagraphStyleAttributeName:paragraph} range:NSMakeRange(0, firstRange.location)];
    //    [attPart addAttributes:@{NSFontAttributeName:[UIFont systemFontOfSize:16],NSForegroundColorAttributeName:[BYCommonTools colorWithRgb:@"#757575"]} range:NSMakeRange(firstRange.location, stringPart.length-firstRange.location)];
    
    UITextView *textView = [[UITextView alloc] init];
    [scrollView addSubview:textView];
    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake(ScreenWidth-100, 200));
        make.centerX.equalTo(logoView.mas_centerX);
        make.top.equalTo(versionLabel.mas_bottom).offset(50);
    }];
    textView.editable = NO;
    textView.scrollEnabled = NO;
    textView.selectable = NO;
    textView.text = @"本应用的可交互唤醒词\n\r1.小奥小奥（用于发送命令前的唤醒）\n2.工作模式 \n3.关机模式 \n\r唤醒后，支持的命令词\n\r1.定时时长相关(1.增加定时 2.减小定时 3.定时n小时,n=1-12);\n2.风扇的档位（1.上一档 2.下一档 3.第n档，n=1-32）;\n3.摇头相关(1.开启摇头（打开摇头） 2. 停止摇头（关闭摇头）);";
    //    [textView setAttributedText:attPart];
    textView.textContainerInset = UIEdgeInsetsMake(0, 0, 0, 0);
    
    for (UIView *view in self.view.subviews) {
        if ([view isKindOfClass:[UITextView class]]) {
            NSLog(@"frame==%@",NSStringFromCGRect(view.frame));
            NSLog(@"添加成功TextView这个视图");
        }
    }
    
    UILabel *copyrightLabel = [[UILabel alloc] init];
    [scrollView addSubview:copyrightLabel];
    [copyrightLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(textView.mas_bottom).offset(60);
        make.height.mas_equalTo(30);
    }];
    copyrightLabel.text = NSLocalizedString(@"Copyright ASK. All Rights Reserved", nil);
    copyrightLabel.textColor = [UIColor grayColor];
    copyrightLabel.textAlignment = NSTextAlignmentCenter;
}


@end

