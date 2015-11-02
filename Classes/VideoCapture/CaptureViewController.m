//
//  CaptureViewController.m
//  SBVideoCaptureDemo
//
//  Created by Pandara on 14-8-12.
//  Copyright (c) 2014年 Pandara. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import "CaptureViewController.h"
#import "SBCaptureToolKit.h"
#import "CenterProgress.h"
#import "POP.h"
#import "UIImage+VideoCapture.h"

typedef NS_ENUM(NSInteger, CaptureStatus){
    ready = 0,//
    recording,//录制
    readyCancel,//准备取消
    readyPlay,//录制完成
    playing,//播放中
    cancel,//关闭界面
    end,//发送
};

@interface CaptureViewController ()
@property (weak, nonatomic) IBOutlet CenterProgress *progress;


@property (weak, nonatomic) IBOutlet UIView *preview;
@property (weak, nonatomic) IBOutlet UIView *viewContainer;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *timeIcon;

@property (weak, nonatomic) IBOutlet UILabel *releaseCancel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *releaseCancel_bottom;
@property (weak, nonatomic) IBOutlet UIButton *upCancel;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *upCancel_bottom;

@property (weak, nonatomic) IBOutlet UIImageView *actionButton;
@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *playView;

@property (strong, nonatomic) UIImageView *focusRectView;

@property (strong, nonatomic) SBVideoRecorder *recorder;

@property (assign, nonatomic) CaptureStatus status;
@property (assign, nonatomic) CGPoint startpos;

@property (weak, nonatomic) IBOutlet UIButton *cancel;

@property (strong, nonatomic) NSURL *outPutUrl;
@property (assign, nonatomic) CGFloat duration;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;


@end

@implementation CaptureViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.progress.progressTintColor = [UIColor yellowColor];
    self.progress.trackTintColor = [UIColor clearColor];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [SBCaptureToolKit createVideoFolderIfNotExist];
    
    self.focusRectView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 90, 90)];
    _focusRectView.image = [UIImage VideoCapture_imageNamed:@"capture_touch_focus_not"];
    _focusRectView.alpha = 0;
    [self.preview addSubview:_focusRectView];
    
    self.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    [UIView animateWithDuration:0.4f animations:^{
        self.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    } completion:^(BOOL finished) {
        
    }];
    
    [self initView];
    [self initRecorder];
    _status = ready;
}




- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _recorder.preViewLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.preview.frame), CGRectGetHeight(self.preview.frame));

}



- (void)changeState:(CaptureStatus)st{
    NSLog(@"changeState from %ld to %ld", (long)_status, (long)st);
    
    if(_status == ready){
        if (st == recording) {
            _status = st;
            [self setStateView:recording];
        }
        
        if (st == cancel) {
            _status = st;
            [self cancelCapture];
        }
    }
    if(_status == recording){
        if (st == ready) {
            _status = st;
            
            [self setStateView:ready];
            [self initView];
        }
        if (st == readyCancel) {
            _status = st;
            [self setStateView:readyCancel];
        }
        if (st == readyPlay) {
            _status = st;
            
            [self clearRecord];
            [self initVideoFilePath:_outPutUrl];
            
            [self readyPlay];
        }
    }
    if(_status == readyCancel){
        if (st == ready) {
            _status = st;
            
            [self setStateView:ready];
            [self initView];
        }
        if (st == recording) {
            _status = st;
            [self setStateView:recording];
        }
        if (st == cancel) {
            _status = st;
            [self cancelCapture];
        }
    }
    if(_status == readyPlay){
        if (st == ready) {
            _status = st;
            [self clearPlay];
            
            [self initRecorder];
            [self initView];
        }
        
        if (st == playing) {
            _status = st;
            [self play];
        }
        
        if (st == end) {
            _status = st;
            [self sendVideo];
        }
    }
    if(_status == playing){
        if (st == readyPlay) {
            _status = st;
             [self readyPlay];
        }
    }
    
}

