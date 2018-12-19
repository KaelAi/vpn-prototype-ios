//
//  AudioUtility.m
//  PFIMCLient
//
//  Created  on 8/1/12.
//  Copyright (c) 2012 Dington. All rights reserved.
//

#import "AudioUtility.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "NotificationName.h"
#import "NLog.h"
#import "ServiceMgr.h"
#import <AVFoundation/AVAudioPlayer.h>
#import "NUtils.h"
#import "PcmAudioPlayer.h"

static void MyAudioServicesSystemSoundCompletionProc (
                                               SystemSoundID  ssID,
                                               void           *clientData
                                               );

static void audioRouteChangeListenerCallback( void                      *inClientData,
                                           AudioSessionPropertyID    inID,
                                           UInt32                    inDataSize,
                                           const void                *inData);

static void audioServerDiedListener(void *inClientData,
                                    AudioSessionPropertyID inID,
                                    UInt32 inDataSize,
                                    const void *inData);


@interface AudioUtility()
@property(nonatomic, retain)NSMutableArray *audioPlayers; 
- (BOOL)EnableSpeaker:(BOOL)bEnable;


@end

@implementation AudioUtility

@synthesize headsetPluggedIn = headsetPluggedIn_;
@synthesize isShouldKeepBuzzing = isShouldKeepBuzzing_;
@synthesize isAudioSessionInterruptionBegin = isAudioSessionInterruptionBegin_;
@synthesize audioPlayers = audioPlayers_;

+ (AudioUtility*)sharedAudioUtility
{
    static dispatch_once_t onceToken;
    static AudioUtility *sharedInstance = nil;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[AudioUtility alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if(self){
        
        [self configureAudioSession];
        audioPlayers_ = [[NSMutableArray alloc] init];
        
    }
    
    return self;
}

- (void)dealloc
{
    self.audioPlayers = nil;
    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_AudioRouteChange, audioRouteChangeListenerCallback, self);
    AudioSessionRemovePropertyListenerWithUserData(kAudioSessionProperty_ServerDied, audioServerDiedListener, self);
    [super dealloc];
}

- (BOOL)isHeadsetPluggedIn
{
    return headsetPluggedIn_;
}

- (BOOL)isSpeakerOpened
{
    return [self isAudioRouteTo:@"Speaker"];
}

- (BOOL)isAudioRouteToReceiver
{
    return [self isAudioRouteTo:@"Receiver"];
}

- (BOOL)isAudioRouteToHeadset
{
    return [self isAudioRouteTo:@"Head"];
}

- (BOOL)isAudioRouteTo:(NSString *)audioRoute
{
    UInt32 routeSize = sizeof (CFStringRef);
    CFStringRef route;
    
    OSStatus error = AudioSessionGetProperty (kAudioSessionProperty_AudioRoute,
                                              &routeSize,
                                              &route);
    
    /* Known values of route:
     * "Headset"
     * "Headphone"
     * "Speaker"
     * "SpeakerAndMicrophone"
     * "HeadphonesAndMicrophone"
     * "HeadsetInOut"
     * "ReceiverAndMicrophone"
     * "Lineout"
     */
    
    if (!error && (route != NULL)) {
        
        NSString* routeStr = (NSString*)route;
        
        NSRange audioRouteRange = [routeStr rangeOfString : audioRoute];
        
        [routeStr release];//route is a copy string ,need release it
        
        if (audioRouteRange.location != NSNotFound) return YES;
        
    }
    
    return NO;
}

- (void)configureAudioSession
{
    LogI(@"configureAudioSession");
    
    // initialize
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setDelegate:self];
    
    OSStatus err = noErr;
    AudioSessionAddPropertyListener (kAudioSessionProperty_AudioRouteChange,
                                     audioRouteChangeListenerCallback,
                                     self);
    
    /* kAudioSessionProperty_ServerDied indicates if the audio server has died (indicated by a nonzero UInt32 value) or is still running (a value of 0).
     This value is available to your app only by way of a property listener callback function.
     */
    
    // register a listener for kAudioSessionProperty_ServerDied
    err = AudioSessionAddPropertyListener(kAudioSessionProperty_ServerDied, audioServerDiedListener, self);
    
    // check if is headset plugged in
    headsetPluggedIn_ = [self isAudioRouteToHeadset];
    isShouldKeepBuzzing_ = NO;
    isAudioSessionInterruptionBegin_ = NO;
    
    
    
}

- (void)openSpeaker
{
    [self EnableSpeaker : YES];
}

- (void)closeSpeaker
{ 
    [self EnableSpeaker : NO];
}

