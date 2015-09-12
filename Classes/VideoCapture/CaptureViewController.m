//
//  CaptureViewController.m
//  SBVideoCaptureDemo
//
//  Created by Pandara on 14-8-12.
//  Copyright (c) 2014年 Pandara. All rights reserved.
//


#import <QuartzCore/QuartzCore.h>

#import "CaptureViewController.h"
#import "SBCaptureToolKit.h"
#import "CenterProgress.h"


typedef NS_ENUM(NSInteger, CaptureStatus){
    ready = 0,
    start_sending,
    start_cancel,
    end,
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

@property (strong, nonatomic) UIImageView *focusRectView;

@property (strong, nonatomic) SBVideoRecorder *recorder;

@property (assign, nonatomic) BOOL initalized;
@property (assign, nonatomic) CaptureStatus status;
@property (assign, nonatomic) CGPoint startpos;

@property (weak, nonatomic) IBOutlet UIButton *cancel;


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
    
    [self initView];
    [self appear];
    if (_initalized) {
        return;
    }
    [self initRecorder];
    [SBCaptureToolKit createVideoFolderIfNotExist];
    [self initTopLayout];
    self.initalized = YES;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    _recorder.preViewLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.preview.frame), CGRectGetHeight(self.preview.frame));

}


- (void)initRecorder
{
    self.recorder = [SBVideoRecorder getInstance];
    _recorder.delegate = self;
    _recorder.preViewLayer.frame = CGRectMake(0, 0, CGRectGetWidth(self.preview.frame), CGRectGetHeight(self.preview.frame));
    [self.preview.layer addSublayer:_recorder.preViewLayer];
}



- (void)initTopLayout
{
    self.focusRectView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 90, 90)];
    _focusRectView.image = [UIImage imageNamed:@"capture_touch_focus_not.png"];
    _focusRectView.alpha = 0;
    [self.preview addSubview:_focusRectView];
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

- (IBAction)cancel:(id)sender {
    self.status = end;
    [self dismissView];
    if (self.completBlock) {
        self.completBlock(nil, 0, [NSError errorWithDomain:@"cancel" code:0 userInfo:nil]);
    }

}


- (void)appear
{
    self.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];
    [UIView animateWithDuration:0.4f animations:^{
        self.view.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    } completion:^(BOOL finished) {
       
    }];
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
    if (error) {
        NSLog(@"录制视频错误:%@", error);
    } else {
        NSLog(@"录制视频完成: %@", outputFileURL);
    }
    
    if (!error && totalDur < MIN_VIDEO_DUR) {
        [self endAnim];
        self.status = ready;
        [self changeStatus:ready];
        return;
    }
    [self endAnim];
    self.status = end;
    [self dismissView];
    if (self.completBlock) {
        if (error) {
            self.completBlock(nil, 0, error);
        }else{
            NSString *filePath = [[outputFileURL absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""];
            self.completBlock(filePath, videoDuration, error);
        }
    }
}

//recorder正在录制的过程中
- (void)videoRecorder:(SBVideoRecorder *)videoRecorder didRecordingToOutPutFileAtURL:(NSURL *)outputFileURL duration:(CGFloat)videoDuration recordedVideosTotalDur:(CGFloat)totalDur
{
    CGFloat left = MAX_VIDEO_DUR - videoDuration;
    self.timeLabel.text = [NSString stringWithFormat:@"00:%0.0f", left];
    self.progress.progress = left * 1.0 / MAX_VIDEO_DUR;
}


-(void)initView{
    self.status = ready;
    
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


-(void)startAnim:(void (^)(BOOL finished))completion{
    float duration = 0.7;
    
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

-(void)changeStatus:(CaptureStatus)status{
    float duration = 0.7;
    if (status == start_cancel) {
        self.upCancel.alpha = 0.0;
        self.releaseCancel.alpha = 1.0;
        
        self.releaseCancel.transform = CGAffineTransformIdentity;
        self.releaseCancel.text = @"松开发送";
        self.releaseCancel_bottom.constant = -20.0;
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
//        self.releaseCancel.scaleY = 0.0;
//        self.releaseCancel.duration = duration;
//        [self.releaseCancel animate];
    }else{
        self.upCancel.alpha = 1.0;
//        self.releaseCancel.alpha = 0.0;
        
        self.releaseCancel.transform = CGAffineTransformIdentity;
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
    if (self.status == start_cancel) {
        
        self.releaseCancel.transform = CGAffineTransformIdentity;
//        self.releaseCancel.scaleY = 0.01;
//        self.releaseCancel.scaleX = 0.01;
//        self.releaseCancel.duration = duration;
//        [self.releaseCancel animateToNext:^{
//            
//        }];
    }else{

    }
}

#pragma mark - Touch Event
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    
    UITouch *touch = [touches anyObject];
    _startpos = [touch locationInView:self.view];
    CGPoint touchPoint = [touch locationInView:self.statusView];
    if (self.actionButton.alpha > 0.0 && CGRectContainsPoint(self.actionButton.frame, touchPoint)) {
        [self startAnim:^(BOOL finished) {
            
            
        }];
        NSString *filePath = [SBCaptureToolKit getVideoSaveFilePathString];
        [_recorder startRecordingToOutputFileURL:[NSURL fileURLWithPath:filePath]];
        self.status = start_sending;

        return;
    }
    
    if (self.cancel.alpha > 0.0 && CGRectContainsPoint(self.cancel.frame, touchPoint)) {
        [self cancel:self.cancel];
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
    if (self.status == start_sending || self.status == start_cancel) {
        if (self.status == start_cancel && CGRectContainsPoint(self.statusView.frame, touchPoint)) {
            self.status = start_sending;
            [self changeStatus:start_sending];
        }
        if (!CGRectContainsPoint(self.statusView.frame, touchPoint)) {
            if (self.status == start_sending) {
                self.status = start_cancel;
                [self changeStatus:start_cancel];
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
    if (self.status == ready) {
         NSLog(@"ready");

//        [self changeStatus:ready];
        return;
    }
    if (self.status == start_cancel) {
        [_recorder cancelCurrentVideoRecording];
    }else if(self.status == start_sending){
        [_recorder stopCurrentVideoRecording];
    }else{
        NSLog(@"already end");
    }
    self.status = end;
}



@end



















