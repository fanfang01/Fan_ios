//
//  BYDeviceDetailViewController.m
//  BeaconYun
//
//  Created by SACRELEE on 3/2/17.
//  Copyright © 2017 MinewTech. All rights reserved.
//

#import "BYDeviceDetailViewController.h"
#import "BYCommonMacros.h"
#import "BYCommonTools.h"
#import "MinewModuleAPI.h"
#import "ColorPickerView.h"
#import <Masonry.h>
#import <SVProgressHUD.h>
#import "NSTimer+Blocks.h"

#define sWidth self.view.bounds.size.width
#define sHeight self.view.bounds.size.height

@interface BYDeviceDetailViewController ()

@property (nonatomic, strong) MinewModuleAPI *api;

@property (nonatomic, strong) NSTimer *timer;

@property (nonatomic, assign) NSInteger countMode;

@property (nonatomic, assign) NSInteger timeLast;

@end

@implementation BYDeviceDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initView];
    [self initHandler];
}

- (void)initView
{
    self.view.backgroundColor = [UIColor whiteColor];
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    // bottom
    CGFloat width = 50;

    NSArray *titles = @[@"开关", @"白光", @"定时"];
    NSArray *images = @[@"Power", @"White", @"Timer"];
    for ( NSInteger i = 0; i < 3; i ++) {
        
        CGFloat tiny = (sWidth - 200 - 50 * 3 ) / 2.f;
        
        UILabel *buttonLabel = [[UILabel alloc]init];
        [self.view addSubview:buttonLabel];
        [buttonLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.view).offset(  100 + ( width + tiny ) * i );
            make.size.mas_equalTo(CGSizeMake( width, 20));
            make.bottom.equalTo(self.view).offset(-20);
        }];
        buttonLabel.text = titles[i];
        buttonLabel.font = [UIFont systemFontOfSize:12.f];
        buttonLabel.textAlignment = NSTextAlignmentCenter;
        buttonLabel.textColor = [UIColor grayColor];
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.view addSubview:button];
        [button mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(buttonLabel);
            make.size.mas_equalTo(CGSizeMake(width, width));
            make.bottom.equalTo(buttonLabel.mas_top).offset(-10);
        }];
        button.tag = 100 + i;
        [button setImage:[UIImage imageNamed:images[i]] forState:UIControlStateNormal];
        button.layer.masksToBounds = YES;
        button.layer.cornerRadius = 25.f;
        button.layer.borderWidth = 0.5f;
        button.layer.borderColor = [UIColor grayColor].CGColor;
        [button addTarget:self action:@selector(configButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    
    // middle
    CGFloat height = width + 20 + 20 + 10 + 20;
    
    CALayer *line = [[CALayer alloc]init];
    line.frame = CGRectMake( 0, sHeight - height - 64.f, sWidth, 0.7);
    line.backgroundColor = [UIColor grayColor].CGColor;
    [self.view.layer addSublayer:line];
    
    for (NSInteger i = 0; i < 2; i ++) {
        
        UILabel *label = [[UILabel alloc]init];
        [self.view addSubview:label];
        [label mas_makeConstraints:^(MASConstraintMaker *make) {
            make.size.mas_equalTo(CGSizeMake( 20.f, 20.f));
            make.bottom.equalTo(self.view).offset( - (height + height / 2.f - 10));
            if (!i)
                make.left.equalTo(self.view).offset(40.f);
            else
                make.right.equalTo(self.view).offset(-40.f);
        }];
        
        label.text = !i? @"暗": @"亮";
        label.font = [UIFont systemFontOfSize:14.f];
        label.textColor = [UIColor grayColor];
        
        if (!i) {
            UISlider *slider = [[UISlider alloc]init];
            [self.view addSubview:slider];
            [slider mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.equalTo(self.view).offset(70);
                make.right.equalTo(self.view).offset(-70);
                make.bottom.equalTo(label).offset(5);
            }];
            slider.maximumValue = 100;
            slider.minimumValue = 0;
            slider.value = 45;
            slider.minimumTrackTintColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.00];
            [slider addTarget:self action:@selector(sliderClick:) forControlEvents:UIControlEventTouchUpInside| UIControlEventTouchCancel];
        }
    }
    
    
    // top
    UIView *topView = [[UIView alloc]init];
    [self.view addSubview:topView];
    [topView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-height * 2);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
    }];
    topView.backgroundColor =  [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.00];
    
    ColorPickerView *colorView = [[ColorPickerView alloc]init];
    [topView addSubview:colorView];
    [colorView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.mas_equalTo(CGSizeMake( sWidth * 0.8, sWidth * 0.8));
        make.center.equalTo(topView).mas_offset(CGPointMake( 0, -32));
    }];
    colorView.completionBlock = ^(NSString *byteString) {
        
        [self sendInstruction:[NSString stringWithFormat:@"0440%@", byteString]];
    };
    

    
    UITextView *textView = [[UITextView alloc]init];
    [self.view addSubview:textView];
    [textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
        make.bottom.equalTo(topView).offset(-10);
    }];
    textView.editable = NO;
    textView.scrollEnabled = NO;
    textView.selectable = NO;
    textView.backgroundColor = [UIColor clearColor];
    textView.tag = 300;
    textView.textContainerInset = UIEdgeInsetsMake( 0, 0, 0, 0);
    
    [self refreshTimerLabel];
}

