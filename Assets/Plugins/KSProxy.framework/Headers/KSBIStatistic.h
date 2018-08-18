//
//  KSBIStatistic.h
//  kaiserSDK
//
//  Created by Kaiser on 17/1/10.
//  Copyright © 2017年 RW. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface KSBIStatistic : NSObject

// BI统计

/**
 *   程序启动时调用
 *
 *  一般在- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions内调用一次即可
 *  !!!一定要调用，否则后面无法上报,只能调用一次
 *  @param appId         在我们网站上创建游戏时分配的appId,用于标识这款游戏. 注意保密!
 *
 */
+ (void)onStart:(NSString *)appId withReportMode:(int)model;

/**
 *  设置开启Log
 *
 *  (1)打印流程信息
 *  (2)错误提示
 *  默认关闭，开发调试时打开，请在正式发布前关闭。
 */
+(void)setDebugMode:(BOOL)model;

/**
 * 创建游戏角色
 * @param uId    平台ID
 * @param gender        用户性别,  0  未知,默认值, 1   男性, 2    女性
 */
+ (void)loginAccountWithUId:(NSString *)uId gender:(NSInteger)gender;

/**
 * 创建游戏角色
 * @param platformId    平台ID
 * @param accountId     游戏账号ID
 * @param roleId        角色ID
 * @param server        游戏区服
 * @param ext           扩展字段,没有则填nil
 */
+ (void)createGameRoleWithPlatformId:(NSString *)platformId accountId:(NSString *)accountId roleId:(NSString *)roleId gameServer:(int)server extInfo:(NSString *)ext;

/**
 * 角色登录, 登录后必须调用，否则无法上报
 * @param uId           平台ID
 * @param accountId     游戏账号ID
 * @param level         角色等级
 * @param roleId        角色ID
 * @param server        游戏区服
 * @param ext           扩展字段,没有则填nil
 */
+ (void)loginGameRoleWithPlatformId:(NSString *)uId accountId:(NSString *)accountId level:(NSString *)level roleId:(NSString *)roleId gameServer:(int)server vipLevel:(int)vipLevel power:(NSString *)power extInfo:(NSString *)ext;


/**
 * 支付
 * @param gameOrder 游戏订单号，即cp的订单号
 * @param payOrder 支付订单号
 * @param moneyType 货币类型
 * @param moneyAmount 支付金额
 * @param payType 支付方式
 * @param goodsName 商品名称
 * @param ext 扩展字段
 */
+ (void)paymentWithGameOrder:(NSString *)gameOrder payOrder:(NSString *)payOrder moneyType:(NSInteger)moneyType moneyAmount:(double)moneyAmount payType:(NSInteger)payType goodsName:(NSString *)goodsName extInfo:(NSString *)ext;
// ---------------- *** ---------------------
/**
 * 上报任务开始
 * @param taskId        任务id
 * @param taskType      任务类型,根据游戏方配置定义,需提前提供配置表,如(1-主线,2-支线)
 * @param ext           扩展字段,没有则填nil
 */
+ (void)reportGameTaskWithTaskId:(int)taskId taskType:(int)taskType extInfo:(NSString *)ext;

/**
 * 上报任务结束
 * @param taskId        任务id
 * @param taskType      任务类型,根据游戏方配置定义,需提前提供配置表,如(1-主线,2-支线)
 * @param duration      任务时长
 * @param isSuccess     0-任务失败，1-任务完成
 * @param reason        任务失败原因id，需提前提供配置表，确认id对应的中文描述
 * @param ext           扩展字段,没有则填nil
 */
+ (void)reportGameTaskEndWithTaskId:(int)taskId taskType:(int)taskType duration:(int)duration isSuccess:(BOOL)isSuccess reason:(NSString *)reason extInfo:(NSString *)ext;

/**
 * 上报游戏关卡开始
 * @param missionId     关卡id
 * @param missionType   关卡类型,根据游戏方配置定义,需提前提供配置表,如(1-主线,2-副本)
 * @param duration      消耗时长
 * @param isSuccess     0-关卡失败，1-关卡完成
 * @param reason        关卡失败原因id,需提前提供配置表，确认id对应的中文描述
 * @param ext           扩展字段,没有则填nil
 */
+ (void)reportGameMissionWithMissionId:(int)missionId missionType:(int)missionType duration:(int)duration isSuccess:(BOOL)isSuccess reason:(NSString *)reason extInfo:(NSString *)ext;

