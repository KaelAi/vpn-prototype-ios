//
//  MutipleDeviceSynMgr.m
//  PFIMCLient
//
//  Created by Tom Wu on 15-3-19.
//  Copyright (c) 2015 Dington. All rights reserved.
//

#import "MutipleDeviceSynMgr.h"
#import "Message.h"
#import "NLog.h"
#import "ServiceMgr.h"
#import "TPWrapper.h"
#import "MyInfo.h"
#import "FollowerMgr.h"
#import "Contact.h"
#import "NUtils.h"
#import "DTTalkMgr.h"
#import "RecentContactMgr.h"
#import "UsageMgr.h"
#import "DTDatabase.h"
#import "WebTask.h"
#import "DtPSTNSMSMgr.h"
#import "ContactListViewSession.h"
#import "HistoryBlockCallAndSMSMgr.h"
#import "HistorySensitiveSMSMgr.h"
#import "DTCallModeMgr.h"

typedef enum enum_universal_device_syn_type{
    enum_universal_device_syn_type_invalid = 0,
    enum_universal_device_syn_type_read_all_miss_call = 1,
    enum_universal_device_syn_type_read_talk_invite = 2,
    enum_universal_device_syn_type_handle_friend_invite = 3,
    enum_universal_device_syn_type_handle_mayknow_people = 4,
    enum_universal_device_syn_type_del_chat_message = 5,
    enum_universal_device_syn_type_del_call_history_item = 6,
    enum_universal_device_syn_type_del_all_call_history = 7,
    enum_universal_device_syn_type_del_miss_call_history = 8,
    enum_universal_device_syn_type_del_talk_history = 9,
    enum_universal_device_syn_type_del_chat_session = 10,
    enum_universal_device_syn_type_del_cdr = 11,
    enum_universal_device_syn_type_clear_all = 12,
    enum_universal_device_syn_type_del_chat_message_list = 13,
    enum_universal_device_syn_type_change_pstn_sms_mode = 14,
    enum_universal_device_syn_type_read_miss_call = 15,
    enum_universal_device_syn_type_chat_set_msg_singature = 16,
    enum_universal_device_syn_type_pstn_call_duration = 17,
    enum_universal_device_syn_type_del_friend = 18,
    enum_universal_device_syn_type_block_user = 19,
    enum_universal_device_syn_type_message_on_top = 20,
    enum_universal_device_syn_type_del_block_call = 21,
    enum_universal_device_syn_type_del_all_by_block_sms = 22,
    enum_universal_device_syn_type_del_by_block_sms_user = 23,
    enum_universal_device_syn_type_call_mode_info = 24,
}enum_universal_device_syn_type;


//desc
NSInteger sortMsgReceiveTimeData(id item1, id item2, void *context);

NSInteger sortMsgReceiveTimeData(id item1, id item2, void *context)
{
    if ([item1 isKindOfClass:[Message class]] && [item2 isKindOfClass:[Message class]])
    {
        Message* msg1 = (Message*)item1;
        Message* msg2 = (Message*)item2;
        
        double v1 = msg1.timestamp;
        double v2 = msg2.timestamp;
        
        
        if (v1 == 0 || v2 == 0)
        {
            return NSOrderedSame;
        }
        else
        {
            if (v1 < v2)
            {
                return NSOrderedAscending;
            }
            else if(v1 > v2)
            {
                return NSOrderedDescending;
            }
            else
            {
                return NSOrderedSame;
            }
        }
    }
    else{
        LogE(@"sortShowArray,type error.");
        return NSOrderedSame;
    }
}

#define kSynType @"type"
@implementation MutipleDeviceSynMgr


#pragma mark -
+ (enum_universal_device_syn_type)universalSynType:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    return [[dicInfo objectForKey:kSynType] intValue];
}

+(void)onReceiveUniversalDeviceSynNotify:(Message*)msg
{
    @try {
        if (msg.type != MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY) {
            Assert(0);
            return;
        }
        
        if (![msg.sentUserId isEqualToString:[MyInfo myUserId]]) {
            Assert(0);
            LogE(@"invalid sent user id:%@",msg.sentUserId);
            return;
        }
        
        enum_universal_device_syn_type readType = [MutipleDeviceSynMgr universalSynType:msg];
        switch (readType) {
            case enum_universal_device_syn_type_read_all_miss_call:
            {
                [MutipleDeviceSynMgr onReceiveReadAllMissCall:msg];
            }
                break;
            case enum_universal_device_syn_type_read_talk_invite:
            {
                [MutipleDeviceSynMgr onReceiveReadTalkInvite:msg];
            }
                break;
            case enum_universal_device_syn_type_handle_friend_invite:
            {
                [MutipleDeviceSynMgr onReceiveHandleFriendInvite:msg];
            }
                break;
            case enum_universal_device_syn_type_handle_mayknow_people:
            {
                [MutipleDeviceSynMgr onReceiveHandlePeropleMayKnown:msg];
            }
                break;
            case enum_universal_device_syn_type_del_chat_message:
            {
                [MutipleDeviceSynMgr onReceiveDelChatMessage:msg];
            }
                break;
            case enum_universal_device_syn_type_del_chat_message_list:
            {
                [MutipleDeviceSynMgr onReceiveDelChatMessageArray:msg];
            }
                break;
            case enum_universal_device_syn_type_del_call_history_item:
            {
                [MutipleDeviceSynMgr onReceiveDelCallHistory:msg];
            }
                break;
            case enum_universal_device_syn_type_del_all_call_history:
            {
                [MutipleDeviceSynMgr onReceiveDelAllCallHistory:msg];
            }
                break;
            case enum_universal_device_syn_type_del_miss_call_history:
            {
                [MutipleDeviceSynMgr onReceiveDelMissCallHistory:msg];
            }
                break;
            case enum_universal_device_syn_type_del_talk_history:
            {
                [MutipleDeviceSynMgr onReceiveDelTalkHistory:msg];
            }
                break;
            case enum_universal_device_syn_type_del_chat_session:
            {
                [MutipleDeviceSynMgr onReceiveDelChatSession:msg];
            }
                break;
            case enum_universal_device_syn_type_del_cdr:
            {
                [MutipleDeviceSynMgr onReceiveDelPSTNRecord:msg];
            }
                break;
            case enum_universal_device_syn_type_clear_all:
            {
                [MutipleDeviceSynMgr onReceiveClearAll:msg];
            }
                break;
            case enum_universal_device_syn_type_change_pstn_sms_mode:
            {
                [MutipleDeviceSynMgr onReceiveChangePSTNSMSMode:msg];
            }
                break;
            case enum_universal_device_syn_type_read_miss_call:
            {
                [MutipleDeviceSynMgr onReceiveReadMissCall:msg];
            }
                break;
            case enum_universal_device_syn_type_chat_set_msg_singature:
            {
                [MutipleDeviceSynMgr onReceiveSetChatMsgSingature:msg];
            }
                break;
            case enum_universal_device_syn_type_message_on_top:
            {
                [MutipleDeviceSynMgr onReceiveMessageOnTop:msg];
            }
                break;
            case enum_universal_device_syn_type_pstn_call_duration:
            {
                [MutipleDeviceSynMgr onReceivePSTNCallRecordDuration:msg];
            }
                break;
            case enum_universal_device_syn_type_del_friend:
            {
                [MutipleDeviceSynMgr onReceiveDingtoneDelFriendMsg:msg];
            }
                break;
            case enum_universal_device_syn_type_block_user:
            {
                [MutipleDeviceSynMgr onReceiveDingtoneBlockFriendMsg:msg];
            }
                break;
            case enum_universal_device_syn_type_del_block_call:
            {
                [MutipleDeviceSynMgr onReceiveDelBlockCallHistory:msg];
            }
                break;
            case enum_universal_device_syn_type_del_all_by_block_sms:
            {
                [MutipleDeviceSynMgr onReceiveDelBlockedSMS:msg];
            }
                break;
            case enum_universal_device_syn_type_del_by_block_sms_user:
            {
                [MutipleDeviceSynMgr onReceiveDelBlockedSMSByBlockwithMsgIdArray:msg];
            }
                break;
            case enum_universal_device_syn_type_call_mode_info:
            {
                [MutipleDeviceSynMgr onReceiveChangeCallModeInfo:msg];
            }
                break;
            default:
            {
                LogI(@"unsupport read notfiy type:%d",readType);
            }
                break;
        }
    }
    @catch (NSException *exception) {
        LogE(@"catch a exception of universal device syn message");
    }
}

