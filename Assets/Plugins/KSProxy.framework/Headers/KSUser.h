//
//  KSUser.h
//  Prox
//
//  Created by kaiser on 2017/2/24.
//  Copyright © 2017年 Kaiser. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSUser : NSObject

+ (instancetype)shareInstance;

// 用户UID
@property (nonatomic, copy) NSString *UID;
// openID，用于服务器验证
@property (nonatomic, copy) NSString *openID;
// 用户名
@property (nonatomic, copy) NSString *userName;

@end
