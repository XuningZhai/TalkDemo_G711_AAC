//
//  TalkManager.m
//  GCDAsyncSocketDemo
//
//  Created by XuningZhai on 2018/4/16.
//  Copyright © 2018年 aipu. All rights reserved.
//

#import "TalkManager.h"
#import "GCDAsyncSocket.h"
#import "AQPlayer.h"
#import "CaptureAAC.h"
#import "EncoderAAC.h"
#import "DecoderAAC.h"
#import "CaptureG711.h"
#import "EncoderG711.h"
#import "DecoderG711.h"

#define SAMPLE_RATE 16000
#define BIT_RATE SAMPLE_RATE*16
#define FILENAME @"12345.pcm"

@interface TalkManager ()<GCDAsyncSocketDelegate,CaptureAACDelegate,AACSendDelegate,CaptureG711Delegate>
@property (nonatomic,retain) GCDAsyncSocket *socket;
@property (nonatomic, strong) CaptureAAC *captureSession;
@property (nonatomic, strong) EncoderAAC *aac;
@property (nonatomic, strong) DecoderAAC *aacDecoder;
@property (nonatomic, strong) AQPlayer *aqplayer;
@property (nonatomic, strong) CaptureG711 *g711capture;
@property (nonatomic ,strong) EncoderG711 *g711;
@end

@implementation TalkManager

+ (instancetype)manager {
    return [[[self class] alloc] init];
}

- (void)initAACEncoder {
    _captureSession = [[CaptureAAC alloc] initCaptureWithSessionPreset:CaptureSessionPreset640x480];
    _captureSession.delegate = self;
    _aac = [[EncoderAAC alloc] init];
    _aac.delegate = self;
}

- (void)startTalk {
    if (_type==AAC) {
        [self initAACEncoder];
        _aacDecoder = [[DecoderAAC alloc] init];
        [_aacDecoder initAACDecoderWithSampleRate:SAMPLE_RATE channel:2 bit:BIT_RATE];
        _aqplayer = [[AQPlayer alloc] initWithSampleRate:SAMPLE_RATE*2];
    }
    else {
        [self startCaptureG711];
        _g711 = [[EncoderG711 alloc] init];
        _aqplayer = [[AQPlayer alloc] initWithSampleRate:SAMPLE_RATE/2];
    }
    [self connectServer:self.ip port:self.port];
}

- (void)stopTalk {
    if (_type==AAC) {
        [_captureSession stop];
        [_aacDecoder releaseAACDecoder];
        _aacDecoder = nil;
    }
    else {
        [_g711capture stopRecord];
        _g711capture = nil;
        _g711 = nil;
    }
    [self doTeardown:self.url];
    self.socket = nil;
    _aqplayer = nil;
}

- (int)connectServer:(NSString *)hostIP port:(int)hostPort {
    if (_socket == nil) {
        _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        NSError *err = nil;
        int t = [_socket connectToHost:hostIP onPort:hostPort error:&err];
        if (!t) {
            return 0;
        }else{
            return 1;
        }
    }else {
        [_socket readDataWithTimeout:-1 tag:0];
        return 1;
    }
}

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    BOOL state = [self.socket isConnected];
    if (state) {
        [self sendCmd];
    }else{
        NSLog(@"socket 没有连接");
    }
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    BOOL state = [_socket isConnected];
    NSLog(@"连接断开,state %d",state);
    self.socket = nil;
}

- (void)sendCmd
{
    [self doSetup:self.url];
}

- (void)doSetup:(NSString *)url {
    NSMutableString *dataString = [NSMutableString string];
    [dataString appendString:[NSString stringWithFormat:@"SETUP %@ RTSP/1.0\r\n", url]];
    [dataString appendString:@"Content-Length: 0\r\n"];
    [dataString appendFormat:@"CSeq: 0\r\n"];
    [dataString appendString:@"Transport: RTP/AVP/DHTP;unicast\r\n"];
    [dataString appendString:@"\r\n"];
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:data withTimeout:-1 tag:0];
    [self.socket readDataWithTimeout:-1 tag:0];
}