-(void)initView{
    
    self.progress.progress = 1.0;
    self.progress.alpha = 0.0;
    
    self.timeLabel.text = @"00:10";
    self.timeLabel.alpha = 0.0;
    self.timeIcon.alpha = 0.0;
    self.releaseCancel.alpha = 0.0;
    
    self.upCancel.alpha = 0.0;
    self.upCancel_bottom.constant = 0.0;
    self.actionButton.alpha = 1.0;
    
    self.cancel.alpha = 1.0;
    
}

- (void)initRecorder
{
    self.statusView.hidden = FALSE;
    self.playView.hidden = YES;
    // record view
    self.recorder = [SBVideoRecorder getInstance];
    _recorder.delegate = self;
    _recorder.preViewLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.preview.frame), CGRectGetHeight(self.preview.frame));
    [self.preview.layer addSublayer:_recorder.preViewLayer];
}

- (void)initVideoFilePath:(NSURL*)url{
    
    self.statusView.hidden = YES;
    self.playView.hidden = FALSE;
    // play view
    NSLog(@"initAndplayVideoFilePath %@ ", url);
    if (_playerLayer == nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(avPlayerItemDidPlayToEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        
        _playerLayer = [[AVPlayerLayer alloc] init];
        _playerLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.preview.frame) , CGRectGetHeight(self.preview.frame));
        _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        [self.preview.layer addSublayer:_playerLayer];
    }
    self.playerItem = [[AVPlayerItem alloc] initWithURL:url];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    [self.playerLayer setPlayer:self.player];
}

- (void)readyPlay{
    [[self.playView subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.hidden = FALSE;
    }];
    
    [self.playerItem seekToTime:kCMTimeZero];
    [self.player pause];
}

- (void)play{
    [[self.playView subviews] enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.hidden = YES;
    }];
    
    [self.playerItem seekToTime:kCMTimeZero];
    [self.player play];
}





#pragma mark - PlayEndNotification
- (void)avPlayerItemDidPlayToEnd:(NSNotification *)notification
{
    if ((AVPlayerItem *)notification.object != _playerItem) {
        return;
    }
    [self changeState:readyPlay];
}

- (void)clearRecord{
    if (_recorder != nil) {
        [_recorder.preViewLayer removeFromSuperlayer];
        _recorder = nil;
    }
}

- (void)clearPlay{
    if (_playerLayer){
        [_playerLayer removeFromSuperlayer];
    }

    _playerItem = nil;
    _player = nil;
    _playerLayer = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}




- (void)dismissView
{
    self.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    [UIView animateWithDuration:0.3f animations:^{
        self.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    } completion:^(BOOL finished) {
        [self.view removeFromSuperview];
    }];
    
}

- (void)sendVideo {
    [self dismissView];
    if (self.completBlock) {
        self.completBlock(self.outPutUrl, self.duration, nil);
    }
}

- (void)cancelCapture {
    [self dismissView];
    if (self.completBlock) {
        self.completBlock(nil, 0, [NSError errorWithDomain:@"cancel" code:0 userInfo:nil]);
    }
}

- (IBAction)cancel:(id)sender {
    [self changeState:cancel];
}

- (IBAction)playClick:(id)sender {
    [self changeState:playing];
    
}

- (IBAction)sendClick:(id)sender {
     [self changeState:end];
}
- (IBAction)cancelPlay:(id)sender {
     [self changeState:ready];
}


- (void)showFocusRectAtPoint:(CGPoint)point
{
    _focusRectView.alpha = 1.0f;
    _focusRectView.center = point;
    _focusRectView.transform = CGAffineTransformMakeScale(1.5f, 1.5f);
    [UIView animateWithDuration:0.2f animations:^{
        _focusRectView.transform = CGAffineTransformMakeScale(1.0f, 1.0f);
    } completion:^(BOOL finished) {
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
        animation.values = @[@0.5f, @1.0f, @0.5f, @1.0f, @0.5f, @1.0f];
        animation.duration = 0.5f;
        [_focusRectView.layer addAnimation:animation forKey:@"opacity"];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.7f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:0.3f animations:^{
                _focusRectView.alpha = 0;
            }];
        });
    }];
}



