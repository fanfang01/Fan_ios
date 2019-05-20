//
//  AppDelegate.m
//  BeaconYun
//
//  Created by SACRELEE on 2/23/17.
//  Copyright © 2017 MinewTech. All rights reserved.
//

#import "AppDelegate.h"
#import "BYNavigationController.h"
#import "ScanConnectViewController.h"
#import <WeexSDK/WeexSDK.h>
#import "MinewModuleAPI.h"
#import "WXImgLoaderDefaultImpl.h"


@interface AppDelegate ()
@property (nonatomic, strong) UIImageView *navBarHairlineImageView;
@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

    
    ScanConnectViewController *scanVC = [[ScanConnectViewController alloc] init];
    BYNavigationController *nav = [[BYNavigationController alloc] initWithRootViewController:scanVC];
//    nvc.navigationBar.barTintColor = [UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.00];
    
    self.window = [[UIWindow alloc]initWithFrame:[UIScreen mainScreen].bounds];
    self.window.rootViewController = nav;
    self.window.backgroundColor = [UIColor whiteColor];
    
//    UINavigationBar *navigationBar = nvc.navigationController.navigationBar;
//    _navBarHairlineImageView = [self slnFindHairlineImageViewUnder:navigationBar];
//    _navBarHairlineImageView.hidden = YES;

    [self.window makeKeyAndVisible];
    
    [MinewModuleAPI sharedInstance];
    
    //
//    [nvc.navigationController.navigationBar setBackgroundImage:[[UIImage alloc] init] forBarMetrics:UIBarMetricsDefault];
//    [nvc.navigationController.navigationBar setShadowImage:[[UIImage alloc] init]];

//    [self initWeexSDK];
    

    // Override point for customization after application launch.
    return YES;
}

- (UIImageView *)slnFindHairlineImageViewUnder:(UIView *)view {
    if ([view isKindOfClass:UIImageView.class] && view.bounds.size.height <= 1.0) {
        return (UIImageView *)view;
    }
    
    for (UIView *subView in view.subviews) {
        UIImageView *imageView = [self slnFindHairlineImageViewUnder:subView];
        if (imageView) {
            return imageView;
        }
    }
    return nil;
}

- (void)initWeexSDK
{
    [WXAppConfiguration setAppGroup:@"Minew"];
    [WXAppConfiguration setAppName:@"MinewModule"];
    [WXAppConfiguration setAppVersion:@"1.0.0"];
    [WXAppConfiguration setExternalUserAgent:@"ExternalUA"];
    
    [WXSDKEngine initSDKEnvironment];
    
    
    [WXSDKEngine registerModule:@"minewModule" withClass:[MinewModuleAPI class]];

    
    [WXSDKEngine registerHandler:[WXImgLoaderDefaultImpl new] withProtocol:@protocol(WXImgLoaderProtocol)];
    //    [WXSDKEngine registerHandler:[WXEventModule new] withProtocol:@protocol(WXEventModuleProtocol)];
    
    [WXSDKEngine registerComponent:@"select" withClass:NSClassFromString(@"WXSelectComponent")];
    //    [WXSDKEngine registerModule:@"event" withClass:[WXEventModule class]];
    
    //#if !(TARGET_IPHONE_SIMULATOR)
    //    [self checkUpdate];
    //#endif
    //
    //#ifdef DEBUG
    //    [self atAddPlugin];
        [WXDebugTool setDebug:YES];
        [WXLog setLogLevel:WXLogLevelDebug];
    //
    //#ifndef UITEST
    //    [[ATManager shareInstance] show];
    //#endif
    //#else
    //    [WXDebugTool setDebug:NO];
    //    [WXLog setLogLevel:WXLogLevelError];
    //#endif
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
