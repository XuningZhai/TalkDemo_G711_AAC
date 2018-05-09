//
//  AudioQueuePlay.h
//  GCDAsyncSocketDemo
//
//  Created by XuningZhai on 2018/4/25.
//  Copyright © 2018年 aipu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface AQPlayer : NSObject

- (instancetype)initWithSampleRate:(int)sample_rate;
- (void)playWithData:(NSData *)data;

@end
