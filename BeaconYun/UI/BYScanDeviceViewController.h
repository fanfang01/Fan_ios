//
//  BYScanViewController.h
//  BeaconYun
//
//  Created by SACRELEE on 2/24/17.
//  Copyright © 2017 MinewTech. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BYScanDeviceViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISwitch *voiceSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *timingonOffSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *leftRightSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *upDownSwitch;
@property (weak, nonatomic) IBOutlet UISlider *dateTimerSlider;
@property (weak, nonatomic) IBOutlet UISlider *speedSlider;
@property (weak, nonatomic) IBOutlet UISwitch *onOffSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *setSwitch;

@end