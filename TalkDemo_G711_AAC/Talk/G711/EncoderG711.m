//
//  DecoderG711.m
//  FocusVision
//
//  Created by XuningZhai on 2018/5/2.
//  Copyright © 2018年 aipu. All rights reserved.
//

#import "EncoderG711.h"

#define QUANT_MASK (0xf)
#define SEG_SHIFT (4)
#define BIAS (0x84)

@implementation EncoderG711

static short seg_end[8] = {0xFF,0x1FF,0x3FF,0x7FF,0xFFF,0x1FFF,0x3FFF,0x7FFF};

static int search(int val,short *table,int size)
{
    int i;
    for (i = 0; i < size; i++) {
        if (val <= *table++)
            return (i);
    }
    return (size);
}

- (unsigned char)linear2alaw:(int)pcm_val
{
    int mask;
    int seg;
    unsigned char aval;
    if (pcm_val >= 0) {
        mask = 0xD5;
    } else {
        mask = 0x55;
        pcm_val = -pcm_val - 8;
    }
    seg = search(pcm_val, seg_end, 8);
    if (seg >= 8)
        return (0x7F ^ mask);
    else {
        aval = seg << SEG_SHIFT;
        if (seg < 2)
            aval |= (pcm_val >> 4) & QUANT_MASK;
        else
            aval |= (pcm_val >> (seg + 3)) & QUANT_MASK;
        return (aval ^ mask);
    }
}

- (unsigned char)linear2ulaw:(int)pcm_val
{
    int mask;
    int seg;
    unsigned char uval;
    if (pcm_val < 0) {
        pcm_val = BIAS - pcm_val;
        mask = 0x7F;
    } else {
        pcm_val += BIAS;
        mask = 0xFF;
    }
    seg = search(pcm_val, seg_end, 8);
    if (seg >= 8)
        return (0x7F ^ mask);
    else {
        uval = (seg << 4) | ((pcm_val >> (seg + 3)) & 0xF);
        return (uval ^ mask);
    }
}

- (void)dealloc {
}

@end
