//
//  EYRecord.h
//  GCDAsyncSocketDemo
//
//  Created by XuningZhai on 2018/5/7.
//  Copyright © 2018年 aipu. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CaptureG711Delegate <NSObject>
- (void)returnDataG711:(NSMutableData *)data;
@end

@interface CaptureG711 : NSObject
@property (nonatomic,strong) id<CaptureG711Delegate>delegate;
- (void)startRecord;
- (void)stopRecord;
@end
