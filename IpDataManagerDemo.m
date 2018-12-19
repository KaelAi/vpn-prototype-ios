//
//  IpDataManager.m
//  Pods
//
//  Created by dev on 2017/10/17.
//
//

#import "IpDataManagerDemo.h"
#import "PingUtil.h"
#import "PingConfigUtil.h"
#import "SDKLog.h"
 #include <pthread.h>
#import "VPNSec.h"
#import "VPNIPMgr.h"

#define ips_key @"ips"
#define lastupdatetime_key @"lastupdatetime"
//#define ipindex_key @"ipindex"

static NSString * const kPlistNameOfIPListFailureTimes = @"kIPListFailureTimes.plist";

@interface IpDataManagerDemo(){
    NSDictionary * _ipListDic;
    CGFloat _ipCacheTime;
}

@property (nonatomic, strong) NSString *clientIP;


@property (nonatomic, strong)NSMutableArray *indexArray;

@end

static NSRecursiveLock *recursiveLock = nil;
@implementation IpDataManagerDemo
@dynamic ipListDic;
@dynamic ipCacheTime;

+ (IpDataManager *)sharedInstance
{
    static IpDataManagerDemo* g_util = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        g_util = [[IpDataManagerDemo alloc] init];
    });
    
    return g_util;
}


- (instancetype)init
{
    self = [super init];
    if (self) {
        
        recursiveLock = [NSRecursiveLock new];
        [self registerToNotificationForSharedExtension];
    }
    return self;
}

- (void)setCurrentCountry:(NSString *)currentCountry{
    _currentCountry = currentCountry;
    if ([currentCountry isEqualToString:@"IR"]) {
        self.downgradeCachedIP = YES;
    }
}

- (void)setIpCacheTime:(CGFloat)ipCacheTime{
    LogI(@"dev: get cached time: %.1f",ipCacheTime);
    _ipCacheTime = ipCacheTime;
    [[NSUserDefaults standardUserDefaults] setFloat:ipCacheTime forKey:@"ipCacheTime"];
    [[NSUserDefaults standardUserDefaults]  synchronize ];
}

- (CGFloat)ipCacheTime{
    if (!_ipCacheTime) {
        if ([[NSUserDefaults standardUserDefaults] floatForKey:@"ipCacheTime"]) {
            _ipCacheTime = [[NSUserDefaults standardUserDefaults] floatForKey:@"ipCacheTime"];

        }else{
            _ipCacheTime = 1;
        }
    }
    LogI(@"dev: use cached time: %.1f",_ipCacheTime);
    return _ipCacheTime;
}





- (NSString *)keyOfWifiAndOption:(VPNOptions *)option{
    NSString *ssid = [SDKUtil wifiSSIDName];
//    if (![ssid isEqualToString:@"unknown"]) {
//        ssid = @"wifiknown";
//    }
    NSString *mode = @"123";
    LogI(@"%@",option.isBasic?@"basic":@"premium");
    NSString *country = option.dstCountry.zoneISOCode;
    return [NSString stringWithFormat:@"%@-%@-%@",country,mode,ssid];
}

- (NSString *)keyTailOfPreList:(VPNOptions *)option{
    NSString *key_tail = option.dstCountry.zoneISOCode;
    if (option.isBasic) {
        key_tail = [NSString stringWithFormat:@"%@-basic",key_tail];
    }
    return key_tail;
}

#pragma mark - receive network extension notification

- (void)registerToNotificationForSharedExtension
{
    [ self unregisterToNotification ];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)(self), didReceivedIpChangedNotification, CFSTR(NOTIFICATION_TO_CHANGE_IP), NULL, CFNotificationSuspensionBehaviorDrop);
    
}


- (void)unregisterToNotification{
    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge const void *)( self ), CFSTR( NOTIFICATION_TO_CHANGE_IP ), NULL );
}

static void didReceivedIpChangedNotification(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    
    //    [(__bridge MainVPNViewController *)observer checkSpeedChangedMark];
    NSUserDefaults *sharedDefault = [[NSUserDefaults alloc]initWithSuiteName:sharedAppGroupId];
    NSDictionary *dic =  [sharedDefault objectForKey:@"ipchanged"];
    NSString *host = dic[@"host"];
    NSInteger changeCode = [dic[@"errorCode"] integerValue];
//    LogI(@"dev: Receive ipchanged notification errorcode :%d",changeCode);
    switch (changeCode) {
        case -60:
            [VPNIPMgr shared].videoVPNIP = nil;

             [(__bridge IpDataManager*)observer removeIpFromCache:host];
            break;
        case -59:
            [VPNIPMgr shared].videoVPNIP = nil;
             [(__bridge IpDataManager*)observer removeIpFromCache:host];
            [(__bridge IpDataManager*)observer removeIpFromPreipDic:host];

            break;
        default:
            break;
    }
}


#pragma mark - ipList operation


- (NSArray<VPNIP *>*)getAllPreIpList{
    VPNOptions *tmpOption  = [VPNOptions new];
    NSString *keyForPreList = [self keyTailOfPreList:tmpOption];
    NSDictionary *preSingleDic = [self fetchPreipDic][keyForPreList];
    NSMutableArray <VPNIP *>*ipListOfPre = [self getIPListWithDictionary:preSingleDic];
    return ipListOfPre;
}

