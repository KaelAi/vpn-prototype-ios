//
//  AudioUtility.h
//  PFIMCLient
//
//  Created  on 8/1/12.
//  Copyright (c) 2012 Dington. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AVFoundation/AVAudioPlayer.h>

@interface AudioUtility : NSObject<AVAudioSessionDelegate, AVAudioPlayerDelegate>

@property(nonatomic, getter = isHeadsetPluggedIn)BOOL headsetPluggedIn;
@property(nonatomic)BOOL isShouldKeepBuzzing;
@property(nonatomic)BOOL isAudioSessionInterruptionBegin;


+ (AudioUtility*)sharedAudioUtility;
- (void)configureAudioSession;
- (BOOL)isHeadsetPluggedIn;
- (BOOL)isAudioRouteTo:(NSString *)audioRoute;
- (BOOL)isSpeakerOpened;
- (BOOL)isAudioRouteToReceiver;
- (BOOL)isAudioRouteToHeadset;
- (void)openSpeaker;
- (void)closeSpeaker;
- (BOOL)silenced;
- (void)playNotifySound:(NSString*)byPath;
- (void)playNotifySound:(NSString*)byName withType:(NSString*)type;
- (void)startVibrate;
- (void)stopVibrate;
- (void)applicationDidBecomeActive;
- (void)playSoundFile:(NSString*)filePath;
- (void)playSoundByName:(NSString*)name ofType:(NSString*)type;
- (void)playEmptySound;
- (void)stopPlayersSound;

- (void)setAudioSessionCategory:(NSString *)category;
- (void)setVolume:(float)volume;
- (float)volume;

@end
