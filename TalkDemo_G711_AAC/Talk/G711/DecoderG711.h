//
//  DecoderG711.h
//  GCDAsyncSocketDemo
//
//  Created by XuningZhai on 2018/5/8.
//  Copyright © 2018年 aipu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DecoderG711 : NSObject

enum _e_g711_tp
{
    TP_ALAW,
    TP_ULAW
};

int g711_decode(void *pout_buf, int *pout_len, const void *pin_buf, const int in_len , int type);

@end
