//
//  DecoderG711.h
//  FocusVision
//
//  Created by XuningZhai on 2018/5/2.
//  Copyright © 2018年 aipu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EncoderG711 : NSObject

- (unsigned char)linear2alaw:(int)pcm_val;
- (unsigned char)linear2ulaw:(int)pcm_val;

@end
