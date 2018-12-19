//
//  GQBannerPositionFrame.m
//  GQNotificationBanner
//
//  Created by Bright on 2018/11/2.
//  Copyright © 2018 Bright. All rights reserved.
//

#import "GQBannerPositionFrame.h"

@interface GQBannerPositionFrame ()

@end

@implementation GQBannerPositionFrame


- (instancetype)initWithPosition:(GQBannerPosition)bannerPosition bannerWidth:(CGFloat)bannerWidth bannerHeight:(CGFloat)bannerHeight maxY:(CGFloat)maxY padding:(CGFloat)padding {
    if (self = [super init]) {
        self.startFrame = [self setupStartFrameWithPosition:bannerPosition bannerWidth:bannerWidth bannerHeight:bannerHeight maxY:maxY padding:padding];
        self.endFrame = [self setupEndFrameWithPosition:bannerPosition bannerWidth:bannerWidth bannerHeight:bannerHeight maxY:maxY padding:padding];
    }
    return self;
}

- (CGRect)setupStartFrameWithPosition:(GQBannerPosition)bannerPosition bannerWidth:(CGFloat)bannerWidth bannerHeight:(CGFloat)bannerHeight maxY:(CGFloat)maxY padding:(CGFloat)padding {
    switch (bannerPosition) {
        case GQBannerPosition_bottom:
            return CGRectMake(padding, maxY + padding, bannerWidth - 2 * padding, bannerHeight);
            break;
        case GQBannerPosition_top:
            return CGRectMake(padding, -bannerHeight - padding, bannerWidth - 2 * padding, bannerHeight);
        default:
            break;
    }
    return CGRectMake(0, 0, 0, 0);
}

- (CGRect)setupEndFrameWithPosition:(GQBannerPosition)bannerPosition bannerWidth:(CGFloat)bannerWidth bannerHeight:(CGFloat)bannerHeight maxY:(CGFloat)maxY padding:(CGFloat)padding {
    switch (bannerPosition) {
        case GQBannerPosition_bottom:
            return CGRectMake(padding, maxY - bannerHeight - padding, bannerWidth - 2 * padding, bannerHeight);
            break;
        case GQBannerPosition_top:
            return CGRectMake(padding, padding, self.startFrame.size.width, self.startFrame.size.height);
        default:
            break;
    }
    return CGRectMake(0, 0, 0, 0);
}

@end
