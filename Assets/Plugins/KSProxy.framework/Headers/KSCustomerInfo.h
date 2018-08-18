//
//  KSIssueInfo.h
//  KSService
//
//  Created by kaiser on 2017/4/10.
//  Copyright © 2017年 kaiser. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KSCustomerInfo : NSObject

/*
 *  客服系统用户信息
 */

/*
 *  服务器名称
 */
@property (nonatomic, copy) NSString *serverName;
/*
 *  服务器ID
 */
@property (nonatomic, copy) NSString *serverId;
/*
 *  游戏的角色名称
 */
@property (nonatomic, copy) NSString *roleName;
/*
 *  游戏的角色Id
 */
@property (nonatomic, copy) NSString *roleId;

@end
