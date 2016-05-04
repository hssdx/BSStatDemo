//
//  BSStatSDK.m
//  Beach Son Stat
//
//  Created by Beach Son Team on 7/27/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import "BSStatSDK.h"
#import "BSEventLogger.h"

@implementation BSStatSDK

+ (void)setLoggerDelegate:(id<BSEventLoggerDelegate>)loggerDelegate {
    [[BSEventLogger sharedEventLogger] setLoggerDelegate:loggerDelegate];
    
}

+ (void)startUpRecord {
    [[BSEventLogger sharedEventLogger] startDaemon];
}

@end
