//
//  CaptureViewController.h
//  SBVideoCaptureDemo
//
//  Created by Pandara on 14-8-12.
//  Copyright (c) 2014年 Pandara. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SBCaptureDefine.h"
#import "SBVideoRecorder.h"

typedef void(^CaptureViewControllerCompletedBlock)(NSString *outputFile, CGFloat videoDuration, NSError *error);

@interface CaptureViewController : UIViewController <SBVideoRecorderDelegate>
@property (readwrite, nonatomic, copy) CaptureViewControllerCompletedBlock completBlock;
@end
