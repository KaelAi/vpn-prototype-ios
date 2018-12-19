//
//  GQNotificationBanner.h
//  GQNotificationBanner
//
//  Created by Bright on 2018/11/5.
//  Copyright © 2018 Bright. All rights reserved.
//

#import "GQBaseNotificationBanner.h"

NS_ASSUME_NONNULL_BEGIN

@interface GQNotificationBanner : GQBaseNotificationBanner

//@property (strong, nonatomic) MarqueeLabel *subTitleLabel;
@property (strong, nonatomic) UILabel *subTitleLabel;

- (instancetype)initWithTitle:(NSString *)title config:(GQBannerConfig *)config;
- (instancetype)initWithCustomView:(UIView *)customView;

@end

NS_ASSUME_NONNULL_END
