//
//  VPNOptions.m
//  VPNSDK
//
//  Created by SK-Pan on 2017/2/16.
//  Copyright © 2017年 SkyVPN. All rights reserved.
//

#import "VPNOptions.h"

@implementation VPNOptions


@synthesize ip;

- (BOOL)isBasic{
    return self.vpnMode == VPNModeBasic;
}



- (instancetype)init{
    self = [super init];
    if (self) {
        self.srcCountry = [CountryReferenceUtil sharedInstance].srcCountry;
        self.dstCountry = [CountryReferenceUtil sharedInstance].dstCountry;
        self.vpnMode = [CountryReferenceUtil sharedInstance].vpnMode;
    }
    return self;
}
@end