- (void)initHandler
{
    _api = [MinewModuleAPI sharedInstance];
    [_api connect:nil completion:^(id result, BOOL keepAlive) {
        
        if ([((NSDictionary *)result)[@"state"] integerValue])
        {
            [SVProgressHUD showSuccessWithStatus:@"连接成功！"];
            return ;
        }
        
        UIAlertController *ac = [UIAlertController alertControllerWithTitle:nil message:@"连接失败" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *ok = [UIAlertAction actionWithTitle:@"好" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [_api disconnect:nil];
            [self.navigationController popViewControllerAnimated:YES];
        }];
        
        [ac addAction:ok];
        
        [self presentViewController:ac animated:YES completion:nil];
    }];
}

#pragma mark *************************Events
- (void)configButtonClick:(UIButton *)sender
{
    NSInteger tag = sender.tag % 100;
    
    NSString *ins = nil;
    
    switch (tag) {
        case 0:
        {
            ins = @"0400";
        }
            break;
        case 1:
        {
            ins = @"0410";
        }
            break;
        case 2:
        {
            _countMode ++;
            
            if (_countMode > 4)
                _countMode = 0;
            
            ins = [NSString stringWithFormat:@"0420%.2ld",(long)_countMode];
            
            [self fireTimer];
        }
            break;
            
        default:
            break;
    }
    
    if (ins)
        [self sendInstruction:ins];
    else
        [SVProgressHUD showErrorWithStatus:@"状态错误"];
    
}



- (void)sliderClick:(UISlider *)sender
{
    [self sendInstruction:[NSString stringWithFormat:@"0430%.2x",(unsigned int)sender.value]];
}


#pragma mark ************************Common
- (void)fireTimer
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    NSArray *arr = @[@0, @(15*60), @(30*60), @(60*60), @(120*60)];
    
    _timeLast = [arr[_countMode] integerValue];
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:1.0f block:^{
        
        _timeLast --;
        
        if (_timeLast == -1) {
            _countMode = 0;
            [_timer invalidate];
            _timer = nil;
        }
        [self refreshTimerLabel];
        
    } repeats:YES];
}

- (void)refreshTimerLabel
{
    UITextView *tv = [self.view viewWithTag:300];
    
    if (!_countMode) {
        tv.alpha = 0;
        return ;
    }
    
    
    NSString *timeCountString = [NSString stringWithFormat:@"%@%ld:%.2ld", NSLocalizedString(@"关闭倒计时\n", nil), _timeLast / 60, _timeLast % 60];
    
    NSMutableAttributedString *attString = [[NSMutableAttributedString alloc]initWithString:timeCountString];

    [attString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:16] range:NSMakeRange(0, timeCountString.length)];
    
    [attString addAttribute:NSFontAttributeName value:[UIFont systemFontOfSize:14.f] range:NSMakeRange( 0, 6)];
    [attString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange( 0, timeCountString.length)];
    
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc]init];
    style.alignment = NSTextAlignmentCenter;
    [attString addAttribute:NSParagraphStyleAttributeName value:style range:NSMakeRange( 0, timeCountString.length)];
    
    [tv setAttributedText:attString];
    [UIView animateWithDuration:0.5f animations:^{
        tv.alpha = 1.f;
    }];

}

- (void)sendInstruction:(NSString *)ins
{
    
   [SVProgressHUD showWithStatus:@"正在发送指令.."];
    self.view.userInteractionEnabled = NO;
    
   [_api sendData:ins hex:YES completion:^(id result, BOOL keepAlive) {
       [self showHUD:[result isEqualToString:@"1"]];
       self.view.userInteractionEnabled = YES;
   }];
    
}

- (void)showHUD:(BOOL)suc
{
    if (suc)
        [SVProgressHUD showSuccessWithStatus:@"指令已发送至设备"];
    else
        [SVProgressHUD showErrorWithStatus:@"指令发送失败"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
