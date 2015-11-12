//
//  VMRecorder.h
//  AVRecorder
//
//  Created by Subhash Sanjeewa on 9/8/15.
//  Copyright (c) 2015 Persystance Networks. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger, RecordFormat) {
    CAF,
    M4A
};

typedef void(^BlockPlayingProgress)(float progress, float currentTime);
typedef void(^BlockPlayingDone)(BOOL done);
typedef void(^BlockRecordingDone)(BOOL done);

@interface VMRecorder : UIView <AVAudioRecorderDelegate, AVAudioPlayerDelegate>
@property (strong, nonatomic) AVAudioRecorder *audioRecorder;
@property (strong, nonatomic) AVAudioPlayer *audioPlayer;

-(NSURL*)recorderUrl;
-(BOOL)record;
-(BOOL)recordingWithBlock:(BlockRecordingDone)block;
-(BOOL)isRecording;
-(BOOL)isPlaying;
-(void)play;
-(void)playWithURL:(NSURL*)url;
-(void)playWithData:(NSData*)data;
-(void)stop;
-(void)initializeRecorderM4A;
-(void)playerProgress:(BlockPlayingProgress)progress withDoneBlock:(BlockPlayingDone)done;
@end
