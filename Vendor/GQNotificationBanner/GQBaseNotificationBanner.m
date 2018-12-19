//
//  GQBaseNotificationBanner.m
//  GQNotificationBanner
//
//  Created by Bright on 2018/11/2.
//  Copyright © 2018 Bright. All rights reserved.
//

#import "GQBaseNotificationBanner.h"
#import "GQNotificationBannerUtilities.h"
#import <Masonry/Masonry.h>

@interface GQBaseNotificationBanner ()

@property (assign, nonatomic) CGFloat customBannerHeight;
@property (strong, nonatomic) GQBannerPositionFrame *bannerPositionFrame;
@property (strong, nonatomic) GQNotificationBannerQueue *bannerQueue;
@property (strong, nonatomic) NSDictionary<NSString *,GQBaseNotificationBanner *> *notificationUserInfo;

@property (weak, nonatomic) UIViewController *parentViewController;


@end

@implementation GQBaseNotificationBanner

#pragma mark - life cycle

- (instancetype)initWithConfig:(GQBannerConfig *)config {
    if (self = [super initWithFrame:CGRectZero]) {
        self.config = config;
        self.isDisplaying = NO;
        self.isSuspended = NO;
        self.bannerQueue = [GQNotificationBannerQueue shareInstance];
        self.contentView = [UIView new];
        [self addSubview:self.contentView];
        self.spacerView = [UIView new];
        [self addSubview:self.spacerView];
        
        UISwipeGestureRecognizer *swipeUpGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(onSwipeUpGestureRecognizer)];
        swipeUpGesture.direction = UISwipeGestureRecognizerDirectionUp;
        [self addGestureRecognizer:swipeUpGesture];
        [self updateMarqueeLabelsDurations];
        self.contentView.backgroundColor = config.bannerColor;
        self.spacerView.backgroundColor = [UIColor clearColor];
        
        if (self.config.padding > 0.0) {
            self.layer.cornerRadius = 5;
//            self.clipsToBounds = YES;
            self.contentView.layer.cornerRadius = 5;
//            self.contentView.clipsToBounds = YES;
        }
        
        if (config.shadow) {
            self.contentView.alpha = 0.9;
            self.contentView.layer.shadowColor = config.shadowColor.CGColor;
            self.contentView.layer.shadowOffset = CGSizeMake(0, 5);
            self.contentView.layer.shadowOpacity = 0.3;
            self.contentView.layer.shadowRadius = 5;
        }
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - public
//- (void)showWithQueuePosition:(GQQueuePosition)queuePosition bannerPosition:(GQBannerPosition)bannerPosition queue:(GQNotificationBannerQueue *)queue viewController:(UIViewController *)viewController {
//    self.parentViewController = viewController;
//    self.bannerQueue = queue;
//    [self showWithQueuePosition:queuePosition bannerPosition:bannerPosition placeOnQueue:YES];
//}

- (void)show {
    if (self.isDisplaying) {
        return;
    }
    
    if (!self.bannerPositionFrame) {
        [self createBannerConstraints];
        self.bannerPositionFrame = [[GQBannerPositionFrame alloc] initWithPosition:self.config.bannerPosition bannerWidth:[self appWindow].frame.size.width bannerHeight:[self getBannerHeight] maxY:[self maximumYPosition] padding:self.config.padding];
    }
    
//    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onOrientationChanged) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    if (self.config.placeOnQueue) {
        [self.bannerQueue addBanner:self];
    } else {
        self.frame = self.bannerPositionFrame.startFrame;
        
        if (self.parentViewController) {
            [self.parentViewController.view addSubview:self];
            if ([self statusBarShouldBeShown]) {
                [self appWindow].windowLevel = UIWindowLevelNormal;
            } else {
                [self appWindow].windowLevel = UIWindowLevelStatusBar + 1;
            }
        } else {
            [[self appWindow] addSubview:self];
            if ([self statusBarShouldBeShown] && !(!self.parentViewController && self.config.bannerPosition == GQBannerPosition_top)) {
                [self appWindow].windowLevel = UIWindowLevelNormal;
            } else {
                [self appWindow].windowLevel = UIWindowLevelStatusBar + 1;
            }
            
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kBannerWillAppear object:self userInfo:self.notificationUserInfo];
        if (self.delegate && [self.delegate respondsToSelector:@selector(notificationBannerWillAppear:)]) {
            [self.delegate notificationBannerWillAppear:self];
        }
        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(onTapGestureRecognizer)];
        [self addGestureRecognizer:tapGestureRecognizer];
        
        self.isDisplaying = YES;
        
        [UIView animateWithDuration:0.5 delay:0.0 usingSpringWithDamping:0.7 initialSpringVelocity:1 options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction animations:^{
            self.frame = self.bannerPositionFrame.endFrame;
        } completion:^(BOOL finished) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kBannerDidAppear object:self userInfo:self.notificationUserInfo];
            if (self.delegate && [self.delegate respondsToSelector:@selector(notificationBannerDidAppear:)]) {
                [self.delegate notificationBannerDidAppear:self];
            }
            
            if (!self.isSuspended && self.config.autoDismiss) {
                [self performSelector:@selector(dismiss) withObject:nil afterDelay:self.config.duration];
            }
        }];
    }
}

