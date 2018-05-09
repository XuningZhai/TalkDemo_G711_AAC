//
//  DecoderG711.m
//  GCDAsyncSocketDemo
//
//  Created by XuningZhai on 2018/5/8.
//  Copyright © 2018年 aipu. All rights reserved.
//

#import "DecoderG711.h"

#define SIGN_BIT (0x80)
#define QUANT_MASK (0xf)
#define NSEGS (8)
#define SEG_SHIFT (4)
#define SEG_MASK (0x70)
#define BIAS (0x84)

@interface DecoderG711()

@end

@implementation DecoderG711

int g711_decode(void *pout_buf, int *pout_len, const void *pin_buf, const int in_len , int type)
{
    int16_t *dst = (int16_t *) pout_buf;
    uint8_t *src = (uint8_t *) pin_buf;
    uint32_t i = 0;
    int Ret = 0;
    if ((NULL == pout_buf) || \
        (NULL == pout_len) || \
        (NULL == pin_buf) || \
        (0 == in_len)) {
        return -1;
    }
    if (*pout_len < 2 * in_len) {
        return -2;
    }
    if (TP_ALAW == type) {
        for (i = 0; i < in_len; i++) {
            *(dst++) = (int16_t)alaw2linear(*(src++));
        }
    }
    else {
        for (i = 0; i < in_len; i++) {
            *(dst++) = (int16_t)ulaw2linear(*(src++));
        }
    }
    *pout_len = 2 * in_len;
    Ret = 2 * in_len;
    return Ret;
}

int alaw2linear(unsigned char a_val)
{
    int t;
    int seg;
    a_val ^= 0x55;
    t = (a_val & QUANT_MASK) << 4;
    seg = ((unsigned)a_val & SEG_MASK) >> SEG_SHIFT;
    switch (seg) {
        case 0:
            t += 8;
            break;
        case 1:
            t += 0x108;
            break;
        default:
            t += 0x108;
            t <<= seg - 1;
    }
    return ((a_val & SIGN_BIT) ? t : -t);
}

int ulaw2linear(unsigned char u_val)
{
    int t;
    u_val = ~u_val;
    t = ((u_val & QUANT_MASK) << 3) + BIAS;
    t <<= ((unsigned)u_val & SEG_MASK) >> SEG_SHIFT;
    return ((u_val & SIGN_BIT) ? (BIAS - t) : (t - BIAS));
}

@end