- (void)setAudioSessionCategory:(NSString *)category
{
	if(category != nil)
    	LogI(@"set category (%@)", category);
    
    NSError *error = nil;
    
    [[AVAudioSession sharedInstance] setCategory:category  error:&error];
    if(error)
    {
        LogE(@"set category error(%@)", [error localizedDescription]);
    }
    
    
}

- (void)setVolume:(float)volume
{
    [[MPMusicPlayerController applicationMusicPlayer] setVolume:volume];
}

- (float)volume
{
    return [[MPMusicPlayerController applicationMusicPlayer] volume];
}

#pragma mark private method

- (BOOL)EnableSpeaker : (BOOL) bEnable
{
    OSStatus result = 0;
    if(bEnable)
    {
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_Speaker;        
        result = AudioSessionSetProperty (
                                          kAudioSessionProperty_OverrideAudioRoute,
                                          sizeof (audioRouteOverride),
                                          &audioRouteOverride
                                          );
        
        if(result != kAudioSessionNoError)
        {
            Assert(0);
            LogE(@"AudioSessionGetProperty(OverrideAudioRoute to speaker instead of receiver) get error %d",result );
            
            return NO;
        }
        
    }
    else
    {
        
        UInt32 audioRouteOverride = kAudioSessionOverrideAudioRoute_None;        
        result = AudioSessionSetProperty (
                                          kAudioSessionProperty_OverrideAudioRoute,
                                          sizeof (audioRouteOverride),
                                          &audioRouteOverride
                                          );
        
        
        if(result != kAudioSessionNoError)
        {
            Assert(0);
            LogE(@"AudioSessionGetProperty(OverrideAudioRoute to normal receiver) get error %d",result );
            
            return NO;
        }        
    }
    
    return YES;    
}

- (BOOL)silenced
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#endif
    
    CFStringRef state;
    UInt32 propertySize = sizeof(state);
    OSStatus status = AudioSessionGetProperty(kAudioSessionProperty_AudioRoute, &propertySize, &state);
    if(status != kAudioSessionNoError)
    {
        LogE(@"AudioSessionGetProperty get error %d",status );
        return NO;
    }
    
    if(CFStringGetLength(state) > 0)
    {
        return NO;
    }
    else {
        return YES;
    }
    
}

- (void)playNotifySound:(NSString*)byPath
{
    //NSString *path = [[NSBundle mainBundle] pathForResource:@"notify" ofType:@"m4a"];
    SystemSoundID soundID;
    
	//Get a URL for the sound file
	NSURL *filePath = [NSURL fileURLWithPath:byPath isDirectory:NO];
    
	//Use audio sevices to create the sound
	AudioServicesCreateSystemSoundID((CFURLRef)filePath, &soundID);
    
    // add system sound completion callback
    AudioServicesAddSystemSoundCompletion(soundID, NULL, NULL, MyAudioServicesSystemSoundCompletionProc, self);
    
	//Use audio services to play the sound
	AudioServicesPlaySystemSound(soundID); 
}

- (void)playNotifySound:(NSString*)byName withType:(NSString*)type
{
    NSString *path = [[NSBundle mainBundle] pathForResource:byName ofType:type];
    Assert(path != nil);
    if(path == nil)
        return;
    
    [self playNotifySound:path];
}

- (void)startVibrate
{
    if(isShouldKeepBuzzing_)
        return;
    
    isShouldKeepBuzzing_ = YES;
    AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, MyAudioServicesSystemSoundCompletionProc, self);
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    
}

- (void)stopVibrate
{
    isShouldKeepBuzzing_ = NO;
}

- (void)applicationDidBecomeActive
{
    LogI(@"Audio utility application become active");
    
    if([[ServiceMgr getCallingMgr] isTelephoneyCallOngoing])
    {
        LogI(@"Telephony call is going");
        return;
    }
    
    [self endInterruption];
    
}

- (void)playSoundByName:(NSString *)name ofType:(NSString *)type
{
    NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:type];
    Assert(path != nil);
    if(path == nil)
        return;
    
    [self playSoundFile:path];
    
}

- (void)playSoundFile:(NSString *)filePath
{
    if(filePath == nil)
        return;
    
    NSURL *url = [[NSURL alloc] initFileURLWithPath:filePath isDirectory:NO];
    
    NSError *error = nil;
    AVAudioPlayer *avPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
    
    if(error)
    {
        LogE(@"create player err(%@)", [error description]);
        [avPlayer release];
        [url release];
        return;
    }

    if (iPhoneModel)
    {
        avPlayer.volume = 1.0; //volume gain set to maximal
    }
    [avPlayer prepareToPlay];
    
    float currentVolume = [NUtils getSystemVolume];
    
    [avPlayer setVolume: currentVolume];
    
    [avPlayer setNumberOfLoops:0];
    
    
    [avPlayer setDelegate:self];
    
    [avPlayer play];
    
    [url release];
    
    [audioPlayers_ addObject:avPlayer];
    [avPlayer release];
}

