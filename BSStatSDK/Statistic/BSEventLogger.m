//
//  BSEventLogger.h
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/13/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BSEventLogger.h"
#import "UIResponder+BSEventInterceptor.h"
#import "BSStatisticModel.h"
#import "BSUncaughtExceptionHandler.h"
#import "BSStatisticCacheManager.h"
#import "NSDate+BSTimeInterval.h"

static NSString *const kEventLoggerAppear = @"appeared";
static NSString *const kEventLoggerDisappear = @"disappeared";
static NSString *const kEventLoggerTouch = @"touched";
static const NSTimeInterval kDefaultTimeInterval = 1 * 60 * 60;

@interface BSEventLogger() <UncaughtExceptionDelegate>
@property (strong, nonatomic) BSStatisticModel *statisticModel;
@property (strong, nonatomic) BSUncaughtExceptionHandler *exceptionHandler;
@property (strong, nonatomic) BSStatisticCacheManager *statisticCacheManager;

@property (copy, nonatomic) NSDate *startDate;
@end

@implementation BSEventLogger

- (instancetype)init{
    self = [super init];
    if (self){
        _statisticModel = [[BSStatisticModel alloc]init];
        _timeInterval = kDefaultTimeInterval;
        _statisticCacheManager = [BSStatisticCacheManager sharedStatisticCacheManager];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self
                   selector:@selector(handleApplicationNotification:)
                       name:UIApplicationWillTerminateNotification
                     object:nil];
        
        [center addObserver:self
                   selector:@selector(handleApplicationNotification:)
                       name:UIApplicationDidReceiveMemoryWarningNotification
                     object:nil];
        
        [center addObserver:self
                   selector:@selector(handleApplicationNotification:)
                       name:UIApplicationWillEnterForegroundNotification
                     object:nil];
        
        [center addObserver:self
                   selector:@selector(handleApplicationNotification:)
                       name:UIApplicationDidEnterBackgroundNotification
                     object:nil];
        
        self.exceptionHandler = [BSUncaughtExceptionHandler sharedUncaughtExceptionHandler];
        self.exceptionHandler.delegate = self;

        self.startDate = [NSDate date];
        return self;
    }
    return nil;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleApplicationNotification:(NSNotification*)aNotification{
    if (aNotification.name == UIApplicationWillEnterForegroundNotification) {
        self.startDate = [NSDate date];
        [self tryToSendCachedStatisticData];
    } else {
        [self.statisticModel addHistoryWithStartDate:self.startDate
                                             endDate:[NSDate date]];
        [self cacheStatisticData];
    }
}

+ (instancetype)sharedEventLogger {
    static BSEventLogger *sharedLogger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLogger = [[BSEventLogger alloc] init];
    });
    return sharedLogger;
}

- (void)exceptionHandler:(BSUncaughtExceptionHandler *)handler
         handleException:(NSException *)exception{
    NSParameterAssert(exception && exception.userInfo);
    
    NSArray *errorInfoArray = [exception.userInfo objectForKey:kUncaughtExceptionInfoKey];
    NSMutableString *errorInfo = [exception.name mutableCopy];
    [errorInfo appendString:exception.reason];
    [errorInfo appendString:[errorInfoArray componentsJoinedByString:@""]];
    
    [self.statisticModel addErrorInfo:errorInfo];
    [self cacheStatisticData];
}

- (void)logEvent:(BSEventLoggerType)type forObject:(NSObject *)object{
    if (![self checkLogConditionForObject:object])
        return;
    NSString *eventType = [object performSelector:@selector(eventKey)];
    if (!eventType || [eventType isEqualToString:@""]){
        return;
    }
    if ([object isKindOfClass:[UIViewController class]]) {
        UIViewController *vc = (id)object;
        eventType = [eventType stringByAppendingFormat:@"(%@)", vc.title];
    }
    NSString *dateString = [[NSDate date] BSTimeIntervalStringForMS];
    
    [self.statisticModel addFlowEventWithKey:eventType value:dateString];
    
    if (self.loggerDelegate) {
        [self.loggerDelegate eventLogger:self
                          didRecordEvent:type
                           withEventType:eventType];
    }
}

- (void)logEventWithkey:(NSString *)key value:(NSString *)value forObject:(NSObject *)object{
    if (![self checkLogConditionForObject:object])
        return;
    //TODO
}

- (BOOL)checkLogConditionForObject:(NSObject *)object{
    if (![object isKindOfClass:[UIResponder class]])
        return NO;
    
    UIResponder *responder = (UIResponder *)object;
    if (!responder.needTelemetry)
        return NO;
    return YES;
}

- (NSString *)stringWithEventType:(BSEventLoggerType)type{
    NSString *result;
    switch (type) {
        case BSEventLoggerTypeTouch:
            result = kEventLoggerTouch;
            break;
        case BSEventLoggerTypeAppear:
            result = kEventLoggerAppear;
            break;
        case BSEventLoggerTypeDisappear:
            result = kEventLoggerDisappear;
            break;
    }
    return result;
}

- (void)cacheStatisticData{
    [self.statisticCacheManager storeStatisticModel:self.statisticModel];
    [self.statisticModel reset];
}

- (void)tryToSendCachedStatisticData{
    if ([self.statisticCacheManager conformsToProtocol:@protocol(MeterCacheSender)])
        [self.statisticCacheManager sendCachedData];
    if (self.loggerDelegate) {
        [self.loggerDelegate sendCachedDataWithEventLogger:self];
    }
}

- (void)startDaemon{
    [self performSelectorInBackground:@selector(daemonEntry:) withObject:@(self.timeInterval)];
}

- (void)daemonEntry:(NSNumber *)timerInterval{
    @autoreleasepool {
        NSTimer *timer = [NSTimer timerWithTimeInterval:timerInterval.floatValue target:self
                                               selector:@selector(timerRoutine) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        [timer performSelector:@selector(fire) withObject:nil afterDelay:3];
        [[NSRunLoop currentRunLoop] run];
    }
}

- (void)timerRoutine{
    [self tryToSendCachedStatisticData];
}

@end
