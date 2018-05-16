//
//  AudioQueuePlay.m
//  GCDAsyncSocketDemo
//
//  Created by XuningZhai on 2018/4/25.
//  Copyright © 2018年 aipu. All rights reserved.
//

#import "AQPlayer.h"

#define MIN_SIZE_PER_FRAME 2000
#define QUEUE_BUFFER_SIZE 3

@interface AQPlayer() {
    AudioQueueRef audioQueue;
    AudioStreamBasicDescription _audioDescription;
    AudioQueueBufferRef audioQueueBuffers[QUEUE_BUFFER_SIZE];
    BOOL audioQueueBufferUsed[QUEUE_BUFFER_SIZE];
    NSLock *sysnLock;
    NSMutableData *tempData;
    OSStatus osState;
    NSMutableString *str;
}

@end

@implementation AQPlayer

- (instancetype)initWithSampleRate:(int)sample_rate {
    self = [super init];
    if (self) {
        str = [NSMutableString string];
        sysnLock = [[NSLock alloc] init];
        //设置参数
        if (_audioDescription.mSampleRate <= 0) {
            _audioDescription.mSampleRate = sample_rate;
            _audioDescription.mFormatID = kAudioFormatLinearPCM;
            _audioDescription.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
            _audioDescription.mChannelsPerFrame = 1;
            _audioDescription.mFramesPerPacket = 1;
            _audioDescription.mBitsPerChannel = 16;
            _audioDescription.mBytesPerFrame = (_audioDescription.mBitsPerChannel/8)*_audioDescription.mChannelsPerFrame;
            _audioDescription.mBytesPerPacket = _audioDescription.mBytesPerFrame*_audioDescription.mFramesPerPacket;
        }
        //创建队列
        AudioQueueNewOutput(&_audioDescription, AudioPlayerAQInputCallback, (__bridge void * _Nullable)(self), nil, 0, 0, &audioQueue);
        AudioQueueSetParameter(audioQueue, kAudioQueueParam_Volume, 1.0);
        //创建buffer
        for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
            audioQueueBufferUsed[i] = false;
            osState = AudioQueueAllocateBuffer(audioQueue, MIN_SIZE_PER_FRAME, &audioQueueBuffers[i]);
        }
        //开始队列
        osState = AudioQueueStart(audioQueue, NULL);
        if (osState != noErr) {
            NSLog(@"AudioQueueStart Error");
        }
    }
    return self;
}

- (void)resetPlay {
    if (audioQueue != nil) {
        AudioQueueReset(audioQueue);
    }
}

- (void)playWithData:(NSData *)data {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self->sysnLock lock];
        self->tempData = [NSMutableData new];
        [self->tempData appendData:data];
        NSUInteger len = self->tempData.length;
        Byte *bytes = (Byte *)malloc(len);
        [self->tempData getBytes:bytes length:len];
        int i = 0;
        //判断buffer是否被使用
        while (true) {
            usleep(1000);//防止cpu过高
            if (!self->audioQueueBufferUsed[i]) {
                self->audioQueueBufferUsed[i] = true;
                break;
            }else {
                i++;
                if (i >= QUEUE_BUFFER_SIZE) {
                    i = 0;
                }
            }
        }
        if (self->str.length < 3) {
            [self->str appendString:[NSString stringWithFormat:@"%d",i]];
        }
        else if (self->str.length == 3) {
            [self->str deleteCharactersInRange:NSMakeRange(0, 1)];
            [self->str appendString:[NSString stringWithFormat:@"%d",i]];
        }
        if ([self->str isEqualToString:@"000"]) {
            //reset
            [self resetPlay];
        }
        //向buffer填充数据
        self->audioQueueBuffers[i]->mAudioDataByteSize = (unsigned int)len;
        memcpy(self->audioQueueBuffers[i]->mAudioData, bytes, len);
        free(bytes);
        //将buffer插入队列
        AudioQueueEnqueueBuffer(self->audioQueue, self->audioQueueBuffers[i], 0, NULL);
        [self->sysnLock unlock];
    });
}

//回调
static void AudioPlayerAQInputCallback(void* inUserData,AudioQueueRef audioQueueRef, AudioQueueBufferRef audioQueueBufferRef) {
    AQPlayer *player = (__bridge AQPlayer*)inUserData;
    [player resetBufferState:audioQueueRef and:audioQueueBufferRef];
}

- (void)resetBufferState:(AudioQueueRef)audioQueueRef and:(AudioQueueBufferRef)audioQueueBufferRef {
    for (int i = 0; i < QUEUE_BUFFER_SIZE; i++) {
        // 将这个buffer设为未使用
        if (audioQueueBufferRef == audioQueueBuffers[i]) {
            audioQueueBufferUsed[i] = false;
        }
    }
}

- (void)dealloc {
    if (audioQueue != nil) {
        AudioQueueStop(audioQueue,true);
    }
    audioQueue = nil;
    sysnLock = nil;
}

@end
