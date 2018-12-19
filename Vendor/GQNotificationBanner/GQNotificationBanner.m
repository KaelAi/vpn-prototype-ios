//
//  GQNotificationBanner.m
//  GQNotificationBanner
//
//  Created by Bright on 2018/11/5.
//  Copyright © 2018 Bright. All rights reserved.
//

#import "GQNotificationBanner.h"
#import <Masonry/Masonry.h>

@interface GQNotificationBanner ()

@property (strong, nonatomic) UIView *leftView;
@property (strong, nonatomic) UIView *rightView;

@end

@implementation GQNotificationBanner

- (instancetype)initWithTitle:(NSString *)title config:(nonnull GQBannerConfig *)config {
    if (self = [super initWithConfig:config]) {
        if (config.leftView) {
            [self.contentView addSubview:config.leftView];
            [config.leftView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(self.contentView).offset(10);
                make.leading.mas_equalTo(self.contentView).offset(10);
                make.bottom.mas_equalTo(self.contentView).offset(-10);
                make.width.mas_equalTo(config.leftView.mas_height);
            }];
        }
        
        if (config.rightView) {
            [self.contentView addSubview:config.rightView];
            [config.rightView mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(self.contentView).offset(10);
                make.trailing.mas_equalTo(self.contentView).offset(-10);
                make.bottom.mas_equalTo(self.contentView).offset(-10);
                make.width.mas_equalTo(config.rightView.mas_height);
            }];
        }
        
        UIView *labelsView = [UIView new];
        [self.contentView addSubview:labelsView];
        
        self.titleLabel = [UILabel new];
//        self.titleLabel.marqueeType = MLLeft;
        self.titleLabel.font = config.titleFont;
        self.titleLabel.textColor = config.titleColor;
        self.titleLabel.text = title;
        [labelsView addSubview:self.titleLabel];
        
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.mas_equalTo(labelsView);
            make.leading.mas_equalTo(labelsView);
            make.trailing.mas_equalTo(labelsView);
            if (config.subTitle) {
                self.titleLabel.numberOfLines = 1;
            } else {
                self.titleLabel.numberOfLines = 0;
//                make.bottom.mas_equalTo(labelsView);
            }
            [self.titleLabel sizeToFit];
            make.height.mas_lessThanOrEqualTo(self.contentView.mas_height);
        }];
        
        if ([config.subTitle length] > 0) {
            self.subTitleLabel = [UILabel new];
//            self.subTitleLabel.marqueeType = MLLeft;
            self.subTitleLabel.font = config.subTitleFont;
            self.subTitleLabel.textColor = config.subTitleColor;
            self.subTitleLabel.text = config.subTitle;
            self.subTitleLabel.numberOfLines = 1;
            [labelsView addSubview:self.subTitleLabel];
            
            [self.subTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
                make.top.mas_equalTo(self.titleLabel.mas_bottom).offset(2.5);
                make.leading.mas_equalTo(labelsView);
                make.trailing.mas_equalTo(labelsView);
            }];
        }
        
        [labelsView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.mas_equalTo(self.contentView);
            
            if (config.leftView) {
                make.leading.mas_equalTo(config.leftView.mas_trailing).offset(10);
            } else {
                make.leading.mas_equalTo(self.contentView.mas_leading).offset(10);
            }
            
            if (config.rightView) {
                make.trailing.mas_equalTo(config.rightView.mas_leading).offset(-10);
            } else {
                make.trailing.mas_equalTo(self.contentView.mas_trailing).offset(-10);
            }
            
            if (self.subTitleLabel) {
                make.bottom.mas_equalTo(self.subTitleLabel.mas_bottom);
            } else {
                make.bottom.mas_equalTo(self.titleLabel.mas_bottom);
            }
            [self updateMarqueeLabelsDurations];
        }];
    }
    return self;
}

//- (instancetype)initWithAttributedTitle:(NSAttributedString *)attributedTitle attributedSubTitle:(NSAttributedString *)attributedSubTitle leftView:(UIView *)leftView rightView:(UIView *)rightView style:(BannerStyle)style color:(GQBannerColor *)color {
//
//}

- (instancetype)initWithCustomView:(UIView *)customView {
    GQBannerConfig *config = [GQBannerConfig bannerConfig];
    if (self = [super initWithConfig:config]) {
        [self.contentView addSubview:customView];
        [customView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self.contentView);
        }];
        
        self.spacerView.backgroundColor = customView.backgroundColor;
    }
    return self;
}

- (void)updateMarqueeLabelsDurations {
    [super updateMarqueeLabelsDurations];
    if (self.subTitleLabel) {
//        self.subTitleLabel.rate = self.config.duration;
    }
}


@end
