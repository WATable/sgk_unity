//
//  KSProxy.h
//  Prox
//
//  Created by Kaiser on 11/1/2017.
//  Copyright © 2017年 Kaiser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "KSPay.h"
#import "KSCustomerInfo.h"

#pragma mark - 监听事件
UIKIT_EXTERN NSString *const KSLoginNotif;
UIKIT_EXTERN NSString *const KSLogoutNotif;
UIKIT_EXTERN NSString *const KSPaymentNotif;

@interface KSProxy : NSObject

#pragma mark - 单例
/**
 *  单例
 *
 */
+ (instancetype)shareInstance;

#pragma mark - 初始化
/**
 *  初始化，配置app参数
 *
 *  @param appid 凯撒应用id
 *  @param appkey 凯撒应用key
 */
- (void)initWithConfig:(NSString *)appid appkey:(NSString *)appkey complete:(void (^)(void))complete;

#pragma mark - 设置root根视图
/**
 *  设置rootViewController,在登录前设置
 *
 *  @param viewController 指定根视图
 */
- (void)setRootViewController:(UIViewController *)viewController;

/**
 *  获取rootViewController
 *
 */
- (UIViewController *)getRootViewController;

#pragma mark - 业务逻辑
/**
 *  登录
 *  
 */
- (void)login;

/**
 *  登出
 *
 */
- (void)logout;

/**
 *  切换账号
 *
 */
- (void)changeAccount;

/**
 *  支付
 *
 *  @param info   KSPay实例，支付数据模型
 */
- (void)pay:(KSPay *)info;

/**
 *  显示用户中心
 *
 */
- (void)initUserCenter:(void (^)(void))complete;

/**
 *  客服系统
 *  @param info 客服数据模型
 */
- (void)initCustomServiceViewWithConfigInfo:(KSCustomerInfo *)info;

/**
 *  微社区
 */
- (void)initCommunity;

#pragma mark - 广告
/**
 *  注册热云广告
 *
 *  @param appKey 热云应用key
 */
- (void)registADkey:(NSString *)appKey;

#pragma mark - 消息推送
/**
 *  注册友盟推送
 *
 *  @param appKey 友盟应用key
 */
- (void)registPushAppkey:(NSString *)appKey;

/**
 *  收到推送消息
 *
 *  @param userInfo 消息
 */
- (void)didReceiveRemoteNotification:(NSDictionary *)userInfo;

#pragma mark -- 自有支付回调
/**
 *  银联支付结果
 *
 *  @param url          银联启动第三方应用时传递过来的URL
 *  @param complete     支付结果回调
 */
- (void)payResult:(NSURL *)url completion:(void(^)(NSString *code, NSDictionary * data))complete;

/**
 *  @brief 通过URL启动第三方应用时传递的数据,微信分享需要在info.plist中的URL Types里填写tencentApiIdentifier和微信id
 *  并且添加scheme白名单 LSApplicationQueriesSchemes
 *  @param url       启动第三方应用的URL
 *
 *  @return 返回布尔值
 */
+ (BOOL)handleOpenURL:(NSURL *)url;

@end