#pragma mark -
#pragma mark -
/*
 {"type":"2","session":"793874948623798"}
 */

+ (void)synDingtoneBlockFriendWithUserId:(NSDictionary*)friendInfo
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_block_user;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    [dicInfo setObject:[friendInfo objectForKey:@"friendId"] forKey:@"friendId"];
    [dicInfo setObject:[friendInfo objectForKey:@"isBlock"] forKey:@"isBlock"];
    [dicInfo setObject:[friendInfo objectForKey:@"blockListVersion"] forKey:@"blockListVersion"];
    NSString* displayName = [friendInfo objectForKey:@"displayName"];
    if (displayName == nil || [displayName length] == 0)
    {
        displayName = @"";
    }
    [dicInfo setObject:displayName forKey:@"displayName"];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    
    LogI(@"Dingtone block friend, will send mutiple device notif msg:%@",msg.msgId);
    [[ServiceMgr getTP] sendMessage:msg];
}

+ (void)onReceiveDingtoneBlockFriendMsg:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    NSString* userId = [dicInfo objectForKey:@"friendId"];
    if (![dicInfo isKindOfClass:[NSDictionary class]])
    {
        return;
    }
    if (dicInfo == nil || [dicInfo count] == 0)
    {
        LogE(@"userId is nil");
        return;
    }
    
    ContactListViewSession* listSession = [[ServiceMgr sessionMgr] getSessionBy:VIEW_TYPE_CONTACT];
    [listSession blockFriendWithInfo:dicInfo];
    LogI(@"receive other device's dingtone block friend notify, userId:%@", userId);
}

+ (void)synDingtoneDelFriendWithUserId:(NSString*)userId
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_del_friend;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    [dicInfo setObject:[NSNumber numberWithLongLong:[userId longLongValue]] forKey:@"friendId"];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    
    LogI(@"Dingtone del friend, will send mutiple device notif msg:%@",msg.msgId);
    [[ServiceMgr getTP] sendMessage:msg];
}

+ (void)onReceiveDingtoneDelFriendMsg:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    NSString* userId = [NSString stringWithFormat:@"%lld", [[dicInfo objectForKey:@"friendId"] longLongValue]];
    if (userId == nil || [userId length] == 0)
    {
        LogE(@"userId is nil");
        return;
    }
    
    ContactListViewSession* listSession = [[ServiceMgr sessionMgr] getSessionBy:VIEW_TYPE_CONTACT];
    [listSession delFriendWithUserId:userId];
    LogI(@"receive other device's dingtone del friend notify, userId:%@", userId);
}

+ (void)synPSTNCallRecordDuration:(int64_t)duration withTransactionId:(NSString*)transactionId
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_pstn_call_duration;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    [dicInfo setObject:transactionId forKey:@"transactionId"];
    [dicInfo setObject:[NSString stringWithFormat:@"%lld", duration*1000] forKey:@"durationTime"]; // change mms
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    
    LogI(@"pstn call duration, will send mutiple device notif msg:%@",msg.msgId);
    [[ServiceMgr getTP] sendMessage:msg];
}

+ (void)onReceivePSTNCallRecordDuration:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    NSString* transactionId = [dicInfo objectForKey:@"transactionId"];
    NSString* strDuration = [dicInfo objectForKey:@"durationTime"];
    
    if (transactionId == nil || [transactionId length] == 0)
    {
        LogE(@"transactionId is nil");
        return;
    }
    
    if (strDuration == nil || [strDuration longLongValue] == 0)
    {
        LogE(@"strDuration is nil or 0");
        return;
    }
    
    [[HistoryMgr sharedInstance] updateCallRecordDuration:strDuration withTransactionId:transactionId];
    LogI(@"receive other device's pstn call duration notify, transactionId:%@, duration:%@", transactionId, strDuration);
}

+ (void)synSetChatMsgSingature:(BOOL)bOpenSingature byChatSession:(NSString*)sessionId withSingatureText:(NSString*)singatureText
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_chat_set_msg_singature;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    [dicInfo setObject:sessionId forKey:@"session"];
    [dicInfo setObject:[NSNumber numberWithBool:bOpenSingature] forKey:@"bOpenSingature"];
    if ([singatureText length] > 0)
    {
        [dicInfo setObject:singatureText forKey:@"messageSingature"];
    }

    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    
    LogI(@"message singature, will send mutiple device notif msg:%@",msg.msgId);
    [[ServiceMgr getTP] sendMessage:msg];
}