- (NSMutableArray <VPNIP *>*)shuffleHeaderOfArray:(NSMutableArray <VPNIP *>*)ipListOfPre{
    
    NSMutableArray <VPNIP *> *backIpListOfPre = [ipListOfPre mutableCopy];
    //对应subzoneid的ip的索引的数组
    __block NSMutableDictionary *indexOfSubzoneArrayDic = [NSMutableDictionary new];
    
    [ipListOfPre enumerateObjectsUsingBlock:^(VPNIP * _Nonnull aip, NSUInteger idx, BOOL * _Nonnull stop) {
        NSMutableArray *currentIndexArray = indexOfSubzoneArrayDic[@(aip.subZoneId)];
        if (!currentIndexArray) {
            currentIndexArray = [NSMutableArray array];
        }
        [currentIndexArray addObject:@(idx)];
        indexOfSubzoneArrayDic[@(aip.subZoneId)] = currentIndexArray;
    }];
    
    NSArray *keys = indexOfSubzoneArrayDic.allKeys;
    NSInteger flag = 0;
    for (NSNumber *key in keys) {
        NSArray *indexArray = indexOfSubzoneArrayDic[key];
        if (indexArray.count) {
            NSInteger indexToReplace = [indexArray[arc4random()%indexArray.count] integerValue];
            [backIpListOfPre exchangeObjectAtIndex:flag withObjectAtIndex:indexToReplace];
            flag++;
        }
        
    }
    
    if (keys.count) {
        [backIpListOfPre exchangeObjectAtIndex:0 withObjectAtIndex:arc4random()%keys.count];

    }

    
    return  backIpListOfPre;
}

- (void)getIPForOption:(VPNOptions *)option connectBlock:(void(^)(VPNIP *ip))blk{
    
    
    if (self.waitingforip) {
        [[SDKExt sharedInstance] sendEvent:@"waitingIP"
                                withAction:@"startConnect"
                                 withLabel:nil
                                 withValue:nil];
        LogI(@"Waiting to get ip");
        [self requestNewIPListOfOption:option completeHandler:^(HttpRespData *data) {
            if (data.error) {
                [[SDKExt sharedInstance] sendEvent:@"waitingIP"
                                        withAction:@"getIpFailed"
                                         withLabel:nil
                                         withValue:nil];
            }
            
            if ([self isDataRight:data]) {
                LogI(@"Get ip success");
                
                
                NSMutableArray <VPNIP *>*ipList = [self getIPListWithDictionary:data.json];
                if(ipList.count){
                    [[SDKExt sharedInstance] sendEvent:@"waitingIP"
                                            withAction:@"getIpSuccess"
                                             withLabel:ipList[0].ip
                                             withValue:nil];
                    blk(ipList[0]);
                }else{
                    blk(nil);
                }
                
                
            }else{
                [[SDKExt sharedInstance] sendEvent:@"waitingIP"
                                        withAction:@"getIpFailed"
                                         withLabel:nil
                                         withValue:nil];
                blk(nil);
            }
        }];
        return;
    }
    NSString *key = [self keyOfWifiAndOption:option];
    NSDictionary *singleIPListDic = self.ipListDic[key];
    if (!singleIPListDic) {
        LogI(@"read pre iplist");
        [[SDKExt sharedInstance] sendEvent:ConnectCategory
                                withAction:@"usePreIp"
                                 withLabel:@""
                                 withValue:nil];
        
        NSString *keyForPreList = [self keyTailOfPreList:option];
        NSDictionary *preSingleDic = [self fetchPreipDic][keyForPreList];
        NSMutableArray <VPNIP *>*ipListOfPre = [self getIPListWithDictionary:preSingleDic];
        if ([option.srcCountry.zoneISOCode isEqualToString:@"CN"]) {
            ipListOfPre = [[[ipListOfPre reverseObjectEnumerator] allObjects] mutableCopy];
        }else{
//            NSInteger randomNum = arc4random()%ipListOfPre.count;
//            [ipListOfPre exchangeObjectAtIndex:0 withObjectAtIndex:randomNum];
             ipListOfPre = [self shuffleHeaderOfArray:ipListOfPre];
        }
        

        
        
        
        __weak typeof(self) weakself = self;
        if (ipListOfPre.count) {
    #ifndef __CLIENT_DISTRIBUTION_BUILD__
            blk(ipListOfPre[0]);
    #else
            [self pingIpList:ipListOfPre option:option completeBlock:^(VPNIP *bestip, NSArray <NSString *>*sortedIPList) {
                [weakself updateIPListDicWithIPList:ipListOfPre key:key sortedIndex:sortedIPList topVPNIP:nil];
                blk(bestip);
            }];
    #endif
        }else{
            blk(nil);
        }
        
    }else{
        
        NSTimeInterval lastUpdateTimeIntervalSince1970 = [singleIPListDic[lastupdatetime_key] doubleValue];
        NSArray <VPNIP *> *ips = singleIPListDic[ips_key];
        
        if ([self isDateExpuired:lastUpdateTimeIntervalSince1970]) {
            [self requestNewIPListOfOption:option];
        }else{
            if ([self isAllIPFailed:ips]) {
                 [self requestNewIPListOfOption:option];
            }
        }
        if (ips.count) {
             blk(ips[0]);
        }else{
             blk(nil);
        }
       
    }

}

