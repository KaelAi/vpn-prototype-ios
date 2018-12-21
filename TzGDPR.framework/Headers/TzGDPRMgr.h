//
//  TzGDPRMgr.h
//  TzGDPR
//
//  Created by mac on 2018/5/17.
//  Copyright © 2018年 TengZhan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//用户当前对隐私条款的选择
typedef enum TZEEAConsentStatus{
    TZEEAConsentStatusUnknown = 0, //用户没有选择
    TZEEAConsentStatusGranted = 1, //用户已经选择同意隐私条款
    TZEEAConsentStatusDeclined = 2,//用户已经选择拒绝隐私条款
}TZEEAConsentStatus;

//App集成需要实现此协议
@protocol TzGDPRMgrDelegate
@required
- (NSString*)appNameForTzGDPR;//集成此SDK的app名字，用做SDK界面文字本地化
- (NSString*)policyURLForTzGDPR;//隐私策略URL

@optional
- (BOOL)isRegisterUserForTzGDPR;//返回是否为已经注册的用户。对于Dingtone未注册用户和已经注册用户的提示界面不一样，需要实现此方法，如果不实现默认为YES，当作已经注册用户; 不区分用户类型的不用实现。
- (BOOL)shouldShowClearUserDataForTzGDPR;//返回是否显示清除用户数据入口，不实现回调的情况下,sdk内部默认显示清除入口。
@end

//GDPR实现公共入口
@interface TzGDPRMgr : NSObject
@property (nonatomic,assign)id delegate;
@property (nonatomic,assign)TZEEAConsentStatus consentStatus;

+ (TzGDPRMgr*)sharedInstance;


/**
 在用户打开App的时候，检查当前用户状态，如果为欧盟用户，检测隐私条款状态，非欧盟用户会忽略检查直接返回。

 @param viewController 如果为欧盟用户，那么会在viewController上弹出隐私策略界面
 @param completion 完成检测回调，isGranted = YES表示欧盟用户已同意条款。非欧盟用户直接返回YES
 */
- (void)checkGDPRConsentOnViewController:(UIViewController*)viewController completion:(void(^)(BOOL isGranted))completion;


/**
 @return 是否欧盟用户（European Economic Area User)，用于在App中决定是否显示ConsentSettings入口。
 */
- (BOOL)isEEAUser;


/**
 弹出consent设置界面，包括同意/接受隐私条款，清除用户数据等。
 
 @param viewController 设置界面将会在viewController上弹出来
 @param completion 完成设置回调，needDeactiveUser = YES表示需要注销当前用户。在此界面中，如果用户选择拒绝条款或点击清除数据，会提示用户进行注销操作，当用户选择确认后，会返回needDeactiveUser=YES。当needDeactiveUser=NO，外部调用代码可以不用做任何其它操作。
 */
- (void)presentConsentSettingsFromViewController:(UIViewController *)viewController completion:(void(^)(BOOL needDeactiveUser))completion;
@end