#pragma mark - SBVideoRecorderDelegate
- (void)videoRecorder:(SBVideoRecorder *)videoRecorder didStartRecordingToOutPutFileAtURL:(NSURL *)fileURL
{
    NSLog(@"正在录制视频: %@", fileURL);
    
}

- (void)videoRecorder:(SBVideoRecorder *)videoRecorder didFinishRecordingToOutPutFileAtURL:(NSURL *)outputFileURL duration:(CGFloat)videoDuration totalDur:(CGFloat)totalDur error:(NSError *)error
{
    if ([@"cancel" isEqualToString:error.domain]) {
        NSLog(@"录制视频取消:%@", error);
        [self changeState:ready];
        return;
    }
    if ([@"timeNotEnough" isEqualToString:error.domain]) {
        NSLog(@"录制视频太短:%@", error);
        [self changeState:ready];
        return;
    }
    NSLog(@"录制视频完成: %@", outputFileURL);
    _outPutUrl = outputFileURL;
    _duration = videoDuration;
    [self changeState:readyPlay];
    
//    [self dismissView];
//    if (self.completBlock) {
//        if (error) {
//            self.completBlock(nil, 0, error);
//        }else{
//            NSString *filePath = [[outputFileURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
//            self.completBlock(filePath, videoDuration, error);
//        }
//    }
}

//recorder正在录制的过程中
- (void)videoRecorder:(SBVideoRecorder *)videoRecorder didRecordingToOutPutFileAtURL:(NSURL *)outputFileURL duration:(CGFloat)videoDuration recordedVideosTotalDur:(CGFloat)totalDur
{
    CGFloat left = MAX_VIDEO_DUR - videoDuration;
    self.timeLabel.text = [NSString stringWithFormat:@"00:%0.0f", left];
    self.progress.progress = left * 1.0 / MAX_VIDEO_DUR;
}




-(void)startAnim:(void (^)(BOOL finished))completion{
    float duration = 0.3;
    
    self.releaseCancel.alpha = 0.0;
    
    [UIView animateWithDuration:duration animations:^{
        self.progress.alpha = 1.0;
        
    } completion:^(BOOL finished) {
        self.cancel.alpha = 0.0;
        self.timeLabel.alpha = 1.0;
        self.timeIcon.alpha = 1.0;
        CAKeyframeAnimation *anim = [self opacityForeverKeyFrame:0.5];
        [self.timeIcon.layer addAnimation:anim forKey:@"flash"];
        completion(finished);
    }];
    
    POPBasicAnimation *actionButtonAnimation = [POPBasicAnimation animation];
    actionButtonAnimation.property = [POPAnimatableProperty propertyWithName:kPOPViewScaleXY];
    actionButtonAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(1.2, 1.2)];
    actionButtonAnimation.duration = duration;
    [actionButtonAnimation setRemovedOnCompletion:YES];
    [actionButtonAnimation setCompletionBlock:^(POPAnimation *ani, BOOL ret) {
        self.actionButton.transform = CGAffineTransformIdentity;
    }];
    [self.actionButton pop_addAnimation:actionButtonAnimation forKey:@"actionButtonAnimation"];

    self.upCancel.alpha = 1.0;
    POPBasicAnimation *upCancelMove = [POPBasicAnimation animation];
    upCancelMove.property = [POPAnimatableProperty propertyWithName:kPOPViewCenter];
    CGPoint center = self.upCancel.center;
    upCancelMove.fromValue = [NSValue valueWithCGPoint:CGPointMake(center.x, center.y)];
    upCancelMove.toValue = [NSValue valueWithCGPoint:CGPointMake(center.x, center.y - 20)];
    upCancelMove.duration = duration;
    [upCancelMove setRemovedOnCompletion:YES];
    [upCancelMove setCompletionBlock:^(POPAnimation *ani, BOOL ret) {
        self.upCancel.transform = CGAffineTransformIdentity;
    }];
    [self.upCancel pop_addAnimation:upCancelMove forKey:@"upCancelMove"];
    
