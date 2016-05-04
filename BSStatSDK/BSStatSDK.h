//
//  BSStatSDK.h
//  Beach Son Stat
//
//  Created by Beach Son Team on 7/27/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, BSEventLoggerType) {
    BSEventLoggerTypeTouch,
    BSEventLoggerTypeAppear,
    BSEventLoggerTypeDisappear
};

@class BSEventLogger;

@protocol BSEventLoggerDelegate <NSObject>

- (void)eventLogger:(BSEventLogger *)logger didRecordEvent:(BSEventLoggerType)type withEventType:(NSString *)eventType;
- (void)sendCachedDataWithEventLogger:(BSEventLogger *)logger;

@end

@interface BSStatSDK : NSObject

/**
 *  设置埋点记录代理
 *
 *  @param loggerDelegate 在记录埋点时交给代理类处理第三方(如 MiState)埋点记录
 */
+ (void)setLoggerDelegate:(id<BSEventLoggerDelegate>)loggerDelegate;

/**
 *  启动埋点收集功能，建议在设置delegate后调用
 */

+ (void)startUpRecord;

@end
