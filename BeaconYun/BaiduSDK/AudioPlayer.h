//
//  AudioPlayer.h
//  Tracker
//
//  Created by SACRELEE on 12/12/17.
//  Copyright © 2017 MinewTech. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AudioPlayerDelegate <NSObject>

- (void)audioPlayerDidFinished;

@end

@interface AudioPlayer : NSObject

@property (nonatomic, assign) BOOL immediate;

@property (nonatomic, strong) NSString *soundPath;

@property (nonatomic, assign) float duration;

@property (nonatomic, assign) BOOL playing;

@property (nonatomic, weak) id<AudioPlayerDelegate> delegate;

+ (float)currentVolume;

- (void)startPlayingAlarmSound;

- (void)stopPlayingAfterInterval:(NSInteger)interval;

- (void)stopPlayingAlarmSound;

@end

