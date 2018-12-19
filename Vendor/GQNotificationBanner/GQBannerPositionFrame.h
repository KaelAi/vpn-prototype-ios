//
//  GQBannerPositionFrame.h
//  GQNotificationBanner
//
//  Created by Bright on 2018/11/2.
//  Copyright © 2018 Bright. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "GQBannerConfig.h"

NS_ASSUME_NONNULL_BEGIN

@interface GQBannerPositionFrame : NSObject

@property (assign, nonatomic) CGRect startFrame;
@property (assign, nonatomic) CGRect endFrame;

- (instancetype)initWithPosition:(GQBannerPosition)bannerPosition bannerWidth:(CGFloat)bannerWidth bannerHeight:(CGFloat)bannerHeight maxY:(CGFloat)maxY padding:(CGFloat)padding;

@end

NS_ASSUME_NONNULL_END
