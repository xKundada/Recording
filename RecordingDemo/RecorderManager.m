//
//  RecorderManager.m
//  RecordingDemo
//
//  Created by xkun on 2017/8/30.
//  Copyright © 2017年 xukun. All rights reserved.
//

#import "RecorderManager.h"
#import "lame.h"
#import "HNAlert.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface RecorderManager ()<AVAudioRecorderDelegate,AVAudioPlayerDelegate>
/**
 录音对象
 */
@property (nonatomic,strong) AVAudioRecorder    *recorder;

/**
 播放对象
 */
@property (nonatomic,strong) AVAudioPlayer      *player;

/**
 文件路径
 */
@property (nonatomic,strong) NSString           *filePath;

@end

@implementation RecorderManager

+ (instancetype)shareInstance{
    static RecorderManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[RecorderManager alloc] init];
    });
    return manager;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        
//        // 录音设置集合
//        NSMutableDictionary *sets = [[NSMutableDictionary alloc] init];
//        
//        // 录音采样率 8000是一般电话的采样率 ()
//        [sets setObject:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
//        // 设置录音格式 LinearPCM这是一个未压缩的音频格式
//        [sets setObject:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
//        // 设置通道（单声道）
//        [sets setObject:@(1) forKey:AVNumberOfChannelsKey];
//        // 采样点位数 分为8，16，24，32
//        [sets setObject:@(16) forKey:AVLinearPCMBitDepthKey];
//        //录音质量
//        [sets setObject:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
        
        
        // 初始化录音对象
        self.filePath = [self getfilePathWithType:@"wav"];
        
        
        // 初始化播放对象
      
        
        //开启接近监视(靠近耳朵的时候听筒播放,离开的时候扬声器播放)
        [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPositionStateChange)name:UIDeviceProximityStateDidChangeNotification object:nil];
        
        
    }
    return self;
}

-(AVAudioRecorder *)recorder{
    if (_recorder == nil) {
        
        // 录音设置集合
        NSMutableDictionary *sets = [[NSMutableDictionary alloc] init];
        
        // 录音采样率 8000是一般电话的采样率 ()
        [sets setObject:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
        // 设置录音格式 LinearPCM这是一个未压缩的音频格式
        [sets setObject:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
        // 设置通道（单声道）
        [sets setObject:@(1) forKey:AVNumberOfChannelsKey];
        // 采样点位数 分为8，16，24，32
        [sets setObject:@(16) forKey:AVLinearPCMBitDepthKey];
        //录音质量
        [sets setObject:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
        
//        _recorder = [[AVAudioRecorder alloc] init];
        NSError *error;
        _recorder = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:_filePath]
                                                    settings:sets error:&error];
        _recorder.delegate = self;
        [_recorder setMeteringEnabled:YES];
    }
    return _recorder;
}

- (AVAudioPlayer *)player{
    if (_player == nil) {
        NSURL *URL= [NSURL URLWithString:_filePath];
        _player = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:nil];
        [_player setDelegate:self];
    }
    return _player;
}

- (NSString *)getDateTime{
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYY-MM-dd hh:mm:ss"];
    NSString *dateTime = [formatter stringFromDate:date];
    return dateTime;
}


- (NSString *)getfilePathWithType:(NSString *)type{
    // 获取沙盒存放地址
    NSString *document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    if (type.length == 0) {
        return document;
    } else {
        NSString *filePath = [document stringByAppendingString:[NSString stringWithFormat:@"%@/record.%@",[self getDateTime],type]];
        return filePath;
    }
   
}


- (void)startRecording{
    
    if (!self.recorder.isRecording) {

        //录音开始前需要设置category,不然录制失败，暂停之后恢复录音，不需要重新设置category，不然恢复之后的录音没效果
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    }
    [self.recorder record];
}

- (void)stopRecording{

    if (self.recorder.isRecording) {
        [self.recorder stop];
    }
}

- (void)pause{
    if ([self.recorder isRecording]) {
        [self.recorder pause];
    }
}

