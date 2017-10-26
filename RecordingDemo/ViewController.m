//
//  ViewController.m
//  RecordingDemo
//
//  Created by xkun on 2017/8/16.
//  Copyright © 2017年 xukun. All rights reserved.
//

#import "ViewController.h"
#import "HNAlert.h"
#import "lame.h"
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()<AVAudioRecorderDelegate,AVAudioPlayerDelegate>
{
    NSInteger _kCountTime;
}

@property (weak, nonatomic) IBOutlet UILabel *display;
@property (weak, nonatomic) IBOutlet UIButton *begin;
@property (weak, nonatomic) IBOutlet UIButton *end;
@property (weak, nonatomic) IBOutlet UIButton *play;

/**
 录音对象
 */
@property (nonatomic,strong) AVAudioRecorder    *recordeManager;

/**
 播放对象
 */
@property (nonatomic,strong) AVAudioPlayer      *playerManager;

/**
 文件路径
 */
@property (nonatomic,strong) NSString           *filePath;

/**
 计时器
 */
@property (nonatomic,strong) NSTimer            *recordTimer;

@property (nonatomic,strong) NSMutableDictionary *settings;
@end

//static NSInteger kCountTime = 60;

@implementation ViewController



/**
 声音质量:
 声卡对声音的处理质量可以用三个基本参数来衡量，即采样频率、采样位数和声道数。
 
 采样频率:
 是指单位时间内的采样次数。采样频率越大，采样点之间的间隔就越小，数字化后得到的声音就越逼真，但相应的数据量就越大。声卡一般提供11.025kHz、22.05kHz和44.1kHz等不同的采样频率。
 
 采样位数：
 是记录每次采样值数值大小的位数。采样位数通常有8bits或16bits两种，采样位数越大，所能记录声音的变化度就越细腻，相应的数据量就越大。
 
 声道数:
 是指处理的声音是单声道还是立体声。单声道在声音处理过程中只有单数据流，而立体声则需要左、右声道的两个数据流。显然，立体声的效果要好，但相应的数据量要比单声道的数据量加倍。
 
 数据量（字节/秒）= (采样频率（Hz）× 采样位数（bit） × 声道数)/ 8
 */



/**
 //音频会话 AVAudioSession:
 AVAudioSessionCategoryPlayAndRecord :录制和播放
 AVAudioSessionCategoryAmbient       :用于非以语音为主的应用,随着静音键和屏幕关闭而静音.
 AVAudioSessionCategorySoloAmbient   :类似AVAudioSessionCategoryAmbient不同之处在于它会中止其它应用播放声音。
 AVAudioSessionCategoryPlayback      :用于以语音为主的应用,不会随着静音键和屏幕关闭而静音.可在后台播放声音
 AVAudioSessionCategoryRecord        :用于需要录音的应用,除了来电铃声,闹钟或日历提醒之外的其它系统声音都不会被播放,只提供单纯录音功能.
*/

- (NSString *)getDateTime{
    NSDate *date = [NSDate date];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    [formatter setDateFormat:@"YYYYMMddhhmmss"];
    NSString *dateTime = [formatter stringFromDate:date];
    return dateTime;
}


- (NSString *)getfilePathWithType:(NSString *)type{
    // 获取沙盒存放地址
    NSString *document = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    if (type.length == 0) {
        return document;
    } else {
        NSString *filePath = [document stringByAppendingString:[NSString stringWithFormat:@"/record%@.%@",[self getDateTime],type]];
        return filePath;
    }
}

- (NSMutableDictionary *)settings{
    if (!_settings) {
        // 录音设置
        _settings = [[NSMutableDictionary alloc] init];
        
        // 录音采样率 8000是一般电话的采样率 () 8000/44100/96000
        [_settings setObject:[NSNumber numberWithFloat:44100] forKey:AVSampleRateKey];
        // 设置录音格式 LinearPCM这是一个未压缩的音频格式
        [_settings setObject:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
        // 设置通道（单声道）
        [_settings setObject:@(1) forKey:AVNumberOfChannelsKey];
        // 采样点位数 分为8，16，24，32
        [_settings setObject:@(16) forKey:AVLinearPCMBitDepthKey];
        //录音质量
        [_settings setObject:[NSNumber numberWithInt:AVAudioQualityHigh] forKey:AVEncoderAudioQualityKey];
    }
    return _settings;
}

- (AVAudioRecorder *)recordeManager{
    if (!_recordeManager) {
        _recordeManager = [[AVAudioRecorder alloc] initWithURL:[NSURL URLWithString:self.filePath] settings:self.settings error:nil];
        _recordeManager.delegate = self;
        [_recordeManager setMeteringEnabled:YES];
    }
    return _recordeManager;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 获取沙盒地址
   
    self.filePath = [self getfilePathWithType:@"wav"];

    // 初始化录音对象

    
    //开启接近监视(靠近耳朵的时候听筒播放,离开的时候扬声器播放)
    [[UIDevice currentDevice] setProximityMonitoringEnabled:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playPositionStateChange:)name:UIDeviceProximityStateDidChangeNotification object:nil];

  
}