- (void)dismiss {
    if (!self.isDisplaying) {
        return;
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:kBannerWillDisappear object:self userInfo:self.notificationUserInfo];
    if (self.delegate && [self.delegate respondsToSelector:@selector(notificationBannerWillDisappear:)]) {
        [self.delegate notificationBannerWillDisappear:self];
    }
    
    [UIView animateWithDuration:self.config.dismissDuration animations:^{
        self.frame = self.bannerPositionFrame.startFrame;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
        self.isDisplaying = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:kBannerDidDisappear object:self userInfo:self.notificationUserInfo];
        if (self.delegate && [self.delegate respondsToSelector:@selector(notificationBannerDidDisappear:)]) {
            [self.delegate notificationBannerDidDisappear:self];
        }
        [self.bannerQueue showNext:^(BOOL isEmpty) {
            if (isEmpty || [self statusBarShouldBeShown]) {
                self.appWindow.windowLevel = UIWindowLevelNormal;
            }
        }];
    }];
}

- (void)remove {
    if (self.isDisplaying) {
        return;
    }
    [self.bannerQueue removeBanner:self];
}

- (void)suspend {
    if (self.config.autoDismiss) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(dismiss) object:nil];
        self.isSuspended = YES;
        self.isDisplaying = NO;
    }
}

- (void)resume {
    if (self.config.autoDismiss) {
        [self performSelector:@selector(dismiss) withObject:nil afterDelay:self.config.duration];
        self.isSuspended = NO;
        self.isDisplaying = YES;
    }
}

- (void)setBannerHeight:(CGFloat)bannerHeight {
    self.customBannerHeight = bannerHeight;
}

- (CGFloat)getBannerHeight {
    if (self.customBannerHeight > 0) {
        return self.customBannerHeight;
    } else {
        return [self shouldAdjustForNotchFeaturedIphone] ? 90.0 : 65.0;
    }
}

- (BOOL)shouldAdjustForNotchFeaturedIphone {
    return [GQNotificationBannerUtilities isNotchFeaturedIPhone]
    && [UIApplication sharedApplication].statusBarOrientation == UIDeviceOrientationPortrait;
}

- (void)updateMarqueeLabelsDurations {
//    todo 文字跑马灯
//    self.titleLabel.rate = self.config.duration;
}

#pragma mark - private

- (void)createBannerConstraints {
    [self.spacerView mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (self.config.bannerPosition == GQBannerPosition_top) {
            make.top.mas_equalTo(self).with.offset(-10);
        } else {
            make.bottom.mas_equalTo(self).with.offset(10);
        }
        make.leading.mas_equalTo(self);
        make.trailing.mas_equalTo(self);
        [self updateSpacerViewHeight:make];
    }];
    
    [self.contentView mas_remakeConstraints:^(MASConstraintMaker *make) {
        if (self.config.bannerPosition == GQBannerPosition_top) {
            make.top.mas_equalTo(self.spacerView.mas_bottom);
            make.bottom.mas_equalTo(self);
        } else {
            make.bottom.mas_equalTo(self.spacerView.mas_top);
            make.top.mas_equalTo(self);
        }
        
        make.leading.mas_equalTo(self);
        make.trailing.mas_equalTo(self);
    }];
}

- (void)updateSpacerViewHeight:(MASConstraintMaker *)make {
    BOOL isNavigationBarHidden = YES;
    if (self.parentViewController && self.parentViewController.navigationController) {
        isNavigationBarHidden = self.parentViewController.navigationController.isNavigationBarHidden;
    }
    NSNumber *finalHeight = [NSNumber numberWithFloat:([GQNotificationBannerUtilities isNotchFeaturedIPhone]
        && [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait
        && isNavigationBarHidden) ? 40.0 : 10.0];
    if (make) {
        make.height.equalTo(finalHeight);
    } else {
        [self.spacerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.height.equalTo(finalHeight);
        }];
    }
    
}

- (void)onTapGestureRecognizer {
    if (self.config.dismissOnTap) {
        [self dismiss];
    }
    
    if (self.config.onTapBlock) {
        self.config.onTapBlock();
    }
}

- (void)onSwipeUpGestureRecognizer {
    if (self.config.dismissOnSwipeUp) {
        [self dismiss];
    }
    
    if (self.config.onSwipTapBlock) {
        self.config.onSwipTapBlock();
    }
}

- (BOOL)statusBarShouldBeShown {
    for (GQBaseNotificationBanner *banner in self.bannerQueue.banners) {
        if (!banner.parentViewController && banner.config.bannerPosition == GQBannerPosition_top) {
            return NO;
        }
    }
    return YES;
}

//- (void)onOrientationChanged {
//    [self updateSpacerViewHeight:nil];
//    CGFloat newY = (self.config.bannerPosition == GQBannerPosition_top) ? self.frame.origin.y : ([self appWindow].frame.size.height - [self getBannerHeight]);
//    self.frame = CGRectMake(self.frame.origin.x, newY, [self appWindow].frame.size.width, [self getBannerHeight]);
//    self.bannerPositionFrame = [[GQBannerPositionFrame alloc] initWithPosition:self.config.bannerPosition bannerWidth:[self appWindow].frame.size.width bannerHeight:[self getBannerHeight] maxY:[self maximumYPosition] padding:self.config.padding];
//}

- (CGFloat)maximumYPosition {
    if (self.parentViewController) {
        return self.parentViewController.view.frame.size.height;
    } else {
        return [self appWindow].frame.size.height;
    }
}

#pragma mark - get

- (UIWindow *)appWindow {
    return [UIApplication sharedApplication].delegate.window;
}

- (NSDictionary<NSString *,GQBaseNotificationBanner *> *)notificationUserInfo {
    if (!_notificationUserInfo) {
        //这一句感觉会产生强引用
        _notificationUserInfo = @{kBannerObjectKey:self};
    }
    return _notificationUserInfo;
}

@end
