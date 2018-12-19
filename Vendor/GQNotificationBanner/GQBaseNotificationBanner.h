//
//  GQBaseNotificationBanner.h
//  GQNotificationBanner
//
//  Created by Bright on 2018/11/2.
//  Copyright © 2018 Bright. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GQBannerConfig.h"
#import "GQBannerPositionFrame.h"
#import "GQNotificationBannerQueue.h"
//#import <MarqueeLabel/MarqueeLabel.h>

NS_ASSUME_NONNULL_BEGIN

@class GQBaseNotificationBanner;

@protocol GQBaseNotificationBannerDelegate <NSObject>

- (void)notificationBannerWillAppear:(GQBaseNotificationBanner *)banner;
- (void)notificationBannerDidAppear:(GQBaseNotificationBanner *)banner;
- (void)notificationBannerWillDisappear:(GQBaseNotificationBanner *)banner;
- (void)notificationBannerDidDisappear:(GQBaseNotificationBanner *)banner;

@end

@interface GQBaseNotificationBanner : UIView

@property (weak, nonatomic) id<GQBaseNotificationBannerDelegate> delegate;

@property (strong, nonatomic) GQBannerConfig *config;
@property (assign, nonatomic) BOOL isDisplaying;
@property (assign, nonatomic) BOOL isSuspended;
@property (strong, nonatomic) UIColor *backgroundColor;
//@property (strong, nonatomic) MarqueeLabel *titleLabel;
@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UIView *contentView;
@property (strong, nonatomic) UIView *spacerView;
@property (strong, nonatomic) UIWindow *appWindow;

- (instancetype)initWithConfig:(GQBannerConfig *)config;
- (void)show;
- (void)dismiss;
- (void)remove;
- (void)suspend;
- (void)resume;
- (void)setBannerHeight:(CGFloat)bannerHeight;
- (CGFloat)getBannerHeight;
- (void)updateMarqueeLabelsDurations;
- (BOOL)shouldAdjustForNotchFeaturedIphone;


@end

NS_ASSUME_NONNULL_END
