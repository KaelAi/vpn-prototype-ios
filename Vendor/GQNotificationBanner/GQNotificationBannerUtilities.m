//
//  GQNotificationBannerUtilities.m
//  GQNotificationBanner
//
//  Created by Bright on 2018/11/5.
//  Copyright © 2018 Bright. All rights reserved.
//

#import "GQNotificationBannerUtilities.h"
#import <UIKit/UIKit.h>

@implementation GQNotificationBannerUtilities

+ (BOOL)isNotchFeaturedIPhone {
    if (@available(iOS 11.0, *)) {
        CGFloat bottom = [UIApplication sharedApplication].windows.firstObject.safeAreaInsets.bottom;
        if (bottom > 0) {
            return YES;
        }
    }
    return NO;
}

@end
