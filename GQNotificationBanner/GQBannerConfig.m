//
//  GQBannerConfig.m
//  GQNotificationBanner
//
//  Created by Bright on 2018/11/11.
//  Copyright © 2018 Bright. All rights reserved.
//

#import "GQBannerConfig.h"

NSNotificationName const kBannerWillAppear = @"kBannerWillAppear";
NSNotificationName const kBannerDidAppear = @"kBannerDidAppear";
NSNotificationName const kBannerWillDisappear = @"kBannerWillDisappear";
NSNotificationName const kBannerDidDisappear = @"kBannerDidDisappear";
NSNotificationName const kBannerObjectKey = @"kBannerObjectKey";


@implementation GQBannerConfig

- (instancetype)init {
    if (self = [super init]) {
        [self initialization];
    }
    return self;
}

- (void)initialization {
    _dismissOnTap = YES;
    _dismissOnSwipeUp = YES;
    _autoDismiss = YES;
    _placeOnQueue = YES;
    _shadow = YES;
    _padding = 10.0;
}

+ (instancetype)bannerConfig {
    return [[self alloc] init];
}

#pragma mark - - view property
- (UIColor *)bannerColor {
    if (!_bannerColor) {
        _bannerColor = [self colorWithStyle:self.bannerStyle];
    }
    return _bannerColor;
}

- (GQBannerStyle)bannerStyle {
    if (_bannerStyle == 0) {
        _bannerStyle = GQBannerStyle_info;
    }
    return _bannerStyle;
}

- (GQBannerPosition)bannerPosition {
    if (_bannerPosition == 0) {
        _bannerPosition = GQBannerPosition_top;
    }
    return _bannerPosition;
}

- (GQQueuePosition)queuePosition {
    if (_queuePosition == 0) {
        _queuePosition = GQQueuePosition_back;
    }
    return _queuePosition;
}

- (UIFont *)titleFont {
    if (!_titleFont) {
        _titleFont = [UIFont systemFontOfSize:16];
    }
    return _titleFont;
}

- (UIColor *)titleColor {
    if (!_titleColor) {
        _titleColor = [UIColor blackColor];
    }
    return _titleColor;
}

- (UIFont *)subTitleFont {
    if (!_subTitleFont) {
        _subTitleFont = [UIFont systemFontOfSize:14 weight:UIFontWeightLight];
    }
    return _subTitleFont;
}

- (UIColor *)subTitleColor {
    if (!_subTitleColor) {
        _subTitleColor = [UIColor grayColor];
    }
    return _subTitleColor;
}

- (UIColor *)shadowColor {
    if (!_shadowColor) {
        _shadowColor = [UIColor blackColor];
    }
    return _shadowColor;
}

#pragma mark - animation property
-(NSTimeInterval)duration {
    if (_duration == 0.0) {
        _duration = 5.0;
    }
    return _duration;
}

- (NSTimeInterval)dismissDuration {
    if (_dismissDuration == 0.0) {
        _dismissDuration = 0.5;
    }
    return _dismissDuration;
}

#pragma mark - set
- (void)setAutoDismiss:(BOOL)autoDismiss {
    _autoDismiss = autoDismiss;
    if (!autoDismiss) {
        self.dismissOnSwipeUp = NO;
        self.dismissOnTap = NO;
    }
}

#pragma mark - private
- (UIColor *)colorWithStyle:(GQBannerStyle)style {
    switch (style) {
        case GQBannerStyle_danger:
            return [UIColor colorWithRed:0.90 green:0.31 blue:0.26 alpha:1.00];
            break;
        case GQBannerStyle_info:
            return [UIColor colorWithRed:255.0 green:255.0 blue:255.0 alpha:0.9];
            break;
        case GQBannerStyle_success:
            return [UIColor colorWithRed:0.22 green:0.80 blue:0.46 alpha:1.00];
            break;
        case GQBannerStyle_warning:
            return [UIColor colorWithRed:1.00 green:0.66 blue:0.16 alpha:1.00];
            break;
        default:
            break;
    }
    return [UIColor clearColor];
}

@end