+ (void)onReceiveSetChatMsgSingature:(Message*)msg
{
    LogI(@"receive other device's Change PSTN SMS mode success notify");
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    NSString* sessionId = [dicInfo objectForKey:@"session"];
    if (sessionId == nil || [sessionId length] == 0)
    {
        LogE(@"chat sessionId is nil");
        return;
    }
    
    ChatViewSession* chatViewSession = [[ServiceMgr sessionMgr] getSessionBy:VIEW_TYPE_CHAT];
    ChatSession* chatSession = [chatViewSession getChatSession:sessionId];
    if (chatSession.chatSet)
    {
        [chatSession.chatSet setChatMessageSignature:[[dicInfo objectForKey:@"bOpenSingature"] boolValue]];
        NSString* singatureText = [dicInfo objectForKey:@"messageSingature"];
        if (singatureText)
        {
            [chatSession.chatSet setChatMessageSignatureText:singatureText];
        }
    }
}

/*
 change pstn sms mode
 */
+ (void)synChangePSTNSMSMode
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_change_pstn_sms_mode;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    
    LogI(@"change PSTN SMS mode success, will send mutiple device notif msg:%@",msg.msgId);
    [[ServiceMgr getTP] sendMessage:msg];
}

+ (void)onReceiveChangePSTNSMSMode:(Message*)msg
{
    LogI(@"receive other device's Change PSTN SMS mode success notify");
    [[DtPSTNSMSMgr sharedInstance] queryPSTNSMSModeInfo];
//    [[ServiceMgr getMsgHandler] HandleGetMyBalance];
}

+ (void)synReadTalkInvite:(NSString*)sessionId
{
    if (sessionId.length == 0) {
        return;
    }
    
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_read_talk_invite;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    [dicInfo setObject:sessionId forKey:@"session"];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    
    LogI(@"read talk invite message sessionId:%@,will send mutilple device notify msg:%@",sessionId,msg.msgId);
    [[ServiceMgr getTP] sendMessage:msg];
}

+ (void)onReceiveReadTalkInvite:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    NSString* sessionId = [dicInfo objectForKey:@"session"];
    [[ServiceMgr getDTTalkMgr] clearLocalTalkInviteMsgWithSesion:sessionId];
    [[ServiceMgr getDTTalkMgr] updateTalkUI];
    LogI(@"receive other device's talk invite read notify:%@",sessionId);
}

+ (void)synReadAllMissCall
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_read_all_miss_call;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    
    LogI(@"read all call record, will send mutiple device notif msg:%@",msg.msgId);
    [[ServiceMgr getTP] sendMessage:msg];
}

+ (void)onReceiveReadAllMissCall:(Message*)msg
{
    LogI(@"receive other device's all call record read notify");
    [[HistoryMgr sharedInstance] clearLocalCallUnreadState];
}

+ (void)synReadMissCallWithCallId:(NSString*)callID withPrivateNumner:(NSString*)privateNumber
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_read_miss_call;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    [dicInfo setObject:callID forKey:@"callId"];
    if ([privateNumber length] > 0)
    {
        [dicInfo setObject:privateNumber forKey:@"privateNumber"];
    }
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    
    LogI(@"read call record, will send mutiple device notif msg:%@",msg.msgId);
    [[ServiceMgr getTP] sendMessage:msg];
}

+ (void)onReceiveReadMissCall:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    NSString* callId = [dicInfo objectForKey:@"callId"];
    NSString* callPrivateNumber = [dicInfo objectForKey:@"privateNumber"];
    if ([callId length] > 0)
    {
        [[HistoryMgr sharedInstance] checkReadCallWithCallId:callId withTargetNumber:callPrivateNumber];
    }
}

+ (void)synHandleFriendInvite:(NSString*)strUserId isAccept:(BOOL)isAccept
{
    if (strUserId.length == 0) {
        return;
    }
    
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_handle_friend_invite;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    [dicInfo setObject:strUserId forKey:@"uid"];
    [dicInfo setObject:[NSNumber numberWithBool:isAccept] forKey:@"isAccept"];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    [[ServiceMgr getTP] sendMessage:msg];
    LogI(@"syn handle friend invite to other device :%@",msg.msgId);
}

+ (void)onReceiveHandleFriendInvite:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    NSString* strUserId = [dicInfo objectForKey:@"uid"];
    //    BOOL isAccept = [[dicInfo objectForKey:@"isAccept"] boolValue];
    
    Contact* contact = nil;
    contact = [[ServiceMgr getContactMgr] FindContactInDingtoneList:[strUserId longLongValue]];
    if (contact == nil) {
        contact = [[[Contact alloc] init] autorelease];
        contact.userId = [strUserId longLongValue];
    }
    [[ServiceMgr getContactMgr] removeFriendRequest:contact];
    LogI(@"handle friend invite by other device :%@",msg.msgId);
    DownFriendListTask * task = [[[DownFriendListTask alloc] initWithVersion:0] autorelease];
    [[[ServiceMgr sharedServiceMgr] getTaskMgr] push_back:task];
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_CONTACT_VIEW object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_FRIEND_REQUEST_VIEW object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:UPDATE_USER_INVITEINFO_NOTIFICATION object:nil userInfo:dicInfo];
}

+ (void)synHandlePeopleMayKnown:(NSString*)strUserId isInviteUser:(BOOL)isInviteUser
{
    if (strUserId.length == 0) {
        return;
    }
    
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_handle_mayknow_people;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    [dicInfo setObject:strUserId forKey:@"uid"];
    [dicInfo setObject:[NSNumber numberWithBool:isInviteUser] forKey:@"isInvite"];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    [[ServiceMgr getTP] sendMessage:msg];
    LogI(@"syn handle people may know to other device :%@",msg.msgId);
}

+ (void)onReceiveHandlePeropleMayKnown:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    NSString* strUserId = [dicInfo objectForKey:@"uid"];
    BOOL isInvite = [[dicInfo objectForKey:@"isInvite"] boolValue];
    
    if (isInvite) {
        Follower *theFollower = [[FollowerMgr sharedInstance] findFollowerWithUserId:[strUserId longLongValue]];
        if (theFollower) {
            theFollower.inviteStatus = follower_invite_status_invited;
            [[FollowerMgr sharedInstance] saveAllUserFollowers];
        }
        
        theFollower = [[FollowerMgr sharedInstance] findInvitorFollowerWithUserId:[strUserId longLongValue]];
        if (theFollower) {
            theFollower.inviteStatus = follower_invite_status_invited;
            [[FollowerMgr sharedInstance] saveAllUserFollowers];
        }
    }
    else{
        Follower *theFollower = [[FollowerMgr sharedInstance] findFollowerWithUserId:[strUserId longLongValue]];
        if (theFollower) {
            theFollower.inviteStatus = follower_invite_status_ignore;
            [[FollowerMgr sharedInstance] saveAllUserFollowers];
        }
        
        theFollower = [[FollowerMgr sharedInstance] findInvitorFollowerWithUserId:[strUserId longLongValue]];
        if (theFollower) {
            theFollower.inviteStatus = follower_invite_status_ignore;
            [[FollowerMgr sharedInstance] saveAllUserFollowers];
        }
    }
    
    LogI(@"handle people may know by other device :%@",msg.msgId);
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_CONTACT_VIEW object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_FOLLOWER_LIST_VIEW object:nil];
}

