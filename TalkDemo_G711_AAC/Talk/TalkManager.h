//
//  TalkManager.h
//  GCDAsyncSocketDemo
//
//  Created by XuningZhai on 2018/4/16.
//  Copyright © 2018年 aipu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TalkManager : NSObject

typedef enum {
    G711A,
    AAC,
    G711U
}Type;

@property (nonatomic,copy)NSString *ip;
@property (nonatomic,assign)int port;
@property (nonatomic,copy)NSString *url;
@property (nonatomic,assign)Type type;

+ (instancetype)manager;
- (void)startTalk;
- (void)stopTalk;

@end
