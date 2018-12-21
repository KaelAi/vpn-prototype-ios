//
//  MutipleDeviceSynMgr.h
//  PFIMCLient
//
//  Created by Tom Wu on 15-3-19.
//  Copyright (c) 2015 Dington. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HistoryMgr.h"

@class Message;
@class HistoryCellData;
@class ChatSession;

@interface MutipleDeviceSynMgr : NSObject

+(void)onReceiveUniversalDeviceSynNotify:(Message*)msg;

+ (void)synDingtoneBlockFriendWithUserId:(NSDictionary*)friendInfo;
+ (void)onReceiveDingtoneBlockFriendMsg:(Message*)msg;

+ (void)synDingtoneDelFriendWithUserId:(NSString*)userId;
+ (void)onReceiveDingtoneDelFriendMsg:(Message*)msg;

+ (void)synReadTalkInvite:(NSString*)sessionId;
+ (void)onReceiveReadTalkInvite:(Message*)msg;

+ (void)synReadAllMissCall;
+ (void)onReceiveReadAllMissCall:(Message*)msg;

+ (void)synReadMissCallWithCallId:(NSString*)callID withPrivateNumner:(NSString*)privateNumber;
+ (void)onReceiveReadMissCall:(Message*)msg;

+ (void)synHandleFriendInvite:(NSString*)strUserId isAccept:(BOOL)isAccept;
+ (void)onReceiveHandleFriendInvite:(Message*)msg;
/*
 isInviteUser: YES: invite, NO: ignore
 */
+ (void)synHandlePeopleMayKnown:(NSString*)strUserId isInviteUser:(BOOL)isInviteUser;
+ (void)onReceiveHandlePeropleMayKnown:(Message*)msg;

+ (void)synDelChatMessage:(NSString*)msgId sendUserId:(NSString*)sendUserId;
+ (void)onReceiveDelChatMessage:(Message*)msg;
+ (void)synDelChatMessageArray:(NSArray*)msgArray;
+ (void)onReceiveDelChatMessageArray:(Message*)msg;

/*
 call mode info change
 */
+ (void)synChangeCallModeData;
+ (void)onReceiveChangeCallModeInfo:(Message*)msg;

/*
 change pstn sms mode
 */
+ (void)synChangePSTNSMSMode;
+ (void)onReceiveChangePSTNSMSMode:(Message*)msg;

+ (void)synPSTNCallRecordDuration:(int64_t)duration withTransactionId:(NSString*)transactionId;
+ (void)onReceivePSTNCallRecordDuration:(Message*)msg;

+ (void)synSetChatMsgSingature:(BOOL)bOpenSingature byChatSession:(NSString*)sessionId withSingatureText:(NSString*)singatureText;
+ (void)onReceiveSetChatMsgSingature:(Message*)msg;

+ (void)synDelAllBlockedSMSByBlockwithMsgIdArray:(NSMutableArray*)msgIdArray withSendUserId:(NSString*)sendUserId;
+ (void)onReceiveDelBlockedSMSBySessiodId:(Message*)msg;

+ (void)synDelAllBlockedSMSByBlock;
+ (void)onReceiveDelBlockedSMS:(Message*)msg;

+ (void)synDelBlockCallHistory;
+ (void)onReceiveDelBlockCallHistory:(Message*)msg;

+ (void)synDelCallHistory:(HistoryCellData*)cellData isMissingCall:(BOOL)isMissingCall;
+ (void)onReceiveDelCallHistory:(Message*)msg;
+ (void)synDelAllCallHistory;
+ (void)onReceiveDelAllCallHistory:(Message*)msg;
+ (void)synDelMissCallHistory;
+ (void)onReceiveDelMissCallHistory:(Message*)msg;
+ (void)synDelTalkHistoryWithTalkSessionId:(NSString*)talkSession;
+ (void)onReceiveDelTalkHistory:(Message*)msg;
+ (void)synDelChatSession:(ChatSession*)chatSession;
+ (void)onReceiveDelChatSession:(Message*)msg;
+ (void)synDelPSTNRecord:(int64_t)transactionId;
+ (void)onReceiveDelPSTNRecord:(Message*)msg;
+ (void)synClearAll;
+ (void)onReceiveClearAll:(Message*)msg;
+ (void)synMessageOnTopState:(BOOL)isOnTop withSession:(ChatSession*)chatSession;
+ (void)onReceiveMessageOnTop:(Message*)msg;
@end