+ (void)synDelChatMessage:(NSString*)msgId sendUserId:(NSString*)sendUserId
{
    if (msgId == nil || sendUserId == nil) {
        return;
    }
    
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_del_chat_message;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    [dicInfo setObject:msgId forKey:@"msg"];
    [dicInfo setObject:sendUserId forKey:@"sender"];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    [[ServiceMgr getTP] sendMessage:msg];
    
    LogI(@"syn del msg:%@ to other device(%@)",msgId,msg.msgId);
}

+ (void)onReceiveDelChatMessage:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    NSString* msgId = [dicInfo objectForKey:@"msg"];
    NSString* sendUserId = [dicInfo objectForKey:@"sender"];
    
    Message* theMsg = [[ServiceMgr getMessageMgr] getMessageBy:msgId andBySenterId:sendUserId];
    [[ServiceMgr getMessageMgr] deleteMsg:theMsg];
    
    LogI(@"del msg:%@ by other device(%@)",msgId,msg.msgId);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_CONTACT_VIEW object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_MESSAGE_VIEW object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_CHAT_VIEW object:nil];
}
+ (void)synDelChatMessageArray:(NSArray*)msgArray
{
    if (msgArray == nil) {
        return;
    }
    
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_del_chat_message_list;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    NSMutableArray* arrayMsgInfo = [NSMutableArray array];
    for (Message* msg in msgArray) {
        NSMutableDictionary* dicItem = [NSMutableDictionary dictionary];
        [dicItem setObject:msg.msgId forKey:@"msg"];
        [dicItem setObject:msg.sentUserId forKey:@"sender"];
        
        [arrayMsgInfo addObject:dicItem];
    }
    [dicInfo setObject:arrayMsgInfo forKey:@"list"];
 
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    [[ServiceMgr getTP] sendMessage:msg];
    
    LogI(@"syn del msg:%@ to other device(%@)",strInfo,msg.msgId);
}

+ (void)onReceiveDelChatMessageArray:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    NSMutableArray* arrayMsgInfo = [dicInfo objectForKey:@"list"];
    for (NSDictionary* dicItem in arrayMsgInfo) {
        NSString* msgId = [dicItem objectForKey:@"msg"];
        NSString* sendUserId = [dicItem objectForKey:@"sender"];
        
        Message* theMsg = [[ServiceMgr getMessageMgr] getMessageBy:msgId andBySenterId:sendUserId];
        [[ServiceMgr getMessageMgr] deleteMsg:theMsg];
        
        LogI(@"del msg:%@ by other device(%@)",msgId,msg.msgId);
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_CONTACT_VIEW object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_MESSAGE_VIEW object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_CHAT_VIEW object:nil];
}
enum enum_universal_call_type
{
    enum_universal_call_type_dingtone = 0,
    enum_universal_call_type_pstn = 1,
    enum_universal_call_type_localcal = 2,
    enum_universal_call_type_callback = 3,
    enum_universal_call_type_inbound = 4,
    enum_universal_call_type_pstn_change_free_call = 5,
};

#pragma mark - 
#pragma mark Block call
+ (void)synDelBlockCallHistory
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_del_block_call;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    
    LogI(@"del block call, will send mutiple device notif msg:%@",msg.msgId);
    [[ServiceMgr getTP] sendMessage:msg];
}

+ (void)onReceiveDelBlockCallHistory:(Message*)msg
{
    //remove from DB
    [[ServiceMgr getMessageMgr] removeAllBlockCallFromDB];
    //remove from cache
    HistoryCellData* cellData = [HistoryBlockCallAndSMSMgr sharedInstance].blockCallCellData;
    if (cellData)
    {
        //has load to cache
        [[HistoryBlockCallAndSMSMgr sharedInstance] removeAllBlockCallCache];
        [[HistoryMgr sharedInstance] delHistoryBlockCellData:cellData];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_HISTORY_VIEW object:nil];
    LogI(@"del block call item by other device,msg:%@",msg.msgId);
}

#pragma mark -
#pragma mark CallModeInfo
+ (void)synChangeCallModeData
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_call_mode_info;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    [dicInfo setObject:[NSString stringWithFormat:@"%d", [[DTCallModeMgr sharedInstance] currentCallModeType]] forKey:@"callModeType"];
    [dicInfo setObject:[NSString stringWithFormat:@"%ld", (long)[[DTCallModeMgr sharedInstance] todayCallFeeModeCount]] forKey:@"todayUseCountCallMode"];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    
    LogI(@"call mode info syn, will send mutiple device notif msg:%@",msg.msgId);
    [[ServiceMgr getTP] sendMessage:msg];
}

+ (void)onReceiveChangeCallModeInfo:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    callModeType currentModeType = [[dicInfo objectForKey:@"callModeType"] intValue];
    NSInteger nCount = [[dicInfo objectForKey:@"todayUseCountCallMode"] integerValue];
    
    LogI(@"receive other device's Change call mode info current modeType:%d, count:%d", currentModeType, nCount);
    [[DTCallModeMgr sharedInstance] setCurrentCallModeType:currentModeType];
    [[DTCallModeMgr sharedInstance] setTodayCallFeeModeCount:nCount];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_CALL_MODE_INFO_NOTIFY object:nil];
}

#pragma mark -
#pragma mark Block sms

+ (void)synDelAllBlockedSMSByBlockwithMsgIdArray:(NSMutableArray*)msgIdArray withSendUserId:(NSString*)sendUserId
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_del_by_block_sms_user;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    [dicInfo setObject:msgIdArray forKey:@"delBlockMessage"];
    [dicInfo setObject:sendUserId forKey:@"sendUserId"];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    
    LogI(@"del block sms by block with magIdArray, will send mutiple device notif msg:%@",msg.msgId);
    [[ServiceMgr getTP] sendMessage:msg];
}