/**
 * 上报游戏角色升级
 * @param interval       升级时长
 * @param startLevel     升级前等级
 * @param nowLevel          升级后等级
 * @param ext            扩展字段,没有则填nil
 */
+ (void)reportedGameRoleLevelUp:(int)interval startLevel:(int)startLevel nowLevel:(int)nowLevel extInfo:(NSString *)ext;

/**
 * 上报游戏虚拟币
 * @param coinType      虚拟币类型,根据游戏方配置定义,需提前提供配置表,如(0-元宝,1-金币)
 * @param coinNum       消耗／获得 虚拟币的数量
 * @param totalCoin     消耗／获得虚拟币后虚拟币总数量
 * @param type          0-消耗,1-购买,2-游戏玩法获得
 * @param reason        货币流动原因id，需提前提供配置表，确认id对应的中文描述
 * @param ext           扩展字段,没有则填nil
 */
+ (void)reportGameCoinWithCoinType:(NSString *)coinType coinNum:(double)coinNum totalCoin:(double)totalCoin type:(NSString *)type reason:(int)reason  extInfo:(NSString *)ext;

/**
 * 上报游戏道具获得
 * @param itemType      道具类型id,根据游戏方配置定义,需提前提供配置表
 * @param itemNum       获得道具的数量
 * @param itemId        道具id
 * @param coinNum       道具所消耗虚拟币数量
 * @param coinType      道具所消耗虚拟币类型
 * @param reason        道具获得原因id,需提前提供配置表，确认id对应的中文描述
 * @param ext           扩展字段,没有则填nil
 */
+ (void)reportGameItemGetWithItemType:(NSString *)itemType itemNum:(int)itemNum itemId:(int)itemId coinNum:(int)coinNum coinType:(int)coinType reason:(NSString *)reason extInfo:(NSString *)ext;

/**
 * 上报游戏道具消耗
 * @param itemType      道具类型id,根据游戏方配置定义,需提前提供配置表
 * @param itemNum       获得道具的数量
 * @param itemId        道具id
 * @param mp            消费点，玩家当前进行的最后一个关卡id
 * @param tp            任务标识，玩家当前进行的最后一个主线任务id
 * @param reason        道具消耗的途径id,需提前提供配置表，确认id对应的中文描述
 * @param ext           扩展字段,没有则填nil
 */
+ (void)reportGameItemConsumeWithItemType:(NSString *)itemType itemNum:(int)itemNum itemId:(int)itemId mp:(NSString*)mp tp:(NSString*)tp reason:(NSString *)reason extInfo:(NSString *)ext;

/**
 * 上报活动
 * @param activityId    活动id
 * @param activityType  活动类型
 * @param ext           扩展字段,没有则填nil
 */
+ (void)reportGameActivityBeginWithActivityId:(int)activityId activityType:(int)activityType extInfo:(NSString *)ext;

/**
 * 上报活动结束
 * @param activityId    活动id
 * @param activityType  活动类型
 * @param duration      活动耗时
 * @param isSuccess    0-活动失败，1-活动完成
 * @param reason        活动失败原因id,需提前提供配置表，确认id对应的中文描述
 * @param ext            扩展字段,没有则填nil
 */
+ (void)reportGameActivityEndWithActivityId:(int)activityId activityType:(int)activityType duration:(int)duration isSuccess:(BOOL)isSuccess reason:(NSString *)reason extInfo:(NSString *)ext;

/**
 * 上报玩法
 * @param playId        玩法id
 * @param playType      玩法类型
 * @param ext           扩展字段,没有则填nil
 */
+ (void)reportGamePlayBeginWithPlayId:(int)playId playType:(int)playType extInfo:(NSString *)ext;

/**
 * 上报玩法结束
 * @param playId        玩法id
 * @param playType      玩法类型
 * @param duration      玩法耗时
 * @param isSuccess     0-失败，1-完成
 * @param reason        活动失败原因id,需提前提供配置表，确认id对应的中文描述
 * @param ext           扩展字段,没有则填nil
 */
+ (void)reportGameplayEndWithPlayId:(int)playId playType:(int)playType duration:(int)duration isSuccess:(BOOL)isSuccess reason:(NSString *)reason extInfo:(NSString *)ext;

@end
