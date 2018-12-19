//
//  VPNOptions.h
//  VPNSDK
//
//  Created by SK-Pan on 2017/2/16.
//  Copyright © 2017年 bitVPN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SDKEnum.h"
#import "CountryReferenceUtil.h"


#define SAVED_VPNSVR_COUNTRYLIST_KEY            @"dcSavedVPNSvrCountryListKey"
#define SAVED_VPNSVR_SELECTED_COUNTRY_KEY       @"dcSavedVPNSvrSelectedCountryKey"
#define SAVED_VPNSVR_CONN_SUCCESS_COUNTRY_KEY   @"dcSavedVPNSvrConnSuccessCountryKey"

#define SAVED_VPNSVR_SEL_BASIC_COUNTRY_KEY      @"dcSavedVPNSvrSelBasicCountryKey"

@interface VPNOptions : NSObject



@property (nonatomic, strong) VPNServerCountry* srcCountry;
@property (nonatomic, strong) VPNServerCountry* dstCountry;

@property (nonatomic, strong) NSString* ip;

@property (nonatomic, assign) VPNTypes   vpnType;
@property (nonatomic, assign) VPNMode   vpnMode;

- (BOOL)isBasic;

@end
