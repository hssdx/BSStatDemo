//
//  UncaughtExceptionHandler.h
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/18/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import "BSUncaughtExceptionHandler.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>

NSString *const kUncaughtExceptionInfoKey = @"UncaughtExceptionInfoKey";

static NSString *const kUncaughtExceptionSignalException = @"UncaughtExceptionSignalException";
static NSString *const kUncaughtExceptionSignalKey = @"UncaughtExceptionSignalKey";

static volatile int32_t kUncaughtExceptionCount = 0;
static const int32_t kUncaughtExceptionMaximum = 10;

static const NSInteger kUncaughtExceptionSkipAddressCount = 1;
static const NSInteger kUncaughtExceptionReportAddressCount = 5;

#pragma mark - Global Exception Function

void performSelectorWithException(NSException *exception);

void HandleException(NSException *exception){
    int32_t exceptionCount = OSAtomicIncrement32(&kUncaughtExceptionCount);
    if (exceptionCount > kUncaughtExceptionMaximum){
        return;
    }
    
    NSArray *fullCallStack = [exception callStackSymbols];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo setObject:fullCallStack forKey:kUncaughtExceptionInfoKey];
    
    NSException *newException = [NSException exceptionWithName:[exception name]
                                                       reason:[exception reason]
                                                     userInfo:userInfo];
    performSelectorWithException(newException);
}

void SignalHandler(int signal){
    int32_t exceptionCount = OSAtomicIncrement32(&kUncaughtExceptionCount);
    if (exceptionCount > kUncaughtExceptionMaximum){
        return;
    }
    
    NSMutableDictionary *userInfo =[NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal]
                                                                      forKey:kUncaughtExceptionSignalKey];
    NSArray *callStack = [BSUncaughtExceptionHandler backtraceArray];
    [userInfo setObject:callStack forKey:kUncaughtExceptionInfoKey];
    
    NSException *newException = [NSException exceptionWithName:kUncaughtExceptionSignalException
                                                        reason:@"Signal was raised"
                                                      userInfo:userInfo];
    performSelectorWithException(newException);
}

#pragma mark - UncaughtExceptionHandler

@implementation BSUncaughtExceptionHandler

+ (instancetype)sharedUncaughtExceptionHandler{
    static BSUncaughtExceptionHandler *sharedHandler = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedHandler = [[BSUncaughtExceptionHandler alloc] init];
    });
    return sharedHandler;
}

- (id)init{
    self = [super init];
    if (self){
        NSSetUncaughtExceptionHandler(&HandleException);
        signal(SIGABRT, SignalHandler);
        signal(SIGILL, SignalHandler);
        signal(SIGSEGV, SignalHandler);
        signal(SIGFPE, SignalHandler);
        signal(SIGBUS, SignalHandler);
        signal(SIGPIPE, SignalHandler);
        return self;
    }
    return nil;
}

- (void)dealloc{
    signal(SIGABRT, SIG_DFL);
    signal(SIGBUS, SIG_DFL);
    signal(SIGFPE, SIG_DFL);
    signal(SIGILL, SIG_DFL);
    signal(SIGPIPE, SIG_DFL);
    signal(SIGSEGV, SIG_DFL);
    NSSetUncaughtExceptionHandler(NULL);
}

+ (NSArray *)backtraceArray{
	 void* callstack[128];
	 int frames = backtrace(callstack, 128);
	 char **strs = backtrace_symbols(callstack, frames);
	 
	 NSMutableArray *backtrace = [NSMutableArray array];
	 for (
	 	NSInteger i = kUncaughtExceptionSkipAddressCount;
	 	i < kUncaughtExceptionSkipAddressCount +
			kUncaughtExceptionReportAddressCount;
		i++)
     {
	 	[backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
	 }
    
	 free(strs);
	 return [backtrace copy];
}

- (void)handleException:(NSException *)exception{
    if (self.delegate)
        [self.delegate exceptionHandler:self handleException:exception];
    
	if ([[exception name] isEqual:kUncaughtExceptionSignalException]){
		kill(getpid(), [[[exception userInfo] objectForKey:kUncaughtExceptionSignalKey] intValue]);
	}else{
		[exception raise];
	}
}

@end

void performSelectorWithException(NSException *exception){
    if (!exception)
        return;
    
    BSUncaughtExceptionHandler *exceptionHandler = [BSUncaughtExceptionHandler sharedUncaughtExceptionHandler];
    [exceptionHandler performSelectorOnMainThread:@selector(handleException:)
                                       withObject:exception
                                    waitUntilDone:YES];
}