- (void)stopPlayersSound
{
    for (AVAudioPlayer * aPalyer in audioPlayers_) {
        [aPalyer stop];
    }
    [audioPlayers_ removeAllObjects];

}
- (void)playEmptySound
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            NSString *emptySoundPath = [[NSBundle mainBundle] pathForResource:@"empty" ofType:@"pcm"];
            if(emptySoundPath == nil)
            {
                LogE(@"empty sound path is nil");
                return;
            }
            
            PcmAudioPlayer *pcmPlayer = [[PcmAudioPlayer alloc] initWithFilePath:emptySoundPath type:enum_pcm_format_8kHz];
            
            [pcmPlayer play:0 endPos:300];
            
            int64_t delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_current_queue(), ^(void){
                [pcmPlayer stop];
            });
            
            [pcmPlayer release];
        });
       
    });
}



#pragma mark AVAudioPlayerDelegate
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [audioPlayers_ removeObject:player];
}

#pragma mark AVAudioSessionDelegate

- (void)beginInterruption
{
    LogI(@"Audio session begin interruption");
    [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_SESSION_BEGIN_INTERRUPTION_NOTIFICATION object:nil userInfo:nil];
    isAudioSessionInterruptionBegin_ = YES;
}

- (void)endInterruption
{
    LogI(@"Audio session end interruption isBegin(%d)", isAudioSessionInterruptionBegin_);
    
    if(isAudioSessionInterruptionBegin_)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:AUDIO_SESSION_END_INTERRUPTION_NOTIFICATION object:nil userInfo:nil];
        isAudioSessionInterruptionBegin_ = NO;
    }
}

@end


void audioRouteChangeListenerCallback( void                      *inClientData,
                                      AudioSessionPropertyID    inID,
                                      UInt32                    inDataSize,
                                      const void                *inData)
{
    
    AudioUtility *auidoUtility = inClientData;
    
    CFDictionaryRef       routeChangeDictionary = inData;
    
    CFNumberRef routeChangeReasonRef =
    CFDictionaryGetValue (routeChangeDictionary,
                          CFSTR (kAudioSession_AudioRouteChangeKey_Reason));
    
    SInt32 routeChangeReason;
    
    CFNumberGetValue (routeChangeReasonRef, kCFNumberSInt32Type, &routeChangeReason);
    NSString * name = [[AVAudioSession sharedInstance] category];
    LogI(@"audio route change callback,reason:%d,category:%@",routeChangeReason,name);

    if (routeChangeReason == kAudioSessionRouteChangeReason_OldDeviceUnavailable)
    {
        LogI(@"old device unavailable");
        // Headset is unplugged..
        if(![auidoUtility isAudioRouteToHeadset])
        {
            LogI(@"headset plug out");
            [auidoUtility setHeadsetPluggedIn:NO];
            [[NSNotificationCenter defaultCenter] postNotificationName:HEADSET_UNPLUGGED_NOTIFICATION object:nil userInfo:nil];
        }
    }
    if (routeChangeReason == kAudioSessionRouteChangeReason_NewDeviceAvailable)
    {
        LogI(@"new device available");
        if([auidoUtility isAudioRouteToHeadset])
        {
            LogI(@"headset plug in");
            // Headset is plugged in..    
            [auidoUtility setHeadsetPluggedIn:YES];
            [[NSNotificationCenter defaultCenter] postNotificationName:HEADSET_PLUGGEDIN_NOTIFICATION object:nil userInfo:nil];
        }
    }
}

void audioServerDiedListener(void *inClientData,
                            AudioSessionPropertyID inID,
                            UInt32 inDataSize,
                            const void *inData)
{
    LogE(@"audio server died");
    AudioUtility *audioUtility = inClientData;
    int64_t delayInSeconds = 10.0;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        LogI(@"config audio session");
        [audioUtility configureAudioSession];
    });
}

void MyAudioServicesSystemSoundCompletionProc (
                                               SystemSoundID  ssID,
                                               void           *clientData
                                               )
{
    AudioUtility *audioUtility = clientData;
    if(ssID == kSystemSoundID_Vibrate)
    {
        if(audioUtility.isShouldKeepBuzzing)
        {
            double delayInSeconds = 1.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            });
            
        }
        else 
        {
            AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate);
        }
        return;
    }
    
    AudioServicesDisposeSystemSoundID(ssID);
}