- (void)playPositionStateChange:(NSNotification *)notif {
    if ([[UIDevice currentDevice] proximityState] == YES) {
        //靠近耳朵
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    } else {
        //离开耳朵
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
}

- (AVAudioPlayer *)playerManager {
    if (_playerManager == nil) {
        NSURL *URL= [NSURL URLWithString:self.filePath];
        _playerManager = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:nil];
        [_playerManager setDelegate:self];
    }
    return _playerManager;
}

- (NSTimer *)recordTimer {
    if (_recordTimer == nil) {
        _recordTimer = [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timeLoop) userInfo:nil repeats:YES];
    }
    return _recordTimer;
}

- (void)timeLoop{
    

    if (self.recordeManager.isRecording) {
        _kCountTime ++;
        
        NSFileManager *manager = [NSFileManager defaultManager];
        if ([manager fileExistsAtPath:self.filePath]){
            double size = [[manager attributesOfItemAtPath:self.filePath error:nil] fileSize];
            NSString *value = [self transformedValue:size];
            
            self.display.text = [NSString stringWithFormat:@"录制中...(%@)(%@)",value,[self getMMSSFromSS:_kCountTime]];
        }
        // 循环获取录音时声音的分贝
        [self.recordeManager updateMeters];
        CGFloat peak = [self.recordeManager peakPowerForChannel:0];
        NSLog(@"%f",peak);
    }
    
}

// 开始录音
- (IBAction)recording:(UIButton *)sender {
    NSLog(@"开始录音");
    
    NSString *path = [self getfilePathWithType:nil];
    NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil];
    NSLog(@"%@",files);

    [self record];

}

- (void)record{
    
    self.play.enabled = NO;
    self.end.enabled = YES;
    [self.display setHidden:NO];
    if (!self.recordeManager.isRecording) {
        //录音开始前需要设置category,不然录制失败，暂停之后恢复录音，不需要重新设置category，不然恢复之后的录音没效果
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:nil];
    }
    [self.recordeManager record];
    _recordTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                                  selector:@selector(timeLoop) userInfo:nil repeats:YES];
}

// 暂停录音
- (IBAction)pause:(UIButton *)sender {
    NSLog(@"暂停录音");
    self.display.text = @"暂停录音";
    [self.recordeManager pause];
    self.play.enabled = YES;
}

// 结束录音
- (IBAction)stop:(UIButton *)sender {
    NSLog(@"结束录音");
    self.display.text = @"结束录音";
    if (self.recordeManager.isRecording) {
        _kCountTime = 0;
        [self.recordeManager stop];
        [self.recordTimer invalidate];
        self.recordTimer = nil;
        self.play.enabled = YES;
        self.end.enabled = NO;
    }
}

// 播放录音
- (IBAction)play:(UIButton *)sender {
    NSLog(@"播放录音");
    
    [self.display setHidden:NO];
    
    // 读取沙盒音频文件
    if (self.filePath.length != 0) {
        NSData *data = [NSData dataWithContentsOfFile:self.filePath];
        // 输出文件大小
        NSString *size = [self transformedValue:data.length];
        NSLog(@"读取前大小 %@",size);
        
        self.display.text = [NSString stringWithFormat:@"播放中（%@）",size];
    }
    
    if (![self.playerManager isPlaying]) {
        // 这里每次播放也需要重新设置category 不然播放不了。
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
        [self.playerManager play];
        
        
        AVURLAsset* audioAsset =[AVURLAsset URLAssetWithURL:[NSURL URLWithString:self.filePath] options:nil];
        CMTime audioDuration = audioAsset.duration;
        
        float audioDurationSeconds = CMTimeGetSeconds(audioDuration);
        NSLog(@"audioDurationSeconds %f",audioDurationSeconds);
    }
}

// 上传录音
- (IBAction)upload:(UIButton *)sender {
    NSLog(@"上传录音");
    NSString *path = [self getfilePathWithType:nil];
    NSString *wavPath = [self getfilePathWithType:@"wav"];
    NSString *mp3Path = [self getfilePathWithType:@"mp3"];
    NSArray *files = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:path error:nil];
    NSLog(@"删除之前 %lu",(unsigned long)files.count);
    // 读取沙盒音频文件
    if (self.filePath.length != 0) {
        NSData *data = [NSData dataWithContentsOfFile:self.filePath];
        // 输出文件大小
        NSLog(@"读取前大小 %@",[self transformedValue:data.length]);

        if ([self convertFromWavToMp3WithData:data]) {
            self.filePath = mp3Path;
            [[NSFileManager defaultManager] removeItemAtPath:wavPath error:nil];
        }
    }
}

- (BOOL)convertFromWavToMp3WithData:(NSData *)data
{
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


//录音结束代理
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    [recorder stop];
}

// 播放录音结束
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [player stop];
    self.display.text = @"播放结束";
    self.end.enabled = YES;
    self.play.enabled = YES;
}

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

-(NSString *)getMMSSFromSS:(NSInteger)totalTime{
    
    NSInteger seconds = totalTime;
    
    //format of minute
    NSString *str_minute = [NSString stringWithFormat:@"%.2ld",seconds/60];
    //format of second
    NSString *str_second = [NSString stringWithFormat:@"%.2ld",seconds%60];
    //format of time
    NSString *format_time = [NSString stringWithFormat:@"%@:%@",str_minute,str_second];
    
    NSLog(@"format_time : %@",format_time);
    return format_time;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
