//
//  GQNotificationBannerQueue.h
//  GQNotificationBanner
//
//  Created by Bright on 2018/11/2.
//  Copyright © 2018 Bright. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GQBannerConfig.h"

@class GQBaseNotificationBanner;

NS_ASSUME_NONNULL_BEGIN

typedef void (^ShowBlock)(BOOL isEmpty);

@interface GQNotificationBannerQueue : NSObject

@property (strong, nonatomic) NSMutableArray<GQBaseNotificationBanner *> *banners;

+ (nonnull instancetype) shareInstance;

- (NSUInteger)numberOfBanners;

- (void)addBanner:(GQBaseNotificationBanner *)banner;

- (void)removeBanner:(GQBaseNotificationBanner *)banner;

- (void)removeAll;

- (void)showNext:(ShowBlock)showBlock;

@end

NS_ASSUME_NONNULL_END
