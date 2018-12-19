//
//  GQNotificationBannerQueue.m
//  GQNotificationBanner
//
//  Created by Bright on 2018/11/2.
//  Copyright © 2018 Bright. All rights reserved.
//

#import "GQNotificationBannerQueue.h"
#import "GQBaseNotificationBanner.h"

@interface GQNotificationBannerQueue ()

@end

@implementation GQNotificationBannerQueue


+ (instancetype)shareInstance {
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [self new];
    });
    return instance;
}

- (NSUInteger)numberOfBanners {
    return self.banners.count;
}

- (void)addBanner:(GQBaseNotificationBanner *)banner {
    if (banner.config.queuePosition == GQQueuePosition_back) {
        [self.banners addObject:banner];
        if ([self.banners indexOfObject:banner] == 0) {
            banner.config.placeOnQueue = NO;
            [banner show];
        }
    } else {
        banner.config.placeOnQueue = NO;
        [banner show];
        GQBaseNotificationBanner *firstBanner = [self.banners firstObject];
        if (firstBanner) {
            [firstBanner suspend];
        }
        [self.banners insertObject:banner atIndex:0];
    }
}

- (void)removeBanner:(GQBaseNotificationBanner *)banner {
    [self.banners removeObject:banner];
}

- (void)removeAll {
    [self.banners removeAllObjects];
}

- (void)showNext:(ShowBlock)showBlock {
    if (self.banners.count > 0) {
        [self.banners removeObjectAtIndex:0];
    }
    GQBaseNotificationBanner *banner = [self.banners firstObject];
    if (!banner) {
        if (showBlock) {
            showBlock(YES);
            return;
        }
    }
    
    if ([banner isSuspended]) {
        [banner resume];
    } else {
        [banner show];
    }
}

- (NSMutableArray<GQBaseNotificationBanner *> *)banners {
    if (!_banners) {
        _banners = [NSMutableArray array];
    }
    return _banners;
}

@end
