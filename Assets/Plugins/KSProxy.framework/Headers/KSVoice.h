//
//  KSVoice
//  Prox
//
//  Created by kaiser on 2017/2/24.
//  Copyright © 2017年 Kaiser. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * Member's role for National Room.
 */
typedef enum
{
    Emcee = 1, // member who can open microphone and say
    Audience,   // member who can only hear anchor's voice
}MemberRole;

UIKIT_EXTERN NSString *const UploadFileNotif;
UIKIT_EXTERN NSString *const SpeechToTextNotif;

@interface KSVoice : NSObject

/**
 *  初始化
 *
 */
+ (KSVoice*)shareInstance;

-(void)setAppID:(NSString *)appID appKey:(NSString *)appKey playerid:(NSString *)playerid;

-(void)pause;

-(void)resume;

#pragma MessageVoice
-(void)StartRecording;

-(void)StopRecording;

-(void)PlayRecordedFile:(NSString * )fileID;

-(void)StopPlayFile;

#pragma RealTiemVoice
-(int)joinTeamRoomWithName:(NSString *)roomName msTimeout:(int)msTimeout;

-(int)joinNationalRoomWithNameAndRole:(NSString *)roomName role:(MemberRole)role msTimeout:(int)msTimeout;

-(void)quitRoomWithName:(NSString *)roomName msTimeout:(int)msTimeout;

-(void)setMICOpen:(bool)open;

-(void)setSpeakerOpen:(bool)open;

#pragma VoiceToText
-(void)initSpeechToText;
-(void)StartSpeech;
-(void)SpeechToText:(NSString * )fileID;
@end