- (void)play{

    if (![self.player isPlaying]) {
        // 这里每次播放也需要重新设置category 不然播放不了。
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [self.player play];
    }
}

- (void)upload{

}

- (void)compression{
    
    NSString *wavPath = [self getfilePathWithType:@"wav"];
    NSString *mp3Path = [self getfilePathWithType:@"mp3"];
    
    //NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil];

    if (wavPath.length > 0) {
        NSData *data = [NSData dataWithContentsOfFile:wavPath];
        
        if (data.length > 0) {
            NSLog(@"文件大小 %@",[self transformedValue:data.length]);
            BOOL success = [self transformFormatWithData:data];
            if (success) {
                self.filePath = mp3Path;
                [[NSFileManager defaultManager] removeItemAtPath:wavPath error:nil];
            }
        }
    }
}

#pragma mark - 代理
//录音结束代理
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    [recorder stop];
//    if (self.recordingEnding) {
//        self.recordingEnding();
//    }
}

// 播放录音结束
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [player stop];
//    if (self.playingEnding) {
//        self.playingEnding();
//    }
}

#pragma mark - 逻辑处理
// wav转MP3
- (BOOL)transformFormatWithData:(NSData *)data{

    NSString *wavPath = [self getfilePathWithType:@"wav"];
    NSString *mp3Path = [self getfilePathWithType:@"mp3"];
    
    if (![data writeToURL:[NSURL fileURLWithPath:wavPath] atomically:YES]) {
        return NO;
    }
    
    int read, write;
    
    FILE *pcm = fopen([wavPath cStringUsingEncoding:NSUTF8StringEncoding], "rb");  //source
    //skip file header
    FILE *mp3 = fopen([mp3Path cStringUsingEncoding:NSUTF8StringEncoding], "wb");  //output
    
    if (!pcm || !mp3)
    {
        fclose(mp3);
        fclose(pcm);
        return NO;
    }
    
    const int PCM_SIZE = 8192;
    const int MP3_SIZE = 8192;
    short int pcm_buffer[PCM_SIZE*2];
    unsigned char mp3_buffer[MP3_SIZE];
    
    lame_t lame = lame_init();
    lame_set_in_samplerate(lame, 22050);
    lame_set_VBR(lame, vbr_default);
    lame_init_params(lame);
    
    do {
        read = (int)fread(pcm_buffer, 2*sizeof(short int), PCM_SIZE, pcm);
        if (read == 0)
            write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
        else
            write = lame_encode_buffer_interleaved(lame, pcm_buffer, read, mp3_buffer, MP3_SIZE);
        
        fwrite(mp3_buffer, write, 1, mp3);
        
    } while (read != 0);
    
    lame_close(lame);
    fclose(mp3);
    fclose(pcm);
    return YES;
}

// 听筒，扬声器播放转换
- (void)playPositionStateChange{
    
    if ([[UIDevice currentDevice] proximityState] == YES) {
        //靠近耳朵
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    } else {
        //离开耳朵
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}

// KB MB GB转换
- (NSString *)transformedValue:(double)value
{
    
    double convertedValue = value;
    int multiplyFactor = 0;
    
    NSArray *tokens = [NSArray arrayWithObjects:@"bytes",@"KB",@"MB",@"GB",@"TB",nil];
    
    while (convertedValue > 1024) {
        convertedValue /= 1024;
        multiplyFactor++;
    }
    
    return [NSString stringWithFormat:@"%4.2f%@",convertedValue, [tokens objectAtIndex:multiplyFactor]];
}


// 格式化计时时间
-(NSString *)getMMSSFromSS:(NSInteger)totalTime{
    
    NSInteger seconds = totalTime;
    
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%.2ld",seconds/60];
    //format of second
    NSString *str_second = [NSString stringWithFormat:@"%.2ld",seconds%60];
    //format of time
    NSString *format_time = [NSString stringWithFormat:@"%@:%@",str_minute,str_second];
    return format_time;
    
}

@end
