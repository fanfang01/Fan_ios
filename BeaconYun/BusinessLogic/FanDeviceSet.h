//
//  FanDeviceSet.h
//  BeaconYun
//
//  Created by 樊芳 on 2019/1/16.
//  Copyright © 2019 MinewTech. All rights reserved.
//

#ifndef FanDeviceSet_h
#define FanDeviceSet_h


typedef NS_ENUM(NSUInteger, WorkMode) {
    ModeClose = 0,
    ModeNormal,
    ModeLimitedTiming,
    ModeSleepWind = 6,
    ModeNatureWind = 5,
    ModeSuperStrongWind = 3,
    ModeSuperWeakWind = 4,
};

typedef NS_ENUM(NSUInteger, ShakeState) {
    ShakeNo = 0,
    ShakeYES = 1,
};

typedef NS_ENUM(NSUInteger, DisplayState) {
    DisplayNO = 0,
    DisplayYES = 1,
};


#endif /* FanDeviceSet_h */