+ (void)onReceiveDelBlockedSMSByBlockwithMsgIdArray:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    NSArray* msgIdArray = [dicInfo objectForKey:@"delBlockMessage"];
    NSString* sendUserId = [dicInfo objectForKey:@"sendUserId"];
    
    if ([sendUserId length] > 0 && [msgIdArray count] > 0)
    {
        LogI(@"handle syn block sms item by other device,msg:%@, sendUserId:%@, msgCount:%d",msg.msgId, sendUserId, [msgIdArray count]);
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        NSMutableArray* newUserMagArray = [[NSMutableArray alloc] init];
        
        NSString* sessionId = nil;
        if ([msgIdArray count] > 0)
        {
            NSString* str = [[ServiceMgr getMessageMgr] getSessionIdBlockFormDBBySendUserId:sendUserId withMsgId:[msgIdArray objectAtIndex:0]];
            if ([str length] > 0)
            {
                sessionId = [NSString stringWithString:str];
            }
        }
        
        // change to user msg and delete block msg
        for (NSString* msgId in msgIdArray)
        {
            Message* newMsg = [[HistoryBlockCallAndSMSMgr sharedInstance] getBlockedSMSWithSendUserId:sendUserId withMsgId:msgId];
            if (newMsg == nil)
            {
                if ([sessionId length] > 0)
                {
                    newMsg = [[HistoryBlockCallAndSMSMgr sharedInstance] getNoBalanceBlockedSMSWithSessionId:sessionId withMsgId:msgId];
                }
            }
            
            if (newMsg != nil)
            {
                [newUserMagArray addObject:newMsg];
            }
            [[ServiceMgr getMessageMgr] removeAllBlockMessagesFromDBBySendUserId:sendUserId withMsgId:msgId];
            [[HistoryBlockCallAndSMSMgr sharedInstance] removeBlockedSMSWithSendUserId:sendUserId withMsgId:msgId];
            if ([sessionId length] > 0) {
                [[HistoryBlockCallAndSMSMgr sharedInstance] removeNoBalanceBlockedSMSWithSessionId:sessionId withMsgId:msgId];
            }
        }
        
        [newUserMagArray sortUsingFunction:sortMsgReceiveTimeData context:nil];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [[HistoryBlockCallAndSMSMgr sharedInstance] reloadNoBalanceBlockedMsgFromDB];
            for (Message* newMsg in newUserMagArray)
            {
                ChatViewSession* chatViewSession = [[ServiceMgr sessionMgr] getSessionBy:VIEW_TYPE_CHAT];
                ChatSession* chatSession = [chatViewSession getChatSession:newMsg.sessionId];
                
                if(chatSession == nil)
                {
                    chatSession = [[ChatSession alloc] initWithPSTNSessionId:newMsg.sessionId withConversationId:newMsg.conversationId withSessionType:newMsg.sessionType];
                    LogI(@"Create chat session(%@), chatSessionType:%d", newMsg.sessionId, chatSession.type);
                   
                    Contact * smsContact = [[[Contact alloc] init] autorelease];
                    smsContact.type =  [NSString stringWithFormat:@"%d",USERTYPE_PSTN_SMS];
                    smsContact.phoneNumber = newMsg.phoneNumber;
                    smsContact.userId = [newMsg.phoneNumber longLongValue];
                    [chatSession addBuddy:smsContact];
                    
                    [chatViewSession addChatSession:chatSession];
                    [chatSession release];
                    
                }
                [[ServiceMgr getMsgHandler] saveMsg:newMsg];
            }
            LogI(@"del by block sms item by other device,msg:%@",msg.msgId);
            [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_MESSAGE_VIEW object:nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_CHAT_VIEW object:nil];
        });
        
        [newUserMagArray release];
        [pool release];
    });
}

+ (void)synDelAllBlockedSMSByBlock
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_del_all_by_block_sms;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    
    LogI(@"del block sms by block, will send mutiple device notif msg:%@",msg.msgId);
    [[ServiceMgr getTP] sendMessage:msg];
}

+ (void)onReceiveDelBlockedSMS:(Message*)msg
{
    //remove from DB
    [[ServiceMgr getMessageMgr] removeAllBlockMessagesFromDB];
    //remove from cache
    [[HistoryBlockCallAndSMSMgr sharedInstance] removeAllBlockSMSCache];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_MESSAGE_VIEW object:nil];
    LogI(@"del by block sms item by other device,msg:%@",msg.msgId);
}