//    self.actionButton.transform = CGAffineTransformIdentity;
//    self.actionButton.scaleX = 1.2;
//    self.actionButton.scaleY = 1.2;
//    self.actionButton.opacity = 0.0;
//    self.actionButton.duration = duration;
//    self.actionButton.curve = @"easeOut";
//    self.actionButton.damping = 2.0;
//    [self.actionButton animateToNext:^{
//        self.actionButton.scaleX = 1.0;
//        self.actionButton.scaleY = 1.0;
//        self.actionButton.transform = CGAffineTransformIdentity;
//    }];
//    
//    self.upCancel.opacity = 1.0;
//    self.upCancel.y = -20;
//    self.upCancel.duration = duration;
//    self.actionButton.curve = @"easeIn";
//    [self.upCancel animateToNext:^{
//    }];
    
}


-(CAKeyframeAnimation *)opacityForeverKeyFrame:(float)time{
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    animation.keyTimes = @[@0.0, @0.49, @0.51, @1.0];
    animation.values = @[@0, @0, @1, @1];
    animation.autoreverses = YES;
    animation.duration = time;
    animation.repeatCount = FLT_MAX;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    return animation;
}

-(CABasicAnimation *)opacityForever:(float)time{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @1.0;
    animation.toValue = @0.0;
    animation.autoreverses = YES;
    animation.duration = time;
    animation.repeatCount = FLT_MAX;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    return animation;
}

-(void)setStateView:(CaptureStatus)status{
    float duration = 0.7;
    

    if (status == readyCancel) {
        self.upCancel.alpha = 0.0;
        self.releaseCancel.alpha = 1.0;
        
        self.releaseCancel.text = @"松开取消";
        self.releaseCancel_bottom.constant = -20.0;
        
        POPBasicAnimation *releaseCancelAni = [POPBasicAnimation animation];
        releaseCancelAni.property = [POPAnimatableProperty propertyWithName:kPOPViewScaleXY];
        releaseCancelAni.fromValue = [NSValue valueWithCGSize:CGSizeMake(1.0, 0.01)];
        releaseCancelAni.toValue = [NSValue valueWithCGSize:CGSizeMake(1.0, 1.0)];
        releaseCancelAni.duration = duration;
        [releaseCancelAni setCompletionBlock:^(POPAnimation *ani, BOOL ret) {
            self.releaseCancel.transform = CGAffineTransformIdentity;
        }];
        [self.releaseCancel pop_addAnimation:releaseCancelAni forKey:@"releaseCancelAni"];

//        self.releaseCancel.scaleY = 0.0;
//        self.releaseCancel.duration = duration;
//        [self.releaseCancel animate];
    }else if (status == ready) {
        self.upCancel.alpha = 0.0;
        self.releaseCancel.alpha = 1.0;
        self.progress.alpha = 0.0;
        
        self.releaseCancel.transform = CGAffineTransformIdentity;
        self.releaseCancel.text = @"手指不要放开";
        //const失效
        self.releaseCancel_bottom.constant = -20.0;
        
        POPBasicAnimation *releaseCancelAni = [POPBasicAnimation animation];
        releaseCancelAni.property = [POPAnimatableProperty propertyWithName:kPOPViewScaleXY];
        releaseCancelAni.fromValue = [NSValue valueWithCGSize:CGSizeMake(1.0, 0.0)];
        releaseCancelAni.toValue = [NSValue valueWithCGSize:CGSizeMake(1.0, 1.0)];
        releaseCancelAni.duration = duration;
        [self.releaseCancel pop_addAnimation:releaseCancelAni forKey:@"releaseCancelAni"];

//        self.releaseCancel.scaleY = 0.0;
//        self.releaseCancel.duration = duration;
//        [self.releaseCancel animate];
    }else if (status == recording) {
        self.upCancel.alpha = 1.0;
        
        POPBasicAnimation *releaseCancelAni = [POPBasicAnimation animation];
        releaseCancelAni.property = [POPAnimatableProperty propertyWithName:kPOPViewScaleXY];
        releaseCancelAni.fromValue = [NSValue valueWithCGSize:CGSizeMake(1.0, 1.0)];
        releaseCancelAni.toValue = [NSValue valueWithCGSize:CGSizeMake(0.0, 0.0)];
        releaseCancelAni.duration = duration;
        [self.releaseCancel pop_addAnimation:releaseCancelAni forKey:@"releaseCancelAni"];
        

//        self.releaseCancel.alpha = 0.0;
        
//        self.releaseCancel.transform = CGAffineTransformIdentity;
//        self.releaseCancel.scaleY = 0.01;
//        self.releaseCancel.scaleX = 0.01;
//        self.releaseCancel.duration = duration;
//        [self.releaseCancel animateToNext:^{
//            
//        }];
    }
}