- (BOOL)isAllIPFailed:(NSArray <VPNIP *>*)iplist{
    __block BOOL hasAllIPFailed = YES;
    
    [iplist enumerateObjectsUsingBlock:^(VPNIP * ip, NSUInteger idx, BOOL * _Nonnull stop) {
        if (!ip.failTimes) {
            hasAllIPFailed = NO;
            *stop = NO;
        }
    }];
    if (hasAllIPFailed) {
        LogI(@"All ip failed");
    }
    
    return hasAllIPFailed;
    
}

- (BOOL)isDateExpuired:(NSTimeInterval )lastUpdtaeTimeInterval{
    NSTimeInterval nowTimeInterval = [[NSDate date]timeIntervalSince1970];
    if ((nowTimeInterval - lastUpdtaeTimeInterval) > self.ipCacheTime*24*60*60) {
        LogI(@"iplist expired");
        return YES;
        
    }else{
        return NO;
    }
}

- (NSDictionary *)ipListDic{
    [recursiveLock lock];
    if (!_ipListDic) {
        LogI(@"try to read iplist from UserDefaults");
        _ipListDic = [self readFromLocal] ;
        LogI(@"iplistlocal:%@",_ipListDic);
    }
    [recursiveLock unlock];
    return _ipListDic;
    
    
}

- (void)setIpListDic:(NSMutableDictionary *)ipListDic{
    [recursiveLock lock];
    
    LogI(@"try to save iplist to UserDefaults");

//    LogI(@"iplist old %@",_ipListDic);
//    LogI(@"iplist new %@",ipListDic);
    #if TARGET_OS_MAC && !TARGET_OS_IPHONE
    [self saveToFileOfFailureTimesInIPList:_ipListDic];
    #endif

    _ipListDic = ipListDic;
    
    [self saveDicToLocal];
    [recursiveLock unlock];
   
}

//删除过期的失败IP；如果失败列表时间很久了，删除之，以key为操作范围
- (void)deleteFailureIpListInFileOfDateExpired {
    
    NSString *path = [self filePathOfFailureIpList];
    
    //取出之前的失败列表，新增整个ip记录或者增加失败次数
    NSDictionary *originDic = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSMutableDictionary *ipListDic = [self changeDicToEntityDic:originDic];
    
    __block NSMutableArray *deleteKeys = [NSMutableArray array];
    
    [ipListDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *keyDic, BOOL *stop) {
        NSTimeInterval lastUpdateTimeIntervalSince1970 = [keyDic[lastupdatetime_key] doubleValue];
        
        if ([self isDateExpuired:lastUpdateTimeIntervalSince1970]) {
            [deleteKeys addObject:key];
        }
    }];
    
    if (deleteKeys.count == 0) {
        return;
    }
    
    NSMutableDictionary *ipListDicNew = [ipListDic mutableCopy];
    [ipListDicNew removeObjectsForKeys:deleteKeys];
    
    [self writeToFileOfFailureIpList:ipListDicNew];
}

- (VPNIP *)findVpnIPInList:(NSDictionary *)ipListDic byKey:(NSString *)key byIP:(NSString *)ipString {
    NSDictionary *keyDic = ipListDic[key];
    NSArray <VPNIP*> *ipArray = keyDic[ips_key];
    
    for (VPNIP *ip in ipArray) {
        if ([ip.ip isEqualToString:ipString]) {
            return ip;
        }
    }
    
    return nil;
}

//本地文件路径
- (NSString *)filePathOfFailureIpList {
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"cache/preferences"]];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = YES;
    BOOL isExist = [fileManager fileExistsAtPath:path isDirectory:&isDir];
    if (!isExist) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES
                                attributes:nil error:NULL];
    }
    
    path = [path stringByAppendingPathComponent:kPlistNameOfIPListFailureTimes];
    
    return path;
}