+ (void)synDelCallHistory:(HistoryCellData*)cellData isMissingCall:(BOOL)isMissingCall
{
    @try {
        if (cellData == nil || ![cellData isKindOfClass:[HistoryCellData class]]) {
            return;
        }
        
        NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
        
        //android client need callType
        int universalCallType = -1;
        CallRecordPhoneType phoneType = cellData.latestCall.phoneType;
        if (phoneType == CALL_RECORD_PHONE_TYPE_DINGTONE) {
            universalCallType = enum_universal_call_type_dingtone;
        }
        else if (phoneType == CALL_RECORD_PHONE_TYPE_PSTN){
            universalCallType = enum_universal_call_type_pstn;
        }
        else if (phoneType == CALL_RECORD_PHONE_TYPE_PSTN_LOCAL_CALL){
            universalCallType = enum_universal_call_type_localcal;
        }
        else if (phoneType == CALL_RECORD_PHONE_TYPE_PSTN_CALLBACK){
            universalCallType = enum_universal_call_type_callback;
        }
        else if (phoneType == CALL_RECORD_PHONE_TYPE_PSTN_INBOUND_CALL){
            universalCallType = enum_universal_call_type_inbound;
        }
        [dicInfo setObject:[NSNumber numberWithInt:universalCallType] forKey:@"callType"];
        
        NSArray* timeOfDay = [[HistoryMgr sharedInstance] getOneDayStartAndEndTimestampByTimestamp:cellData.latestCall.startTime];
        NSTimeInterval start = [[timeOfDay objectAtIndex:0] timeIntervalSince1970];
        NSTimeInterval end = [[timeOfDay objectAtIndex:1] timeIntervalSince1970];
        
        BOOL isCallIn = NO;
        if(cellData.latestCall.type == CALL_RECORD_TYPE_CALL_IN ||
           cellData.latestCall.type == CALL_RECORD_TYPE_CALL_MISSED ||
           cellData.latestCall.type == CALL_RECORD_TYPE_CALL_DECLINED)
        {
            isCallIn = YES;
        }
        
        NSMutableArray* sessionIdInTheCell = [[NSMutableArray alloc] init];
        NSArray* arrayRecordInTheCell =[NSMutableArray arrayWithArray:[[HistoryMgr sharedInstance] getCallRecordArrayOfDayByCallRecord:cellData.latestCall isMiss:isMissingCall]];
        for (CallRecord* call in arrayRecordInTheCell) {
            [sessionIdInTheCell addObject:call.callSessionId];
        }
        
        NSString* callId = cellData.latestCall.callId;
        NSString* callerId = cellData.latestCall.targetId;
        
        enum_universal_device_syn_type readType = enum_universal_device_syn_type_del_call_history_item;
        [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
        [dicInfo setObject:[NSNumber numberWithDouble:start] forKey:@"start"];
        [dicInfo setObject:[NSNumber numberWithDouble:end] forKey:@"end"];
        [dicInfo setObject:[NSNumber numberWithInt:isCallIn] forKey:@"in"];
        [dicInfo setObject:sessionIdInTheCell forKey:@"sessionId"];
        [dicInfo setObject:callId forKey:@"callId"];
        if (callerId) {
            [dicInfo setObject:callerId forKey:@"callerId"];
        }
        
        [dicInfo setObject:[NSNumber numberWithInt:isMissingCall] forKey:@"isMiss"];
        
        NSString* strInfo = [dicInfo JSONRepresentationSystem];
        
        Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
        [[ServiceMgr getTP] sendMessage:msg];
        LogI(@"syn del call item:%@ to other device,msg:%@",callId,msg.msgId);
    }
    @catch (NSException *exception) {
        LogE(@"catch a exception");
    }
}

+ (void)onReceiveDelCallHistory:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    
    BOOL isCallIn = [[dicInfo objectForKey:@"in"] boolValue];
    NSTimeInterval start = [[dicInfo objectForKey:@"start"] doubleValue];
    NSTimeInterval end = [[dicInfo objectForKey:@"end"] doubleValue];
    NSString* callId = [dicInfo objectForKey:@"callId"];
    NSString* callerId = [dicInfo objectForKey:@"callerId"];
    BOOL isMissingCall= [[dicInfo objectForKey:@"isMiss"] boolValue];
    NSArray* sessionIdInTheCell = [dicInfo objectForKey:@"sessionId"];
    
    NSString* callType = @"CALLOUT";
    if(isCallIn)
    {
        callType = @"CALLIN";
    }
    NSString* key = [NSString stringWithFormat:@"%@-%@-%@-%@",[NUtils getDayKeyWithTimeIntervalInGregorianCalendar:start], callType, callId, callerId];
    HistoryCellData* cellData = [[HistoryMgr sharedInstance] getCellDataWithKey:key isMissingCall:isMissingCall];
    if (cellData) {
        //has load to cache
        [[HistoryMgr sharedInstance] delHistoryOfDayAndNotifyOthersByItem:cellData isMiss:isMissingCall synDB:YES synUnread:YES synReltiveMsg:YES];
    }
    else{
        //del from db directly if has not load to cache
        if (sessionIdInTheCell.count > 0) {
            [[ServiceMgr getMessageMgr] HistoryMgrSynToMessageMgrForDelCallRecordWithsessionId:sessionIdInTheCell callId:callId needSynToDB:YES];
            [[ServiceMgr getMessageMgr] removeCallParticipantFromDBWithCallSessionId:sessionIdInTheCell isMissedCall:isMissingCall];
        }
        
        [[ServiceMgr getMessageMgr] delCallRecordFrom:start to:end callId:callId isCallIn:isCallIn isMiss:isMissingCall withCallerId:callerId];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_HISTORY_VIEW object:nil];
    LogI(@"del call item by other device,callid:%@,msg:%@",callId,msg.msgId);
}
+ (void)synDelAllCallHistory
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_del_all_call_history;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    [[ServiceMgr getTP] sendMessage:msg];
    LogI(@"syn del all call to other device,msg:%@",msg.msgId);
}
+ (void)onReceiveDelAllCallHistory:(Message*)msg
{
    [[HistoryMgr sharedInstance] delAllHistoryOfDayAndNotifyOthersIsMiss:NO];
    [[ServiceMgr sessionMgr] updateBadgeForTabBar:2];
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_HISTORY_VIEW object:nil];
    LogI(@"del all call by other device,msg:%@",msg.msgId);
}
+ (void)synDelMissCallHistory
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_del_miss_call_history;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    [[ServiceMgr getTP] sendMessage:msg];
    LogI(@"syn del miss call to other device,msg:%@",msg.msgId);
}

+ (void)onReceiveDelMissCallHistory:(Message*)msg
{
    [[HistoryMgr sharedInstance] delAllHistoryOfDayAndNotifyOthersIsMiss:YES];
    [[ServiceMgr sessionMgr] updateBadgeForTabBar:2];
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_HISTORY_VIEW object:nil];
    LogI(@"del miss call by other device,msg:%@",msg.msgId);
}

+ (void)synDelTalkHistoryWithTalkSessionId:(NSString*)talkSession
{
    if (talkSession == nil) {
        return;
    }
    
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_del_talk_history;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    [dicInfo setObject:talkSession forKey:@"session"];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    [[ServiceMgr getTP] sendMessage:msg];
    LogI(@"syn other device del talk history:%@,msg:%@",talkSession,msg.msgId);
}

