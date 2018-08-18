//
//  KSShare.h
//  KSShare
//
//  Created by Kaiser on 2017/5/17.
//  Copyright © 2017年 RW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

UIKIT_EXTERN NSString *const KSShareNotif;

typedef NS_ENUM(NSInteger, KSQQSharingSendResult) {
    KSQQAPISENDSUCESS = 0,
    KSQQAPIQQNOTINSTALLED = 1,
    KSQQAPIQQNOTSUPPORTAPI = 2,
    KSQQAPIMESSAGETYPEINVALID = 3,
    KSQQAPIMESSAGECONTENTNULL = 4,
    KSQQAPIMESSAGECONTENTINVALID = 5,
    KSQQAPIAPPNOTREGISTED = 6,
    KSQQAPIAPPSHAREASYNC = 7,
    KSQQAPIQQNOTSUPPORTAPI_WITH_ERRORSHOW = 8,
    KSQQAPISENDFAILD = 9,
    KSQQAPISHAREDESTUNKNOWN = 10, //未指定分享到QQ或TIM
    
    KSQQAPITIMNOTINSTALLED = 11, //TIM未安装
    KSQQAPITIMNOTSUPPORTAPI = 12, // TIM api不支持
    //qzone分享不支持text类型分享
    KSQQAPIQZONENOTSUPPORTTEXT = 13,
    //qzone分享不支持image类型分享
    KSQQAPIQZONENOTSUPPORTIMAGE = 14,
    //当前QQ版本太低，需要更新至新版本才可以支持
    KSQQAPIVERSIONNEEDUPDATE = 15,
    KSTIMAPIVERSIONNEEDUPDATE = 16
};

typedef NS_ENUM(NSInteger, KSShareType) {
    KSShareType_Wechat = 1,
    KSShareType_QQ,
    KSShareType_QQZone,
    KSShareType_SinaWeibo,
    KSShareType_Unkown
};

@protocol KSShareSDKDelegate <NSObject>
/**
 *  分享回调
 *
 *  @param reqType 类型
 *  @param userInfo   用户信息
 *  @param success    成功失败
 */
- (void)shareSDKShareResponse:(KSShareType)reqType WithInfo:(NSDictionary *)userInfo Success:(BOOL)success;

@optional
/**
 *  QQ分享发送结果
 *
 *  @param resultCode 结果状态码
 */
- (void)handleSendQQShareResult:(KSQQSharingSendResult)resultCode;

@end

@interface KSShare : NSObject

+ (instancetype)shareInstance;

/**
 *	是否安装微信
 */
+ (BOOL)isWeChatInstalled;

/**
 *	是否安装微信
 */
+ (BOOL)isQQInstalled;

/**
 *	是否安装新浪微博
 */
+ (BOOL)isWeiboInstalled;

/**
 *	微信平台初始化接口
 */
-(void)initializeWechatWithAppId:(NSString *)appid appSecret:(NSString *)appSecret;

/**
 *	qq初始化接口
 */
-(void)initializeQQWithAppId:(NSString *)appid appSecret:(NSString *)appSecret;

/**
 *	sina微博初始化接口
 */
-(void)initializeSinaWeiboWithAppId:(NSString *)appid appSecret:(NSString *)appSecret redirectUri:(NSString *)redirectUri;

/**
 *  分享微信好友
 *
 *  @param message 分享内容
 *  @param title   分享回调
 *  @param url   分享链接
 *  @param image   分享图片
 */
-(void)sendWechatMessage:(NSString *)message title:(NSString *)title url:(NSString *)url image:(UIImage *)image;

/**
 *  分享微信朋友圈
 *
 *  @param message 分享内容
 *  @param title   分享回调
 *  @param url   分享链接
 *  @param image   分享图片
 */
-(void)sendWechatFriends:(NSString *)message title:(NSString *)title url:(NSString *)url image:(UIImage *)image;

/**
 *  分享QQ Zone
 *
 *  @param message  分享内容
 *  @param title    分享回调
 *  @param url      分享链接
 *  @param image    分享图片
 */
- (void)sendQQZone:(NSString *)message title:(NSString *)title url:(NSString *)url image:(UIImage *)image;

/**
 *  分享QQ
 *
 *  @param message  分享内容
 *  @param title    分享回调
 *  @param url      分享链接
 *  @param image    分享图片
 */
- (void)sendQQ:(NSString *)message title:(NSString *)title url:(NSString *)url image:(UIImage *)image;

/**
 *  分享新浪微博
 *
 *  @param message  分享内容
 *  @param title    分享回调
 *  @param url      分享链接
 *  @param image    分享图片
 */
- (void)sendSinaWeibo:(NSString *)message title:(NSString *)title url:(NSString *)url image:(UIImage *)image;
/**
 *  @brief 通过URL启动第三方应用时传递的数据
 *
 *  @param url       启动第三方应用的URL
 *  @param pDelegate 用于接收SDK触发消息的委托
 *
 *  @return 返回布尔值
 */
+ (BOOL)handleOpenURL:(NSURL *)url delegate:(id)pDelegate;

/**
 *  判断是否为启动微信的URL
 */
+ (NSString *)wechatForHandleShareURLPrefx;
+ (NSString *)wechatForHandlepayURLPrefx;

@end