//将指定IPList中的失败IP添加到本地失败文件中，本地失败文件中的IP暂无淘汰机制
- (void)saveToFileOfFailureTimesInIPList:(NSDictionary *)ipListDic {
    
    NSMutableDictionary *failureIPListDicNew = [ipListDic mutableCopy];
    
    NSMutableArray *delKeyArray = [NSMutableArray array];
    
    //找出有失败记录的IP
    //这里可以同时找出成功记录的IP，将其从本地失败文件中删除，因为理论上不存在这种情况（服务端不会下发），暂不做
    [failureIPListDicNew enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *keyDic, BOOL *stop) {
        
        NSMutableDictionary *keyDicM = [keyDic mutableCopy];
        NSMutableArray <VPNIP*> *ipArray = [keyDic[ips_key] mutableCopy];
        
        NSMutableIndexSet *delIndexSet = [NSMutableIndexSet indexSet];
        
        [ipArray enumerateObjectsUsingBlock:^(VPNIP * aip, NSUInteger idx, BOOL * _Nonnull stop) {
            if (aip.failTimes <= 0) {
                [delIndexSet addIndex:idx];
            }
        }];
        
        //删除没有失败次数的IP
        if (delIndexSet.count > 0) {
            [ipArray removeObjectsAtIndexes:delIndexSet];
            keyDicM[ips_key] = ipArray;
            failureIPListDicNew[key] = keyDicM;
        }
        
        //如果全删除了，那直接删key
        if (ipArray.count == 0) {
            [delKeyArray addObject:key];
        }
        
    }];
    
    if (delKeyArray.count > 0) {
        [failureIPListDicNew removeObjectsForKeys:delKeyArray];
    }
    
    //没有新增失败IP
    if (failureIPListDicNew == nil || failureIPListDicNew.count == 0) {
        return;
    }
    
    LogI(@"failure IP List in Memory: %@",failureIPListDicNew);
    
    //删除失败IP文件中过期的key
    [self deleteFailureIpListInFileOfDateExpired];
    
    NSString *path = [self filePathOfFailureIpList];
    
    //取出之前的失败列表，新增整个ip记录或者增加失败次数
    NSDictionary *originDicOld = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSMutableDictionary *failureIPListDicOld = [self changeDicToEntityDic:originDicOld];
    
    __block BOOL hasNewFailureIP = YES;

    //旧列表没有数据，直接用新失败列表覆盖
    if (failureIPListDicOld == nil || failureIPListDicOld.count == 0) {
        failureIPListDicOld = failureIPListDicNew;
    } else {
        //遍历新的失败列表，旧列表中已经存在IP记录就更新失败次数，不存在就添加IP记录
        [failureIPListDicNew enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *keyDic, BOOL *stop) {
            NSMutableArray <VPNIP*> *ipArray = [keyDic[ips_key] mutableCopy];
            
            [ipArray enumerateObjectsUsingBlock:^(VPNIP * aip, NSUInteger idx, BOOL * _Nonnull stop) {
                //如果旧列表中存在，补充失败信息，不存在就添加记录
                VPNIP *IP = [self findVpnIPInList:failureIPListDicOld byKey:key byIP:aip.ip];
                
                NSMutableDictionary *keyDicNew = [failureIPListDicOld[key] mutableCopy]?:[NSMutableDictionary dictionary];
                NSMutableArray <VPNIP*> *ipArrayNew = [keyDicNew[ips_key] mutableCopy]?:[NSMutableArray array];
                
                if (IP != nil) {
                    LogI(@"failure IP is exist: %@",IP);
                    hasNewFailureIP = NO;//已经存在，不做操作
//                    if (IP.failTimes == aip.failTimes) {
//                        LogI(@"failure IP is exist: %@",IP);
//                        hasNewFailureIP = NO;
//                    } else {
//                        LogI(@"failure IP is exist, but failTimes change: %@",IP);
//                        IP.failTimes = MAX(IP.failTimes, aip.failTimes);
//                    }
                } else {
                    LogI(@"new failure IP: %@",aip);
                    [ipArrayNew addObject:aip];
                }
                keyDicNew[ips_key] = [ipArrayNew copy];
                failureIPListDicOld[key] = [keyDicNew copy];
            }];
            
        }];
    }
    
    if (hasNewFailureIP) {
        [self writeToFileOfFailureIpList:failureIPListDicOld];
    }
}

- (BOOL)writeToFileOfFailureIpList:(NSDictionary *)ipListDic {
    NSString *path = [self filePathOfFailureIpList];

    if (ipListDic == nil || ipListDic.count == 0) {
        return [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
    }
    
    NSDictionary *dic  = [self changeIpListEntityDicToDic:ipListDic];
    LogI(@"failure IP List should write to file: %@",path);
    
    LogI(@"failure IP List: %@",dic);
    return [dic writeToFile:path atomically:YES];
}

- (void)removeIpFromCache:(NSString *)ipToRemove{

    NSMutableDictionary *cityDic = self.ipListDic;
//    LogI(@"dev: Receive ipchanged notification before :%@",cityDic);

    __block NSMutableDictionary *cityDicBak =  [[NSMutableDictionary alloc]initWithDictionary:cityDic copyItems:YES];
    __block BOOL dicHasChanged = NO;
    [cityDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *countryIpDic, BOOL * _Nonnull stop) {
        NSMutableArray <VPNIP*>*ips = [countryIpDic[@"ips"] mutableCopy];
        BOOL ipHasChanged = NO;
        for(VPNIP *singleIp in countryIpDic[@"ips"]){
            if ([singleIp.ip isEqualToString:ipToRemove]) {
                [ips removeObject:singleIp];
                ipHasChanged = YES;
            }
        }
        
        if (ipHasChanged) {
            dicHasChanged = YES;
            if (ips.count) {
                cityDicBak[key]  = @{@"ips":ips};
            }else{
                [cityDicBak removeObjectForKey:key];
            }
            
        }
    }];
//    LogI(@"dev: Receive ipchanged notification after :%@",cityDicBak);

    if (dicHasChanged) {
        self.ipListDic = cityDicBak;
//        [cityDicBak writeToFile:[self documentPath] atomically:YES];
    }
}