- (void)doPlay:(NSString *)url {
    NSMutableString *dataString = [NSMutableString string];
    [dataString appendString:[NSString stringWithFormat:@"PLAY %@ RTSP/1.0\r\n", url]];
    [dataString appendString:@"Content-Length: 0\r\n"];
    [dataString appendFormat:@"CSeq: 1\r\n"];
    [dataString appendString:@"\r\n"];
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:data withTimeout:-1 tag:1];
    [self.socket readDataWithTimeout:-1 tag:1];
}

- (void)doTeardown:(NSString *)url {
    NSMutableString *dataString = [NSMutableString string];
    [dataString appendString:[NSString stringWithFormat:@"TEARDOWN %@ RTSP/1.0\r\n", url]];
    [dataString appendString:@"Content-Length: 0\r\n"];
    [dataString appendString:@"CSeq: 2\r\n"];
    [dataString appendString:@"\r\n"];
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    [self.socket writeData:data withTimeout:-1 tag:2];
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *dataString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    switch (tag) {
        case 0:
            [self doPlay:self.url];
            break;
        case 1:
            if (_type==AAC) {
                [self startCaptureAAC];
            }
            break;
        case 200:
            if (!dataString) {
                if (_type==AAC) {
                    [self getPayloadAAC:data];
                }
                else {
                    [self getPayloadG711:data];
                }
            }
            break;
        default:
            break;
    }
    [sock readDataWithTimeout:-1 tag:200];
}



#pragma mark - AAC
- (void)getPayloadAAC:(NSData *)data {
    NSMutableData *payload = [NSMutableData dataWithData:data];
    if (data.length>40) {
        [payload replaceBytesInRange:NSMakeRange(0, 40) withBytes:NULL length:0];//4+12+24
        [self decoderAAC:payload];
    }
}

- (void)decoderAAC:(NSMutableData *)data {
    [_aacDecoder AACDecoderWithMediaData:data sampleRate:SAMPLE_RATE completion:^(uint8_t *out_buffer, size_t out_buffer_size) {
        NSData *pcm = [NSData dataWithBytes:out_buffer length:out_buffer_size];
        [self->_aqplayer playWithData:pcm];
    }];
}

- (void)startCaptureAAC {
    [_captureSession start];
}

- (void)audioWithSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    [_aac encodeSmapleBuffer:sampleBuffer];
}

- (void)sendData:(NSMutableData *)data {
    [self.socket writeData:data withTimeout:-1 tag:100];
}



#pragma mark - G711
- (void)startCaptureG711 {
    _g711capture = [[CaptureG711 alloc] init];
    _g711capture.delegate = self;
    [_g711capture startRecord];
}

- (void)returnDataG711:(NSMutableData *)data {
    NSData *g711 = [self encodeG711:(NSData *)data];
    NSData *rtpG711 = [self addHeader:g711];
    [self.socket writeData:rtpG711 withTimeout:-1 tag:100];
}

- (NSData *)encodeG711:(NSData *)data {
    NSUInteger datalength = [data length];
    Byte *byteData = (Byte *)[data bytes];
    short *pPcm = (short *)byteData;
    free(byteData);
    int outlen = 0;
    int len =(int)datalength/2;
    Byte *G711Buff = (Byte *)malloc(len);
    memset(G711Buff,0,len);
    int i;
    for (i=0; i<len; i++) {
        if (_type==G711A) {
            G711Buff[i] = [_g711 linear2alaw:pPcm[i]];
        }
        else if (_type==G711U) {
            G711Buff[i] = [_g711 linear2ulaw:pPcm[i]];
        }
    }
    outlen = i;
    Byte *sendbuff = (Byte *)G711Buff;
    NSData *sendData = [[NSData alloc] initWithBytes:sendbuff length:len];
    free(G711Buff);
    return sendData;
}

