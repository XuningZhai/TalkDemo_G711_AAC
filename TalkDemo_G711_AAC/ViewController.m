//
//  ViewController.m
//  TalkDemo_G711_AAC
//
//  Created by XuningZhai on 2018/5/9.
//  Copyright © 2018年 aipu. All rights reserved.
//

#import "ViewController.h"
#import "TalkManager.h"

@interface ViewController ()
@property (nonatomic,strong)TalkManager *manager;
@property (nonatomic, strong) UIButton *btnAAC;
@property (nonatomic, strong) UIButton *btnG711A;
@property (nonatomic, strong) UIButton *btnG711U;
@property (nonatomic, strong) UITextField *tf1;
@property (nonatomic, strong) UITextField *tf2;
@end

//#define HOST_IP _tf1.text  // ip
//#define HOST_PORT [_tf2.text intValue]   // port
///*定义rtsp url*/
//#define RTSP_ADDRESS [NSString stringWithFormat:@"rtsp://%@:%@/hzcms_talk?token=1",_tf1.text,_tf2.text]   // rtsp url
#define HOST_IP @"172.17.2.85"
#define HOST_PORT 554
#define RTSP_ADDRESS @"rtsp://172.17.2.85:554/hzcms_talk?token=1"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addBtn];
}

- (void)addBtn {
    _manager = [TalkManager manager];
    
    _tf1 = [[UITextField alloc] initWithFrame:CGRectMake(100, 200, 200, 30)];
    _tf1.borderStyle = UITextBorderStyleRoundedRect;
    _tf1.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    [self.view addSubview:_tf1];
    _tf2 = [[UITextField alloc] initWithFrame:CGRectMake(100, 250, 100, 30)];
    _tf2.borderStyle = UITextBorderStyleRoundedRect;
    _tf2.keyboardType = UIKeyboardTypeNumbersAndPunctuation;
    [self.view addSubview:_tf2];
    
    _btnAAC = [UIButton buttonWithType:UIButtonTypeSystem];
    _btnAAC.frame = CGRectMake(30, 350, 100, 50);
    [_btnAAC setTitle:@"AAC" forState:UIControlStateNormal];
    [_btnAAC setTitle:@"stop" forState:UIControlStateSelected];
    [_btnAAC addTarget:self action:@selector(startAAC) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnAAC];
    
    _btnG711A = [UIButton buttonWithType:UIButtonTypeSystem];
    _btnG711A.frame = CGRectMake(130, 350, 100, 50);
    [_btnG711A setTitle:@"G711A" forState:UIControlStateNormal];
    [_btnG711A setTitle:@"stop" forState:UIControlStateSelected];
    [_btnG711A addTarget:self action:@selector(startG711A) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnG711A];
    
    _btnG711U = [UIButton buttonWithType:UIButtonTypeSystem];
    _btnG711U.frame = CGRectMake(230, 350, 100, 50);
    [_btnG711U setTitle:@"G711U" forState:UIControlStateNormal];
    [_btnG711U setTitle:@"stop" forState:UIControlStateSelected];
    [_btnG711U addTarget:self action:@selector(startG711U) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_btnG711U];
}

- (void)startAAC {
    _manager.ip = HOST_IP;
    _manager.port = HOST_PORT;
    _manager.url = RTSP_ADDRESS;
    _manager.type = AAC;
    _btnAAC.selected = !_btnAAC.selected;
    if (_btnAAC.selected) {
        [_manager startTalk];
        _btnG711A.userInteractionEnabled = NO;
        _btnG711U.userInteractionEnabled = NO;
    }
    else {
        [_manager stopTalk];
        _btnG711A.userInteractionEnabled = YES;
        _btnG711U.userInteractionEnabled = YES;
    }
}

- (void)startG711A {
    _manager.ip = HOST_IP;
    _manager.port = HOST_PORT;
    _manager.url = RTSP_ADDRESS;
    _manager.type = G711A;
    _btnG711A.selected = !_btnG711A.selected;
    if (_btnG711A.selected) {
        [_manager startTalk];
        _btnAAC.userInteractionEnabled = NO;
        _btnG711U.userInteractionEnabled = NO;
    }
    else {
        [_manager stopTalk];
        _btnAAC.userInteractionEnabled = YES;
        _btnG711U.userInteractionEnabled = YES;
    }
}

- (void)startG711U {
    _manager.ip = HOST_IP;
    _manager.port = HOST_PORT;
    _manager.url = RTSP_ADDRESS;
    _manager.type = G711U;
    _btnG711U.selected = !_btnG711U.selected;
    if (_btnG711U.selected) {
        [_manager startTalk];
        _btnAAC.userInteractionEnabled = NO;
        _btnG711A.userInteractionEnabled = NO;
    }
    else {
        [_manager stopTalk];
        _btnAAC.userInteractionEnabled = YES;
        _btnG711A.userInteractionEnabled = YES;
    }
}



@end
