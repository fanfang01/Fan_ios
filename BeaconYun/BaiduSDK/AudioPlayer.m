//
//  AudioPlayer.m
//  Tracker
//
//  Created by SACRELEE on 12/12/17.
//  Copyright © 2017 MinewTech. All rights reserved.
//

#import "AudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>

@interface AudioPlayer ()<AVAudioPlayerDelegate>

@property (nonatomic, strong) AVAudioPlayer *player;

@property (nonatomic, strong) AVURLAsset *asset;

@property (nonatomic, assign) NSInteger endInterval;

@property (nonatomic, strong) NSTimer *endTimer;

@property (nonatomic, assign) NSInteger timeCount;

@property (nonatomic, assign) float lastVolume;


@end

@implementation AudioPlayer


- (AudioPlayer *)init
{
    if (self = [super init])
    {
        
    }
    
    return self;
}

- (void)setSoundPath:(NSString *)soundPath
{
    _soundPath = soundPath;
    NSURL *url = [NSURL fileURLWithPath:soundPath];
    
    _asset = [AVURLAsset assetWithURL:url];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
    _player.delegate = self;
    
    [[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:nil];
}

+ (float)currentVolume
{
    return [AVAudioSession sharedInstance].outputVolume;
}

- (BOOL)playing {
    return _player.isPlaying;
}

- (void)setDuration:(float)duration {
    
    _duration = duration;
    
    
//    if (_asset) {
//        CMTime currentCT = _asset.duration;
//        float currentDura = CMTimeGetSeconds(currentCT);
//        
//        AVMutableComposition *composition = [AVMutableComposition composition];
//        AVMutableCompositionTrack *audioTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
//        
//        AVAssetTrack *assetTrack = [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, <#CMTime duration#>) ofTrack:<#(nonnull AVAssetTrack *)#> atTime:<#(CMTime)#> error:<#(NSError *__autoreleasing  _Nullable * _Nullable)#>]
//        
//    }
//    else
//        NSLog(@"Null Asset, operation incorrect.");
}

- (void)startPlayingAlarmSound
{
//    [GlobalManager executeOnMain:^{
        NSError *error;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
        [[AVAudioSession sharedInstance] setActive:YES error:&error];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED < 110000
    
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
//    }];
  
#else
    MPRemoteCommandCenter *center = [MPRemoteCommandCenter sharedCommandCenter];
    [center.pauseCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [_player stop];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [center.playCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        return MPRemoteCommandHandlerStatusSuccess;
    }];
    
    [center.stopCommand addTargetWithHandler:^MPRemoteCommandHandlerStatus(MPRemoteCommandEvent * _Nonnull event) {
        [_player stop];
        return MPRemoteCommandHandlerStatusSuccess;
    }];
#endif
    
    _player.numberOfLoops = 0;

    if (!_immediate) {
        _lastVolume = _player.volume;
//        _player.volume = 0;
    }
    
    _player.currentTime = 0;
    [_player play];
}

- (void)stopPlayingAfterInterval:(NSInteger)interval
{
    _endInterval = interval;
    _timeCount = 0;
    if (_endTimer) {
        [_endTimer invalidate];
        _endTimer = nil;
    }
    
    _endTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(tryStop) userInfo:nil repeats:YES];
}

- (void)tryStop {
   
    if (!_immediate && _timeCount == 3 ) {
        _player.volume = _lastVolume;
    }
    
    NSLog(@"time count %ld", (long)_timeCount);
    
    _timeCount++;
    if (_timeCount >= _endInterval) {
        [self stopPlayingAlarmSound];
    }
}

- (void)stopPlayingAlarmSound
{
    if (_endTimer) {
        [_endTimer invalidate];
        _endTimer = nil;
    }
    
//    if (_player.isPlaying)
//    {
//        [_player stop];
//    }
    [_player stop];

}

-(BOOL)isPlaying
{
    return _player.isPlaying;
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
    NSLog(@"audioPlayerDidFinishPlaying");
    [_player stop];
    
    if ([self.delegate respondsToSelector:@selector(audioPlayerDidFinished)]) {
        [self.delegate audioPlayerDidFinished];
    }
}

@end

