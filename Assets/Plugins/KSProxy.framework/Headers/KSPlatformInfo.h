//
//  KSPlatformInfo.h
//  KSProxy
//
//  Created by kaiser on 2017/6/26.
//  Copyright © 2017年 jaime. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM (NSInteger,KSPlatformNetInfo){
    KSPlatformNet2G = 1,
    KSPlatformNet3G,
    KSPlatformNet4G,
    KSPlatformNetWifi,
    KSPlatformNetUnkown
};

@interface KSPlatformInfo : NSObject

+ (instancetype)shareInstance;
/**
 * 获取AppKey
 *
 */
- (NSString *)getAppKey;

/**
 * 获取AppID
 *
 */
- (NSString *)getAppID;

/**
 * 获取渠道号
 *
 */
- (NSString *)getChannelID;

/**
 * 获取子渠道号
 *
 */
- (NSString *)getAdChannelID;

/**
 * 获取sdk版本号
 *
 */
- (NSString *)getSDKVersion;

/**
 * 获取设备型号
 *
 */
- (NSString *)getDeviceName;

/**
 *	获取分辨率 w*h
 *
 */
- (NSString *)getResolution;

/**
 *  获取ip
 *
 */
- (NSString *)getIPAddress:(BOOL)preferIPv4;

/**
 *  获取手机运营商
 *
 */
- (NSString *)getTelecom;

/**
 *  获取网络状态
 *
 */
- (KSPlatformNetInfo)getNetInfo;

/**
 * 获取唯一标志（设备号）
 *
 */
- (NSString *)getIdfv;

@end
