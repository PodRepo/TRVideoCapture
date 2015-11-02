//
//  UIImage+UzysExtension.m
//  UzysAssetsPickerController
//
//  Created by jianpx on 8/26/14.
//  Copyright (c) 2014 Uzys. All rights reserved.
//

#import "CaptureViewController.h"
#import "UIImage+VideoCapture.h"

@implementation UIImage (VideoCapture)

+ (UIImage *)VideoCapture_imageNamed:(NSString *)imageName
{
    UIImage *image = [[self class] imageNamed:imageName];
    if (image) {
        return image;
    }

    //for Swift podfile
    NSString *imagePathInFrameworkForClass = [NSString stringWithFormat:@"%@/%@", [[NSBundle bundleForClass:[CaptureViewController class]] resourcePath], imageName ];
    image = [[self class] imageNamed:imagePathInFrameworkForClass];
    if (image) {
        return image;
    }
//    //bundel
//    NSString *bundelName = @"capture.bundle";
//    NSString *imagePathInBundleForClass = [NSString stringWithFormat:@"%@/%@/%@", [[NSBundle bundleForClass:[CaptureViewController class]] resourcePath],bundelName, imageName];
//    image = [[self class] imageNamed:imagePathInBundleForClass];
    return image;
}
@end
