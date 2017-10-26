//
//  RecorderManager.h
//  RecordingDemo
//
//  Created by xkun on 2017/8/30.
//  Copyright © 2017年 xukun. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RecorderManager : NSObject

+ (instancetype)shareInstance;

/**
 开始录音
 */
- (void)startRecording;

/**
 结束录音
 */
- (void)stopRecording;


/**
 暂停录音
 */
- (void)pause;

/**
 播放录音
 */
- (void)play;

/**
 压缩录音文件大小
 */
- (void)compression;


/**
 转换格式
 */
- (BOOL)transformFormatWithData:(NSData *)data;

/**
 上传
 */
- (void)upload;

//@property (nonatomic,copy)void (^recordingEnding)(void);
//@property (nonatomic,copy)void (^playingEnding)(void);


@end
