//
//  KSPay.h
//  Prox
//
//  Created by kaiser on 2017/2/27.
//  Copyright © 2017年 Kaiser. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,KSPayResult) {
    KSPayResult_Success     = 1,
    KSPayResult_Fail,
    KSPayResult_Cancel
};

@interface KSPay : NSObject

@property (nonatomic, copy) NSString *cp_orderno;   //游戏商品订单号
@property (nonatomic, copy) NSString *product_id;   //订单ID
@property (nonatomic, copy) NSString *price;        //商品价格（元）
@property (nonatomic, copy) NSString *project;      //商品名称（如：50钻石）
@property (nonatomic, copy) NSString *ext_info;     //透传字段，供游戏cp使用，回调时会原样返回
@property (nonatomic, copy) NSString *rid;          // 游戏角色ID
@property (nonatomic, copy) NSString *level;        // 角色等级
@property (nonatomic, copy) NSString *serverId;     // 服务器ID
@property (nonatomic, copy) NSString *uid;          // 游戏 uid
@property (nonatomic, copy) NSString *desc;         // 商品描述

@end