-(void)endAnim{
    self.actionButton.alpha = 1.0;
    [self.actionButton.layer removeAllAnimations];
    self.cancel.alpha = 1.0;
    
    self.upCancel.alpha = 0.0;
    self.timeIcon.alpha = 0.0;
    [self.timeIcon.layer removeAllAnimations];
    self.timeLabel.alpha = 0.0;
    
    float duration = 0.7;
    
    POPBasicAnimation *releaseCancelAni = [POPBasicAnimation animation];
    releaseCancelAni.property = [POPAnimatableProperty propertyWithName:kPOPViewScaleXY];
    releaseCancelAni.fromValue = [NSValue valueWithCGSize:CGSizeMake(1.0, 1.0)];
    releaseCancelAni.toValue = [NSValue valueWithCGSize:CGSizeMake(0.0, 0.0)];
    releaseCancelAni.duration = duration;
    [self.releaseCancel pop_addAnimation:releaseCancelAni forKey:@"releaseCancelAni"];


   
}

#pragma mark - Touch Event
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    UITouch *touch = [touches anyObject];
    _startpos = [touch locationInView:self.view];
    CGPoint touchPoint = [touch locationInView:self.statusView];
    if (self.status == ready && CGRectContainsPoint(self.actionButton.frame, touchPoint)) {
        [self startAnim:^(BOOL finished) {
            
            
        }];
        NSString *filePath = [SBCaptureToolKit getVideoSaveFilePathString];
        [_recorder startRecordingToOutputFileURL:[NSURL fileURLWithPath:filePath]];
        [self changeState:recording];

        return;
    }
    
    if (self.status == ready && CGRectContainsPoint(self.cancel.frame, touchPoint)) {
        [self changeState:cancel];
        return;
    }
    
    touchPoint = [touch locationInView:self.preview];//previewLayer 的 superLayer所在的view
    if (CGRectContainsPoint(_recorder.preViewLayer.frame, touchPoint)) {
        [self showFocusRectAtPoint:touchPoint];
        [_recorder focusInPoint:touchPoint];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.view];
    if (self.status == recording || self.status == readyCancel) {
        if (self.status == readyCancel && CGRectContainsPoint(self.statusView.frame, touchPoint)) {
            [self changeState:recording];
        }
        if (!CGRectContainsPoint(self.statusView.frame, touchPoint)) {
            if (self.status == recording) {
                [self changeState:readyCancel];
            }
            CGPoint p = [touch locationInView:self.viewContainer];
            CGRect rect = self.releaseCancel.frame;
            rect.origin.y = p.y;
            self.releaseCancel.frame = rect;
        }
    }
    
//    if (self.status == ready) {
//        if (touchPoint.y - _startpos.y > 10) {
//            [self cancel:nil];
//        }
//    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [self endAnim];
    if(self.status == recording){
        [_recorder stopCurrentVideoRecording];
    }
    if (self.status == readyCancel) {
        [_recorder cancelCurrentVideoRecording];
    }
    
}



@end



















