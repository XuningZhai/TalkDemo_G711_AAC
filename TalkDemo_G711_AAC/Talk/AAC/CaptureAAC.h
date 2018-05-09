//
//  CaptureAAC.h
//  GCDAsyncSocketDemo
//
//  Created by XuningZhai on 2018/5/7.
//  Copyright © 2018年 aipu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef NS_ENUM(NSUInteger,CaptureSessionPreset) {
    CaptureSessionPreset640x480,
    CaptureSessionPresetiFrame960x540,
    CaptureSessionPreset1280x720,
};

@protocol CaptureAACDelegate <NSObject>
- (void)audioWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;
@end

@interface CaptureAAC : NSObject
@property(nonatomic,strong)id<CaptureAACDelegate>delegate;
@property(nonatomic,strong)AVCaptureSession *session;//管理对象

- (instancetype)initCaptureWithSessionPreset:(CaptureSessionPreset)preset;
- (void)start;
- (void)stop;

@end
