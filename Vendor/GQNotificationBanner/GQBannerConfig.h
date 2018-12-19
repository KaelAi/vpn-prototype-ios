//
//  GQBannerConfig.h
//  GQNotificationBanner
//
//  Created by Bright on 2018/11/11.
//  Copyright © 2018 Bright. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, GQBannerStyle) {
    GQBannerStyle_none = 1,
    GQBannerStyle_info = 2,
    GQBannerStyle_danger = 3,
    GQBannerStyle_success = 4,
    GQBannerStyle_warning = 5
};

typedef NS_ENUM(NSInteger, GQQueuePosition) {
    GQQueuePosition_back = 1,
    GQQueuePosition_front = 2
};

typedef NS_ENUM(NSInteger, GQBannerPosition) {
    GQBannerPosition_bottom = 1,
    GQBannerPosition_top = 2
};

typedef void (^OnTapBlock)(void);

typedef void (^OnSwipTapBlock)(void);


UIKIT_EXTERN NSNotificationName const kBannerWillAppear;
UIKIT_EXTERN NSNotificationName const kBannerDidAppear;
UIKIT_EXTERN NSNotificationName const kBannerWillDisappear;
UIKIT_EXTERN NSNotificationName const kBannerDidDisappear;
UIKIT_EXTERN NSNotificationName const kBannerObjectKey;

NS_ASSUME_NONNULL_BEGIN

@interface GQBannerConfig : NSObject

/** class method create */
+ (instancetype)bannerConfig;

@property (strong, nonatomic) UIView *leftView;
@property (strong, nonatomic) UIView *rightView;
@property (strong, nonatomic) UIColor *bannerColor;
@property (copy, nonatomic) NSString *subTitle;
@property (assign, nonatomic) CGFloat padding;
@property (assign, nonatomic) BOOL placeOnQueue;

@property (assign, nonatomic) BOOL shadow;
@property (strong, nonatomic) UIColor *shadowColor;

@property (strong, nonatomic) UIFont *titleFont;
@property (strong, nonatomic) UIColor *titleColor;

@property (strong, nonatomic) UIFont *subTitleFont;
@property (strong, nonatomic) UIColor *subTitleColor;

@property (assign, nonatomic) GQBannerStyle bannerStyle;
@property (assign, nonatomic) GQBannerPosition bannerPosition;
@property (assign, nonatomic) GQQueuePosition queuePosition;

@property (assign, nonatomic) NSTimeInterval duration;
@property (assign, nonatomic) NSTimeInterval dismissDuration;
@property (assign, nonatomic) BOOL autoDismiss;
@property (assign, nonatomic) BOOL dismissOnTap;
@property (assign, nonatomic) BOOL dismissOnSwipeUp;

@property (copy, nonatomic) OnTapBlock onTapBlock;
@property (copy, nonatomic) OnSwipTapBlock onSwipTapBlock;




@end

NS_ASSUME_NONNULL_END