+ (void)onReceiveDelTalkHistory:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    NSString* talkSession = [dicInfo objectForKey:@"session"];
    NSString* convId = [[ServiceMgr getConversationMgr] getConversationIdBySessionId:talkSession];
    
    if ([[ServiceMgr getDTTalkMgr].walkieTalkieSession.conversationId isEqualToString:convId] || [[ServiceMgr getDTTalkMgr].commandSession.conversationId isEqualToString:convId]) {
        LogI(@"can not del cur talk conversation:%@",convId);
        return;
    }
    
    TalkConvInfo* talkInfo = [[ServiceMgr getDTTalkMgr] getTalkInfoWithConversatioinId:convId];
    if (talkInfo) {
        //has load to cache
        [[ServiceMgr getDTTalkMgr] delTalkConversation:talkInfo];
    }
    else{
        //del db directly
        NSString* talkGroupId = [[ServiceMgr getConversationMgr] getSessionIdByConversationId:convId];
        [[ServiceMgr getDTTalkMgr] clearLocalTalkInviteMsgWithSesion:talkGroupId];
        [[ServiceMgr getDTTalkMgr] delTalkHistoryWithConversationId:convId];
    }
    
    LogI(@"del talk history:%@, msg:%@",talkSession,msg.msgId);
}
enum enum_universal_chatsession_type
{
    enum_universal_chatsession_type_dingtone = 0,
    enum_universal_chatsession_type_sms = 1,
    enum_universal_chatsession_type_sms_group = 2,
    enum_universal_chatsession_type_sms_broadcast = 3,
    enum_universal_chatsession_type_inapp_broadcast = 4,
    enum_universal_chatsession_type_facebook = 5,
};
+ (int)getUniversalSessionType:(ChatSession*) chatSession
{
    int universalSessionType = -1;
    if (chatSession.type == CHATSESSION_TYPE_CHAT) {
        universalSessionType = enum_universal_chatsession_type_dingtone;
    }
    else if (chatSession.type == CHATSESSION_TYPE_FACEBOOK){
        universalSessionType = enum_universal_chatsession_type_facebook;
    }
    else if (chatSession.type == CHATSESSION_TYPE_PSTN_SMS){
        universalSessionType = enum_universal_chatsession_type_sms;
    }
    else if (chatSession.type == CHATSESSION_TYPE_GROUP_SMS){
        universalSessionType = enum_universal_chatsession_type_sms_group;
    }
    else if (chatSession.type == CHATSESSION_TYPE_INAPP_BROADCAST){
        universalSessionType = enum_universal_chatsession_type_inapp_broadcast;
    }
    else if (chatSession.type == CHATSESSION_TYPE_BROADCAST_SMS){
        universalSessionType = enum_universal_chatsession_type_sms_broadcast;
    }
    else if (chatSession.type == CHATSESSION_TYPE_PSTN_SMS_SWITCH){
        universalSessionType = enum_universal_chatsession_type_sms;
    }
    else if (chatSession.type == CHATSESSION_TYPE_PSTN_FAX){
    }
    else{
        LogE(@"unsupport session type:%d",chatSession.type);
    }
    return universalSessionType;
}
+ (void)synDelChatSession:(ChatSession*)chatSession
{
    if (chatSession == nil) {
        LogE(@"nil session");
        return;
    }
    
    NSString* sessionId = chatSession.sessionId;
    if (sessionId == nil) {
        return;
    }
    
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    /*
     syn type
     */
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_del_chat_session;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
  
    /*
     session type
     */
    int universalSessionType = [MutipleDeviceSynMgr getUniversalSessionType:chatSession];
    [dicInfo setObject:[NSNumber numberWithInt:universalSessionType] forKey:@"sessionType"];
    
    /*
     session id, pn
     */
    if (chatSession.type == CHATSESSION_TYPE_PSTN_SMS){
        NSString* strTarget = nil; //the target phone number to receive sms
        NSString* strPrivatePhone = nil; //the private phone number to send sms
        
        //get target private phone number and the send private phone number from session id ,conversation id.
        //session id = send phone + target phone;
        //conversation id contain the send phone
        NSArray* converArrayList = [chatSession.conversationId componentsSeparatedByString:@"_"];
        if ([converArrayList count] != 3)
        {
            Assert(0);
            LogE(@"the conversation:%@ is not correct",chatSession.conversationId);
        }
        else{
            strPrivatePhone =  [converArrayList objectAtIndex:2];
            
            int64_t privatePhone = [strPrivatePhone longLongValue];
            int64_t theSessionId = [chatSession.sessionId longLongValue];
            if (privatePhone < 100 || theSessionId < 100 || theSessionId - privatePhone < 100)
            {
                Assert(0);
                LogE(@"the session id is not correct,sessionId:%lld,private:%lld,recevier:%lld",theSessionId,privatePhone,theSessionId - privatePhone );
            }
            else{
                strTarget = [NSString stringWithFormat:@"%lld",theSessionId-privatePhone];
            }
        }
        
        //
        if (strTarget == nil) {
            strTarget = @"";
            Assert(0);
        }
        [dicInfo setObject:strTarget forKey:@"sessionId"];
        
        //
        if (strPrivatePhone == nil) {
            strPrivatePhone = @"";
        }
        [dicInfo setObject:strPrivatePhone forKey:@"pn"];
    }
    else{
        [dicInfo setObject:sessionId forKey:@"sessionId"];
    }
    
    
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    [[ServiceMgr getTP] sendMessage:msg];
    
    LogI(@"syn other device del session:%@, msg:%@",sessionId,msg.msgId);
}

+ (void)onReceiveDelChatSession:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    NSNumber* sessionType = [dicInfo objectForKey:@"sessionType"];
    NSString* sessionId = nil;
    if (sessionType && [sessionType intValue] == enum_universal_chatsession_type_sms) {
        NSString* strPrivatePhone = [dicInfo objectForKey:@"pn"];
        NSString* strTarget = [dicInfo objectForKey:@"sessionId"];
        
        int64_t aSession = [strPrivatePhone longLongValue] + [strTarget longLongValue];
        sessionId = [NSString stringWithFormat:@"%lld",aSession];
    }
    else{
        sessionId = [dicInfo objectForKey:@"sessionId"];
    }
    NSString* convId = [[ServiceMgr getConversationMgr] getConversationIdBySessionId:sessionId];
    
    //del draft text data
    [[ServiceMgr getMessageMgr] deleteChatDraftStringWithConversationId:convId];
    
    [[ServiceMgr getMessageMgr] removeAllMsgFromArrayOfConversation:convId];
    [[ServiceMgr getMessageMgr] removeContacts:convId];
    
    ChatViewSession* chatViewSession = [[ServiceMgr sessionMgr] getSessionBy:VIEW_TYPE_CHAT];
    ChatSession* chatSession = [chatViewSession getChatSession:sessionId];
    [chatViewSession removeChatSession:chatSession];
    [[HistorySensitiveSMSMgr sharedInstance] removeSesitiveMessageCacheWithChatSessionId:chatSession.sessionId];
    
    [[ServiceMgr sessionMgr] updateBadgeForTabBar:1];
    [[ServiceMgr sessionMgr] updateBadgeForTabBar:3];
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_MESSAGE_VIEW object:nil];
    
    LogI(@"del session:%@ by other device syn message:%@",sessionId,msg.msgId);
}

+ (void)synDelPSTNRecord:(int64_t)transactionId
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_del_cdr;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    [dicInfo setObject:[NSNumber numberWithLongLong:transactionId] forKey:@"transactionId"];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    [[ServiceMgr getTP] sendMessage:msg];
    LogI(@"syn other device del cdr:%lld, message:%@",transactionId,msg.msgId);
}

