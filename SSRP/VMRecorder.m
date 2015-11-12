//
//  VMRecorder.m
//  AVRecorder
//
//  Created by Subhash Sanjeewa on 9/8/15.
//  Copyright (c) 2015 Persystance Networks. All rights reserved.
//

#import "VMRecorder.h"

@implementation VMRecorder

BlockPlayingProgress playingProgerss;
BlockPlayingDone playingDone;
BlockRecordingDone recordingBlock;

NSTimer* timerRecorder;

- (instancetype)init
{
    self = [super init];
    if (self) {
        timerRecorder = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(playingProgress:) userInfo:nil repeats:YES];
    }
    return self;
}

- (NSURL *)getFilePathCAF {
    NSArray *dirPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *docsDir = dirPaths[0];
    NSString *soundFilePath = [docsDir stringByAppendingPathComponent:@"sound.caf"];
    return [NSURL fileURLWithPath:soundFilePath];
}

- (NSURL *)getFilePathM4A {
    NSArray *pathComponents = [NSArray arrayWithObjects: [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"sound.m4a", nil];
    return [NSURL fileURLWithPathComponents:pathComponents];
}

- (NSURL *)getFilePathWAV {
    NSArray *pathComponents = [NSArray arrayWithObjects: [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject], @"sound.wav", nil];
    return [NSURL fileURLWithPathComponents:pathComponents];
}

-(void)initializeRecorderWAV {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    NSMutableDictionary* recordSetting = [[NSMutableDictionary alloc]init];
    [recordSetting setValue :[NSNumber  numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:11025.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    [recordSetting setValue:[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:[self recorderUrl] settings:recordSetting error:NULL];
    _audioRecorder.delegate = self;
    _audioRecorder.meteringEnabled = YES;
    [_audioRecorder prepareToRecord];
}

-(void)initializeRecorderM4A {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    
    NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
    [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatMPEG4AAC] forKey:AVFormatIDKey];
    [recordSetting setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    [recordSetting setValue:[NSNumber numberWithInt: 2] forKey:AVNumberOfChannelsKey];
    
    NSError* error;
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:[self recorderUrl] settings:recordSetting error:&error];
    
    if (error) {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        _audioRecorder.delegate = self;
        _audioRecorder.meteringEnabled = YES;
        [_audioRecorder prepareToRecord];
    }
}

-(NSURL*)initializeRecordCAF {
    NSURL *soundFileURL = [self recorderUrl];
    NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:AVAudioQualityMin], AVEncoderAudioQualityKey,
                                    [NSNumber numberWithInt:16],AVEncoderBitRateKey,
                                    [NSNumber numberWithInt: 2], AVNumberOfChannelsKey,
                                    [NSNumber numberWithFloat:44100.0], AVSampleRateKey,
                                    nil];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                        error:nil];
    NSError* error;
    _audioRecorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL settings:recordSettings error:&error];
    
    if (error) {
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [_audioRecorder prepareToRecord];
    }
    
    return soundFileURL;
}

-(BOOL)recordingWithBlock:(BlockRecordingDone)block {
    recordingBlock = block;
    [self record];
    return YES;
}

-(BOOL)record {
    return  [_audioRecorder record];
}

-(BOOL)isRecording {
    return _audioRecorder.recording;
}

-(BOOL)isPlaying {
    return _audioPlayer.isPlaying;
}

-(void)play {
    if (!_audioRecorder.recording) {
        NSError *error;
        
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:_audioRecorder.url error:&error];
        _audioPlayer.delegate = self;
        
        if (error) NSLog(@"Error: %@", [error localizedDescription]);
        else [_audioPlayer play];
    }
}

-(void)playWithData:(NSData *)data {
    [_audioRecorder stop];
    [_audioPlayer stop];
    
    NSError *error;
    
    _audioPlayer = [[AVAudioPlayer alloc] initWithData:data error:&error];
    _audioPlayer.delegate = self;
    _audioPlayer.numberOfLoops = 0;
    _audioPlayer.volume = 10.0f;
    [_audioPlayer prepareToPlay];
    
    if (error) NSLog(@"Error: %@", [error localizedDescription]);
    else {
        [_audioPlayer play];
    }
}

-(void)playWithURL:(NSURL *)url {
    if (!_audioRecorder.recording) {
        NSError *error;
        
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];
        _audioPlayer.delegate = self;
        
        if (error) NSLog(@"Error: %@", [error localizedDescription]);
        else [_audioPlayer play];
    }
}

-(void)stop {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (_audioRecorder.isRecording) {
            [_audioRecorder stop];
        } else if (_audioPlayer.playing) {
            [_audioPlayer stop];
        }
    });
}

-(void)playerProgress:(BlockPlayingProgress)progress withDoneBlock:(BlockPlayingDone)done {
    playingProgerss = progress;
    playingDone = done;
}

-(void)playingProgress:(NSTimer*)timer {
    if(_audioPlayer.isPlaying) {
        float total= _audioPlayer.duration;
        float f = _audioPlayer.currentTime / total;
        //NSLog(@"%@",[NSString stringWithFormat:@"%f", f]);
        playingProgerss(f,_audioPlayer.currentTime);
    }
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    playingDone(YES);
    NSLog(@"Playing done");
}

-(void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error {
    NSLog(@"Decode Error occurred");
}

-(void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    recordingBlock(YES);
    NSLog(@"Playing done");
}

-(void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error {
    NSLog(@"Encode Error occurred");
}

-(NSURL *)recorderUrl {
    return [self getFilePathM4A];
}

@end
