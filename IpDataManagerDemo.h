//
//  IpDataManager.h
//  Pods
//
//  Created by dev: ai on 2017/10/17.
//
//

#import <Foundation/Foundation.h>
#import "VPNOptions.h"
#import "VPNAppNet.h"
#import "VPNIP.h"
#import "SDKUtil.h"
#import "VPNIP.h"

@interface IpDataManagerDemo : NSObject

+ (IpDataManagerDemo *)sharedInstance;

@property (nonatomic, strong)NSMutableDictionary *ipListDic;
@property (nonatomic, assign)CGFloat ipCacheTime;
@property (nonatomic, assign)BOOL downgradeCachedIP;
@property (nonatomic, assign)BOOL waitingforip;
@property (nonatomic, copy)NSString *currentCountry;
- (void)getIPForOption:(VPNOptions *)option connectBlock:(void(^)(VPNIP *ip))blk;

- (void)markSuccessOfIP:(VPNIP *)successIP option:(VPNOptions *)option;

- (void)markFailureOfIP:(VPNIP *)failureIP option:(VPNOptions *)option;
    - (void)markSlowOfIP:(VPNIP *)failureIP option:(VPNOptions *)option;

- (void)requestNewIPListOfOption:(VPNOptions *)option;


- (NSArray<VPNIP *>*)getAllPreIpList;

- (void)replacePreIPList;

- (NSString *)getPlistName;

- (void)dealWithHttpData:(HttpRespData *)data option:(VPNOptions *)option;
- (NSString *)assembleExcludeStrWithOption:(VPNOptions *)option;
- (void)compessIpArray;
@end