- (void)updateIPListDicWithIPList:(NSArray <VPNIP*>*)iplist key:(NSString *)key sortedIndex:(NSArray<NSString *>*)sortedIPList topVPNIP:(VPNIP*)topIP{
    
    
    NSTimeInterval nowTimeInterval = [[NSDate date]timeIntervalSince1970];
    NSMutableDictionary *finalDic = [NSMutableDictionary new];
    [finalDic setObject:@(nowTimeInterval) forKey:lastupdatetime_key];
    
    __block NSMutableArray *bakIPList = [[NSMutableArray alloc] initWithArray:iplist copyItems:YES];
    [iplist enumerateObjectsUsingBlock:^(VPNIP * aip, NSUInteger idx, BOOL * _Nonnull stop) {
        NSInteger index = [sortedIPList indexOfObject:aip.ip];
        if (index !=NSNotFound && index>=0 && index<bakIPList.count) {
            [bakIPList replaceObjectAtIndex:index withObject:aip];
        }
    }];
    
    if (topIP) {
        NSInteger index = [sortedIPList indexOfObject:topIP.ip];
        if (index !=NSNotFound && index>=0 && index<bakIPList.count) {
            VPNIP *newIP = bakIPList[index];
            [newIP update:topIP.contentDic ];
            topIP = [newIP copy];
            [bakIPList removeObjectAtIndex:index];
        }
        if(self.downgradeCachedIP){
            if(bakIPList.count){
                [bakIPList insertObject:topIP atIndex:1];
            }else{
                 [bakIPList insertObject:topIP atIndex:0];
            }
        }else{
            [bakIPList insertObject:topIP atIndex:0];
        }
        
    }
    
    
    [finalDic setObject:bakIPList forKey:ips_key];
    NSMutableDictionary *bakIpListDic = [[NSMutableDictionary alloc]initWithDictionary:self.ipListDic copyItems:YES];
    if (!(bakIpListDic.allKeys.count)) {
        bakIpListDic = [NSMutableDictionary new];
    }
    if (bakIPList.count) {
        [bakIpListDic setValue:finalDic forKey:key];
        LogI(@"key:%@,value:%@",key,finalDic);
        self.ipListDic = bakIpListDic;
    }
    
    
}


#pragma mark - single ip operation

- (void)markSuccessOfIP:(VPNIP *)successIP option:(VPNOptions *)option{
    if (!successIP) {
        return;
    }
    if(option.vpnType != VPNType_VPN){
        return;
    }
    
    if (self.waitingforip) {
        [[SDKExt sharedInstance] sendEvent:@"waitingIP"
                                withAction:@"connectSuccess"
                                 withLabel:nil
                                 withValue:nil];
    }
    //操作的是副本
    NSMutableDictionary *bakDic =  [[NSMutableDictionary alloc]initWithDictionary:self.ipListDic copyItems:YES];
    NSString *key = [self keyOfWifiAndOption:option];
    NSMutableDictionary *singleIPListDic = [[NSMutableDictionary alloc]initWithDictionary:bakDic[key] copyItems:YES];
    if (singleIPListDic && singleIPListDic.allKeys.count) {
        __block NSInteger index = -1;
        NSMutableArray <VPNIP*> *ipArray = [singleIPListDic[ips_key] mutableCopy];
        [ipArray enumerateObjectsUsingBlock:^(VPNIP * aip, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([aip.ip isEqualToString:successIP.ip]) {
                index = idx;
                *stop = YES;
            }
        }];
        if (index != -1) {
            [ipArray removeObjectAtIndex:index];

        }
        successIP.failTimes = 0;
        successIP.successTimes ++;
        if (successIP.successTimes <=5) {
            [ipArray insertObject:successIP atIndex:0];
        }else{
            successIP.successTimes = 0;
            if (ipArray.count) {
                [ipArray insertObject:successIP atIndex:1];
            }else{
                [ipArray insertObject:successIP atIndex:0];
            }
        }
        singleIPListDic[ips_key] = ipArray;
        bakDic[key] = singleIPListDic;
        LogI(@"key:%@,value:%@",key,singleIPListDic);
        self.ipListDic = bakDic;
    }
}

- (void)markFailureOfIP:(VPNIP *)failureIP option:(VPNOptions *)option{
    if (!failureIP) {
        return;
    }
    if(option.vpnType != VPNType_VPN){
        return;
    }
    
    if (self.waitingforip) {
        [[SDKExt sharedInstance] sendEvent:@"waitingIP"
                                withAction:@"connectFailed"
                                 withLabel:nil
                                 withValue:nil];
    }
    
    //操作的是副本
    NSMutableDictionary *bakDic = [[NSMutableDictionary alloc]initWithDictionary:self.ipListDic copyItems:YES];
    NSString *key = [self keyOfWifiAndOption:option];
    NSMutableDictionary *singleIPListDic = [[NSMutableDictionary alloc]initWithDictionary:bakDic[key] copyItems:YES];
    if (singleIPListDic && singleIPListDic.allKeys.count) {
        NSMutableArray <VPNIP*> *ipArray = [singleIPListDic[ips_key] mutableCopy];
        
        __block NSInteger index = -1;
        [ipArray enumerateObjectsUsingBlock:^(VPNIP * aip, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([aip.ip isEqualToString:failureIP.ip]) {
                index = idx;
                *stop = YES;
            }
        }];
        
        
        
        if (index != -1) {
            [ipArray removeObjectAtIndex:index];
            failureIP.failTimes ++;
            failureIP.successTimes =0;
            if (ipArray.count) {
                [ipArray insertObject:failureIP atIndex:ipArray.count];
            }else{
                [ipArray insertObject:failureIP atIndex:0];
            }
            singleIPListDic[ips_key] = ipArray;
            bakDic[key] = singleIPListDic;
            LogI(@"key:%@,value:%@",key,singleIPListDic);
            self.ipListDic = bakDic;
        }
       
    }
    
    NSArray <VPNIP *> *ips = singleIPListDic[ips_key];
    if ([self isAllIPFailed:ips]) {
        [[SDKExt sharedInstance] sendEvent:ConnectCategory
                                withAction:@"allIpFailed"
                                 withLabel:@""
                                 withValue:nil];
        LogI(@"All ip has failed, use bakeup ip");
        NSMutableDictionary *tmpDic = [self.ipListDic mutableCopy];
        [tmpDic removeObjectForKey:key];
        self.ipListDic = tmpDic;
        [self getIPForOption:option connectBlock:^(VPNIP *ip) {
            
        }];
    }
}

