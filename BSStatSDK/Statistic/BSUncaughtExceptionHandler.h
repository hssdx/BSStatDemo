//
//  UncaughtExceptionHandler.h
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/18/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString *const kUncaughtExceptionInfoKey;

@class BSUncaughtExceptionHandler;

@protocol UncaughtExceptionDelegate <NSObject>
- (void)exceptionHandler:(BSUncaughtExceptionHandler *)handler
         handleException:(NSException *)exception;
@end


@interface BSUncaughtExceptionHandler : NSObject

@property (weak, nonatomic) id<UncaughtExceptionDelegate> delegate;

+ (instancetype)sharedUncaughtExceptionHandler;
+ (NSArray *)backtraceArray;

@end