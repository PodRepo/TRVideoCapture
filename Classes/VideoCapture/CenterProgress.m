//
//  BJRangeSliderWithProgress.m
//  BJRangeSliderWithProgress
//
//  Created by Barrett Jacobsen on 7/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CenterProgress.h"

@implementation CenterProgress

-(void)setProgress:(CGFloat)progress{
    _progress = progress;
    self.backgroundColor = [UIColor clearColor];
    [self setNeedsDisplay];
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {

    // 获取CGContext，注意UIKit里用的是一个专门的函数
    CGContextRef context = UIGraphicsGetCurrentContext();
    UIGraphicsPushContext(context);
    
    CGFloat r, g, b, a;
    [self.trackTintColor getRed:&r green:&g blue:&b alpha:&a];
    CGContextSetRGBFillColor(context, r, g, b, a);
    CGContextFillRect(context, rect);
    
    [self.progressTintColor getRed:&r green:&g blue:&b alpha:&a];
    CGContextSetRGBFillColor(context, r, g, b, a);
    CGFloat len = (1 - self.progress) * CGRectGetWidth(rect) * 0.5;
    CGRect blaceRect = CGRectMake(CGRectGetMinX(rect) + len, CGRectGetMinY(rect), CGRectGetWidth(rect) - len * 2.0, CGRectGetHeight(rect));
    CGContextFillRect(context, blaceRect);
    
    UIGraphicsPopContext();
}


@end