- (NSMutableData *)addHeader:(NSData *)data {
    char *privateHeader = newPrivateG711((int)data.length,_type);
    NSData *privateHeaderData = [NSData dataWithBytes:privateHeader length:24];
    free(privateHeader);
    privateHeader = NULL;
    NSMutableData *pFullData = [NSMutableData dataWithData:privateHeaderData];
    [pFullData appendData:data];
    char *rtpHeader = newRTPForG711();
    NSData *rtpHeaderData = [NSData dataWithBytes:rtpHeader length:12];
    free(rtpHeader);
    rtpHeader = NULL;
    NSMutableData *fullData1 = [NSMutableData dataWithData:rtpHeaderData];
    [fullData1 appendData:pFullData];
    char *rtspFrameHeader = newRTSPInterleavedFrameG711((int)fullData1.length);
    NSData *rtspFrameHeaderData = [NSData dataWithBytes:rtspFrameHeader length:4];
    free(rtspFrameHeader);
    rtspFrameHeader = NULL;
    NSMutableData *fullData2 = [NSMutableData dataWithData:rtspFrameHeaderData];
    [fullData2 appendData:fullData1];
    fullData1 = nil;
    pFullData = nil;
    return fullData2;
}

char *newPrivateG711 (int packetLength,int type) {
    int adtsLen = 24;
    char *packet = malloc(sizeof(char)*adtsLen);
    packet[2] = 0x01;
    packet[3] = 0xEA;
    if (type==G711U) {
        packet[8] = 0x16;//u-law
    }
    else {
        packet[8] = 0x0e;//a-law
    }
    packet[9] = 0x01;
    packet[10] = 0x02;//8k
    packet[11] = 0x10;
    NSString *lengthStr = [NSString stringWithFormat:@"%d",packetLength];
    long long lengthL = [lengthStr longLongValue];
    NSString *length16 = [NSString stringWithFormat:@"%08llx",lengthL];
    NSRange r1 = {2,2};
    NSRange r2 = {4,2};
    NSString *s16_1 = [length16 substringToIndex:2];
    NSString *s16_2 = [length16 substringWithRange:r1];
    NSString *s16_3 = [length16 substringWithRange:r2];
    NSString *s16_4 = [length16 substringFromIndex:6];
    unsigned long res1 = strtoul([s16_1 UTF8String],0,16);
    unsigned long res2 = strtoul([s16_2 UTF8String],0,16);
    unsigned long res3 = strtoul([s16_3 UTF8String],0,16);
    unsigned long res4 = strtoul([s16_4 UTF8String],0,16);
    packet[20] = res4;
    packet[21] = res3;
    packet[22] = res2;
    packet[23] = res1;
    return packet;
}

char *newRTPForG711() {
    int rtpLen = 12;
    char *packet = malloc(sizeof(char)*rtpLen);
    packet[0] = 0x80;//V_P_X_CC
    packet[1] = 0x88;//M_PT
    packet[2] = 0x00;
    packet[3] = 0xDA;
    packet[4] = 0x00;
    packet[5] = 0x01;
    packet[6] = 0x98;
    packet[7] = 0xC0;
    return packet;
}

char *newRTSPInterleavedFrameG711(int packetLength) {
    int rtpLen = 4;
    char *packet = malloc(sizeof(char)*rtpLen);
    packet[0] = 0x24;
    packet[1] = 0x00;
    NSString *str = [NSString stringWithFormat:@"%d",packetLength];
    long long l = [str longLongValue];
    NSString *s16 = [NSString stringWithFormat:@"%04llx",l];
    NSString *s16_1 = [s16 substringToIndex:2];
    NSString *s16_2 = [s16 substringFromIndex:2];
    unsigned long res1 = strtoul([s16_1 UTF8String],0,16);
    unsigned long res2 = strtoul([s16_2 UTF8String],0,16);
    packet[2] = res1;
    packet[3] = res2;
    return packet;
}

- (void)getPayloadG711:(NSData *)data {
    NSMutableData *payload = [NSMutableData dataWithData:data];
    if (data.length>40) {
        [payload replaceBytesInRange:NSMakeRange(0, 40) withBytes:NULL length:0];//4+12+24
        [self decoderG711:payload];
    }
}

- (void)decoderG711:(NSData *)data {
    NSUInteger datalength = [data length];
    Byte *byteData = (Byte *)[data bytes];
    int inlen = (int)datalength;
    short *g711Buf = (short *)byteData;
    int outlen = inlen * 2;
    Byte *pcmBuf = (Byte *)malloc(outlen);
    g711_decode(pcmBuf, &outlen, g711Buf, inlen, TP_ALAW);
    NSData *pcm = [[NSData alloc] initWithBytes:pcmBuf length:outlen];
    free(pcmBuf);
    [_aqplayer playWithData:pcm];
}



@end
