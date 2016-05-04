//
//  BSEventLogger.h
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/13/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BSStatSDK.h"

@interface BSEventLogger : NSObject

@property (assign, nonatomic) NSTimeInterval timeInterval;
@property (weak, nonatomic) id<BSEventLoggerDelegate> loggerDelegate;

+ (instancetype)sharedEventLogger;
- (void)startDaemon;

- (void)logEvent:(BSEventLoggerType)type forObject:(NSObject *)object;
- (void)logEventWithkey:(NSString *)key value:(NSString *)value forObject:(NSObject *)object;

@end