+ (void)onReceiveDelPSTNRecord:(Message*)msg
{
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    int64_t transactionId = [[dicInfo objectForKey:@"transactionId"] longLongValue];
    
    [[DTDatabase sharedInstance] inUpdateDatabaseAsync:^(FMDatabase *db) {
        BOOL isBeginTran = [db beginTransaction];
        if (isBeginTran)
        {
            if (transactionId > 0)
            {
                BOOL isSuccessful =  [db executeUpdate:@"delete from pstnCallRecord where transactionId = ?",[NSNumber numberWithLongLong:transactionId]];
                if (!isSuccessful) {
                    LogE(@"failed to delete transaction:%lld,phone:%@,starttime:%lld",transactionId);
                }
            }
            else
            {
                LogE(@"a record transcation id is 0");
            }
            
            [db commit];
        }
        else
        {
            LogE(@"failed to begin transaction");
        }
    }];
    
    LogI(@"del cdr:%lld by device syn message:%@",transactionId,msg.msgId);
}
+ (void)synClearAll
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type readType = enum_universal_device_syn_type_clear_all;
    [dicInfo setObject:[NSString stringWithFormat:@"%d",readType] forKey:kSynType];
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    [[ServiceMgr getTP] sendMessage:msg];
    
    LogI(@"sys other device clear all:%@",msg.msgId);
}
+ (void)onReceiveClearAll:(Message*)msg
{
    [[ServiceMgr getMessageMgr] removeAllChatDrafts];
    [[ServiceMgr getMessageMgr] clearAllMemoryMsg];
    [[ServiceMgr getMessageMgr] clearVoiceMediaObjectsTable];
    [[ServiceMgr getContactMgr] removeAllDeactiveInfo];
    [[ServiceMgr getDTTalkMgr] delAllTalkConversation];
    [[RecentContactMgr sharedInstance] clearAllRecentContactsItems];
    [UsageMgr clearAllData];
    
    [[ServiceMgr getMessageMgr] removeAllBlockCallFromDB];
    [[HistoryBlockCallAndSMSMgr sharedInstance] removeAllBlockSMSCache];
    [[HistoryBlockCallAndSMSMgr sharedInstance] removeAllBlockCallCache];
    [[HistorySensitiveSMSMgr sharedInstance] clearSensitiveMessageCache];
    
    [[ServiceMgr sessionMgr] updateAllBadgeForTabBar];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_CONTACT_VIEW object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_MESSAGE_VIEW object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:REFRESH_CHAT_VIEW object:nil];
    
    LogI(@"clear all by device syn msg:%@",msg.msgId);
}
+ (void)synMessageOnTopState:(BOOL)isOnTop withSession:(ChatSession*)chatSession
{
    NSMutableDictionary* dicInfo = [NSMutableDictionary dictionary];
    enum_universal_device_syn_type type = enum_universal_device_syn_type_message_on_top;
    

    [dicInfo setObject:[NSString stringWithFormat:@"%d",type] forKey:kSynType];

    /* session id */
    
    if (chatSession.type == CHATSESSION_TYPE_PSTN_SMS){
        NSString* strTarget = nil; //the target phone number to receive sms
        NSString* strPrivatePhone = nil; //the private phone number to send sms
        
        //get target private phone number and the send private phone number from session id ,conversation id.
        //session id = send phone + target phone;
        //conversation id contain the send phone
        NSArray* converArrayList = [chatSession.conversationId componentsSeparatedByString:@"_"];
        if ([converArrayList count] != 3)
        {
            Assert(0);
            LogE(@"the conversation:%@ is not correct",chatSession.conversationId);
        }
        else{
            strPrivatePhone =  [converArrayList objectAtIndex:2];
            
            int64_t privatePhone = [strPrivatePhone longLongValue];
            int64_t theSessionId = [chatSession.sessionId longLongValue];
            if (privatePhone < 100 || theSessionId < 100 || theSessionId - privatePhone < 100)
            {
                Assert(0);
                LogE(@"the session id is not correct,sessionId:%lld,private:%lld,recevier:%lld",theSessionId,privatePhone,theSessionId - privatePhone );
            }
            else{
                strTarget = [NSString stringWithFormat:@"%lld",theSessionId-privatePhone];
            }
        }
        
        //
        if (strTarget == nil) {
            strTarget = @"";
            Assert(0);
        }
        [dicInfo setObject:strTarget forKey:@"sessionId"];
        
        //
        if (strPrivatePhone == nil) {
            strPrivatePhone = @"";
        }
        [dicInfo setObject:strPrivatePhone forKey:@"pn"];
    }
    else{
        [dicInfo setObject:chatSession.sessionId forKey:@"sessionId"];
    }
 
    /* session type */
    int universalSessionType = [MutipleDeviceSynMgr getUniversalSessionType:chatSession];

    [dicInfo setObject:[NSString stringWithFormat:@"%d", universalSessionType] forKey:@"sessionType"];
    
    /* on top */
    [dicInfo setObject:[NSString stringWithFormat:@"%d", isOnTop] forKey:@"onTop"];
    
    NSString* strInfo = [dicInfo JSONRepresentationSystem];
    
    Message *msg = [Message messageWithType:MSG_TYPE_UNIVERSAL_DEVICE_SYN_NOTIFY content:strInfo data:nil session:[MyInfo myUserId] isGroupChat:NO];
    [[ServiceMgr getTP] sendMessage:msg];
    
    LogI(@"syn message(msgId:%@, sessionId:%@) on top state:%d", msg.msgId, chatSession.sessionId, isOnTop);
}
+ (void)onReceiveMessageOnTop:(Message*)msg
{
    LogI(@"onReceiveMessageOnTop");
    NSString* strInfo = msg.text;
    NSDictionary* dicInfo = [strInfo JSONValueWithSystem];
    if (!dicInfo)
    {
        return;
    }
    NSString* sessionType = [dicInfo objectForKey:@"sessionType"];
    NSString* strOnTop = [dicInfo objectForKey:@"onTop"];
    NSString* sessionId = nil;
    if (sessionType && [sessionType intValue] == enum_universal_chatsession_type_sms)
    {
        NSString* strPrivatePhone = [dicInfo objectForKey:@"pn"];
        NSString* strTarget = [dicInfo objectForKey:@"sessionId"];
        
        int64_t aSession = [strPrivatePhone longLongValue] + [strTarget longLongValue];
        sessionId = [NSString stringWithFormat:@"%lld",aSession];
    }
    else
    {
        sessionId = [dicInfo objectForKey:@"sessionId"];
    }
    LogI(@"stick on top message(sessionId = %@, sessionType = %@, onTop = %@)", sessionId, sessionType, strOnTop);
    
    if (sessionId == nil || [sessionId length] == 0 || sessionType == nil || [sessionType length] == 0 || strOnTop == nil || [strOnTop length] == 0)
    {
        return;
    }

    ChatViewSession* chatViewSession = [[ServiceMgr sessionMgr] getSessionBy:VIEW_TYPE_CHAT];

    ChatSession* chatSession = [chatViewSession getChatSession:sessionId];

    if (!chatSession)
    {
        LogE(@"chatSession(sessionId = %@) not found!", sessionId);
        return;
    }
    
    if (!chatSession.chatSet)
    {
        LogE(@"chatSet(sessionId = %@) not found!", sessionId);
        return;
    }

    [chatSession.chatSet setOnTop:[strOnTop isEqual:@"1"]];
    // save to file
    NSString* path = [NSString stringWithFormat:@"%@/%@_setting.dat", [NUtils settingDirectory], sessionId];
    Boolean ret = [NSKeyedArchiver archiveRootObject:chatSession.chatSet toFile:path];
    if (!ret)
    {
        LogE(@"save chatset for session(%@) failed!", sessionId);
        return;
    }
    [chatSession.chatSet saveOnTopInfo:sessionId];
    [[NSNotificationCenter defaultCenter] postNotificationName:LOAD_ON_TOP_AND_FAVORITE_MESSAGE object:nil];

}
@end
