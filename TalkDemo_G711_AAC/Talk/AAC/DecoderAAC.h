//
//  DecoderAAC.h
//  GCDAsyncSocketDemo
//
//  Created by XuningZhai on 2018/4/17.
//  Copyright © 2018年 aipu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DecoderAAC : NSObject

- (BOOL)initAACDecoderWithSampleRate:(int)sampleRate channel:(int)channel bit:(int)bit ;
- (void)AACDecoderWithMediaData:(NSData *)mediaData sampleRate:(int)sampleRate completion:(void(^)(uint8_t *out_buffer, size_t out_buffer_size))completion;
- (void)releaseAACDecoder;

@end