- (void)markSlowOfIP:(VPNIP *)failureIP option:(VPNOptions *)option{
    if (!failureIP) {
        return;
    }
    if(option.vpnType != VPNType_VPN){
        return;
    }
    //操作的是副本
    NSMutableDictionary *bakDic = [[NSMutableDictionary alloc]initWithDictionary:self.ipListDic copyItems:YES];
    NSString *key = [self keyOfWifiAndOption:option];
    NSMutableDictionary *singleIPListDic = [[NSMutableDictionary alloc]initWithDictionary:bakDic[key] copyItems:YES];
    if (singleIPListDic && singleIPListDic.allKeys.count) {
        NSMutableArray <VPNIP*> *ipArray = [singleIPListDic[ips_key] mutableCopy];
        
        __block NSInteger index = -1;
        [ipArray enumerateObjectsUsingBlock:^(VPNIP * aip, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([aip.ip isEqualToString:failureIP.ip]) {
                index = idx;
                *stop = YES;
            }
        }];
        
        
        
        if (index != -1) {
            [ipArray removeObjectAtIndex:index];

            if (ipArray.count) {
                [ipArray insertObject:failureIP atIndex:1];
            }else{
                [ipArray insertObject:failureIP atIndex:0];
            }
            singleIPListDic[ips_key] = ipArray;
            bakDic[key] = singleIPListDic;
            LogI(@"key:%@,value:%@",key,singleIPListDic);
            self.ipListDic = bakDic;
        }
        
    }
    
    NSArray <VPNIP *> *ips = singleIPListDic[ips_key];
    if ([self isAllIPFailed:ips]) {
        [[SDKExt sharedInstance] sendEvent:ConnectCategory
                                withAction:@"allIpFailed"
                                 withLabel:@""
                                 withValue:nil];
        LogI(@"All ip has failed, use bakeup ip");
        NSMutableDictionary *tmpDic = [self.ipListDic mutableCopy];
        [tmpDic removeObjectForKey:key];
        self.ipListDic = tmpDic;
        [self getIPForOption:option connectBlock:^(VPNIP *ip) {
            
        }];
    }
}



#pragma mark - local file excute


- (void)saveDicToLocal{
    if (!_ipListDic) {
        return;
    }
    NSDictionary *mdic  = [self changeIpListEntityDicToDic:_ipListDic];
    [[NSUserDefaults standardUserDefaults] setObject:mdic forKey:@"ipListDic"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (NSMutableDictionary *)readFromLocal{
    NSDictionary *originDic = [[NSUserDefaults standardUserDefaults]dictionaryForKey:@"ipListDic"];
    NSMutableDictionary *mDic = [self changeDicToEntityDic:originDic];
    return mDic;
}

//将iplist里面的dic转化为entity
- (NSMutableDictionary *)changeDicToEntityDic:(NSDictionary *)dic{
    NSMutableDictionary *tmpDic = [[NSMutableDictionary alloc]initWithDictionary:dic copyItems:YES];

    for (NSString *key in tmpDic.allKeys) {
        NSMutableDictionary *singleIPentity = [[NSMutableDictionary alloc]initWithDictionary:tmpDic[key] copyItems:YES];
        __block NSMutableArray *entityiplist = [NSMutableArray new];
        
        NSArray <NSDictionary *>*ipList = singleIPentity[ips_key];

        if (ipList.count) {
            [ipList enumerateObjectsUsingBlock:^(NSDictionary * dic, NSUInteger idx, BOOL * _Nonnull stop) {
                VPNIP *ip = [VPNIP new];
                [ip update:dic];
                [entityiplist addObject:ip];
            }];
            singleIPentity[ips_key] = entityiplist;
            tmpDic[key] = singleIPentity;
        }

    }
    
    
   
    return tmpDic;
}

//将iplist里面的entity转化为dic
- (NSDictionary *)changeIpListEntityDicToDic:(NSDictionary*)entityDic{
    NSMutableDictionary *tmpDic = [[NSMutableDictionary alloc]initWithDictionary:entityDic copyItems:YES];
    
    for (NSString *key in tmpDic.allKeys) {
        NSMutableDictionary *singleIPDic =  [[NSMutableDictionary alloc]initWithDictionary:tmpDic[key] copyItems:YES];
        NSArray <VPNIP *>*ipList = singleIPDic[ips_key];
        __block NSMutableArray *diciplist = [NSMutableArray new];
        [ipList enumerateObjectsUsingBlock:^(VPNIP * ip, NSUInteger idx, BOOL * _Nonnull stop) {
            [diciplist addObject:[ip entityToDic]];
        }];
        singleIPDic[ips_key] = diciplist;
        tmpDic[key] = singleIPDic;
    }
    return [tmpDic copy];
}

#pragma mark -  pre ip operation
/**
 *不同地区返回不同iplist
 **/
- (NSString *)getPlistName{
#if TARGET_OS_IPHONE
    if ([[[UIDevice currentDevice] systemVersion] intValue] < 10) {
        return @"iplist_bakup";
    }else{
        NSString *countryCode = [[NSLocale currentLocale] countryCode];
        if ([countryCode isEqualToString:@"IR"]) {
            return @"iplist_bakup";
        }
//        else if([countryCode isEqualToString:@"CN"]){
//            return @"iplist_bakup_CN";
//        }
        else{
           return @"iplist_bakup";
        }
    }
#else
    return @"iplist_bakup";
#endif
    
}

- (NSString *)documentPath{
    //需要将预埋ip列表拷贝到document目录下，否则没有写权限
    NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
    NSString *plistPath =[thisBundle pathForResource:[self getPlistName] ofType:@"plist"];
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    NSString *plistPath1 = [paths objectAtIndex:0];
    NSString *newFilePath=[plistPath1 stringByAppendingPathComponent:@"country_ipList.plist"];
    
    NSFileManager* fileMgr = [NSFileManager defaultManager];
    if([fileMgr fileExistsAtPath:newFilePath]){
        return newFilePath;
    }else{
        NSError *err = nil ;
        [fileMgr copyItemAtPath:plistPath toPath:newFilePath error:&err];
        
        if (err) {
            return plistPath;
        }else{
            return newFilePath;
        }
    }
    
}

- (void)replacePreIPList{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *verStr = [userDefault objectForKey:@"lastPreIpListVersion"];
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *build = [infoDictionary objectForKey:@"CFBundleVersion"];//app的build号
    
    if (![build isEqualToString:verStr]) {
        NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
        NSString *plistPath =[thisBundle pathForResource:[self getPlistName] ofType:@"plist"];
        NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
        NSString *plistPath1 = [paths objectAtIndex:0];
        NSString *newFilePath=[plistPath1 stringByAppendingPathComponent:@"country_ipList.plist"];
        NSFileManager* fileMgr = [NSFileManager defaultManager];
        NSError *err = nil ;
        if([fileMgr fileExistsAtPath:newFilePath]){
            [fileMgr removeItemAtPath:newFilePath error:&err];
        }
        [fileMgr copyItemAtPath:plistPath toPath:newFilePath error:&err];
        [userDefault setObject:build forKey:@"lastPreIpListVersion"];
        
    }

}

- (NSMutableDictionary *)fetchPreipDic{
    
    NSString *plistPath =[self documentPath];
    NSMutableDictionary *cityDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    return cityDic;
}

- (void)removeIpFromPreipDic:(NSString *)ipToRemove{
    NSString *plistPath =[self documentPath];
    NSMutableDictionary *cityDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
//    LogI(@"dev: Receive ipchanged notification ippre before :%@",cityDic);
    __block NSMutableDictionary *cityDicBak =  [[NSMutableDictionary alloc]initWithDictionary:cityDic copyItems:YES];
    __block BOOL dicHasChanged = NO;
    [cityDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *countryIpDic, BOOL * _Nonnull stop) {
        NSMutableArray *ips = [countryIpDic[@"ips"] mutableCopy];
       BOOL ipHasChanged = NO;
        for(NSDictionary *singleIpDic in countryIpDic[@"ips"]){
            if ([singleIpDic[@"ip"] isEqualToString:ipToRemove]) {
                [ips removeObject:singleIpDic];
                ipHasChanged = YES;
            }
        }
        
        if (ipHasChanged) {
            dicHasChanged = YES;
            if (ips.count) {
                cityDicBak[key] = @{@"ips":ips};
            }else{
                [cityDicBak removeObjectForKey:key];
            }
        }
    }];
//    LogI(@"dev: Receive ipchanged notification ippre after :%@",cityDicBak);

    if (dicHasChanged) {
        [cityDicBak writeToFile:[self documentPath] atomically:YES];
    }
}


#pragma mark - remoteData to localdata

- (void)requestNewIPListOfOption:(VPNOptions *)option   completeHandler :(void (^)(HttpRespData *))completionHandler{
    __weak typeof(self) weakself = self;
    
    
    
    [[VPNAppNet shared] getSkyVPNIPs:option exludeStr:[self assembleExcludeStrWithOption:option] completeHandler:^(HttpRespData *data) {
        if (completionHandler) {
            completionHandler(data);
        }
    }];
    
}

- (void)requestNewIPListOfOption:(VPNOptions *)option{
    __weak typeof(self) weakself = self;



    [[VPNAppNet shared] getSkyVPNIPs:option exludeStr:[self assembleExcludeStrWithOption:option] completeHandler:^(HttpRespData *data) {
        [weakself dealWithHttpData:data option:option];
    }];

}

- (NSString *)assembleExcludeStrWithOption:(VPNOptions *)option{
    NSString *key = [self keyOfWifiAndOption:option];
    
    //从本地获取
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    path = [path stringByAppendingPathComponent:[NSString stringWithFormat:@"cache/preferences/%@", kPlistNameOfIPListFailureTimes]];
    
    NSDictionary *originDic = [[NSDictionary alloc] initWithContentsOfFile:path];
    NSDictionary *ipListDic = [self changeDicToEntityDic:originDic];
    
    NSDictionary *singleIPListDic = ipListDic[key];
    
    if (singleIPListDic == nil) {
        return nil;
    }
    
    NSArray <VPNIP *> *iparray = singleIPListDic[ips_key];
    __block NSString *excludeStr = nil;
    [iparray enumerateObjectsUsingBlock:^(VPNIP * aip, NSUInteger idx, BOOL * _Nonnull stop) {
        if (aip.failTimes) {
            if (!excludeStr) {
                excludeStr = aip.ip;
            }else{
                excludeStr = [NSString stringWithFormat:@"%@;%@",excludeStr,aip.ip];
            }
            
        }
    }];
//#ifndef __CLIENT_DISTRIBUTION_BUILD__
//    exludeStr = nil;
//#endif
    
    LogI(@"exclude ip list:%@",excludeStr);
    return excludeStr;
}


- (void)dealWithHttpData:(HttpRespData *)data option:(VPNOptions *)option{
    NSString *key = [self keyOfWifiAndOption:option];
    if ([self isDataRight:data]) {
        LogI(@"Get ip success");
        NSMutableArray <VPNIP *>*ipList = [self getIPListWithDictionary:data.json];
        self.clientIP = data.json[@"clientIp"]?:@"";
        [self pingIpList:ipList option:option completeBlock:^(VPNIP *bestip, NSArray <NSString *>*sortedIPList) {
            [self updateIPListDicWithIPList:ipList key:key sortedIndex:sortedIPList topVPNIP:[self getLastSuccessIP:option]];
        }];
        
    }
}


- (void)pingIpList:(NSArray <VPNIP *>*)ipList
            option:(VPNOptions *)option
     completeBlock:(void(^)(VPNIP *bestip,NSArray*sortedIPList))blk{
    
    BOOL shouldUsePing = [[NSUserDefaults standardUserDefaults] boolForKey:@"shouldUsePing"];
    if (!shouldUsePing) {
        LogI(@"dev: not use ping");
        if (ipList.count) {
            __block NSMutableArray *fakeArray = [NSMutableArray new];
            [ipList enumerateObjectsUsingBlock:^(VPNIP * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [fakeArray addObject:obj.ip];
            }];
            if (blk) {
                blk(ipList[0],fakeArray);
            }
        }
        return;
       
    }
     LogI(@"dev:  use ping");
    NSTimeInterval start = [[NSDate date] timeIntervalSince1970];
    //同时做ping和连接会影响ping的结果，需要串行执行
    [[PingUtil sharedInstance] ping:ipList onPingResult:^(NSString *bestIP, OCPingDetail *pingDetail, NSArray *ipArray) {
        //当第一次Ping返回之后，再执行后续连接vpn的操作。
        
        __block VPNIP *tmpIP = nil;
        [ipList enumerateObjectsUsingBlock:^(VPNIP *aIP, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([aIP.ip isEqualToString:bestIP]) {
                tmpIP = aIP;
            }
        }];
        
        tmpIP.pingdetail = pingDetail;
        tmpIP.pingTime = [[NSDate date] timeIntervalSince1970] - start;
        tmpIP.clientIP = self.clientIP;
        if (blk) {
            blk(tmpIP,ipArray);
        }
        
        
        
    }];
}

- (BOOL)isDataRight:(HttpRespData *)data{
    if (data && data.json && !data.hasError) {
        return YES;
    }else{
        return NO;
    }
}

//将ip的json解析成ip列表
- (NSMutableArray <VPNIP *>*)getIPListWithDictionary:(NSDictionary *)json
{
    __block NSMutableArray *ipList = [NSMutableArray array];
    if (json && json.count > 0) {
        NSArray *ips = [NSArray arrayWithArray: json[@"ips"] ];
        if (ips && [ips isKindOfClass:[NSArray class]]) {
            [ips enumerateObjectsUsingBlock:^(NSDictionary *dic, NSUInteger idx, BOOL * _Nonnull stop) {
                VPNIP *singleIP = [VPNIP new];
                [singleIP update:dic];
                [ipList addObject:singleIP];

            }];
            
        }
    }
    

    return ipList;
}

- (VPNIP *)getLastSuccessIP:(VPNOptions*)option{
    NSString *key = [self keyOfWifiAndOption:option];
    NSDictionary *singleIPListDic = self.ipListDic[key];
    if (singleIPListDic) {
        NSArray <VPNIP *> *ips = singleIPListDic[ips_key];
        if (ips.count) {
            for (VPNIP *ip in ips){
                if (ip.successTimes) {
                    return ip;
                }
            }
            return nil;
           
            
        }else{
            return nil;
        }
     
    }else{
        return nil;
    }

}



- (void)compessIpArray{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *newFilePath = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:sharedAppGroupId] URLByAppendingPathComponent:@"testArrayFile.plist"].path;
//    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
//    NSString *plistPath1 = [paths objectAtIndex:0];
//    NSString *newFilePath=[plistPath1 stringByAppendingPathComponent:@"testArrayFile.plist"];
    [fileManager removeItemAtPath:newFilePath error:nil];
    
    
    
    
    NSString *plistPath =[self documentPath];
    __block NSMutableArray *fileArray = [NSMutableArray new];
    NSArray *portArray  = @[@"sslPort",@"tlsPort",@"icmpPort",@"tcpPort",@"udpPort",@"httpPort",@"httpsPort",@"dnsPort",@"tdnsPort"];
    
    NSMutableDictionary *cityDic = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    [cityDic enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSDictionary *countryIpDic, BOOL * _Nonnull stop) {
        for(NSDictionary *singleIpDic in countryIpDic[@"ips"]){
            for (NSString *portKey in portArray) {
                if (singleIpDic[portKey]) {
                    NSArray *ports = [singleIpDic[portKey] componentsSeparatedByString:@";"];
                    for (NSString *port in ports) {
                        NSArray *ipDetailArray = @[singleIpDic[@"ip"],portKey,port];
                               [fileArray addObject:ipDetailArray];
                        
                        //   [fileArray addObject:ipDetailArray];
                        
                    }
                }
            }
        }
        
      
    }];
    
    [fileArray writeToFile:newFilePath atomically:YES];
    
}


@end
