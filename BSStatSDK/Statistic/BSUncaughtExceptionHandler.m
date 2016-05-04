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

NSString *const kBSUncaughtExceptionInfoKey = @"UncaughtExceptionInfoKey";

static NSString *const kBSUncaughtExceptionSignalException = @"UncaughtExceptionSignalException";
static NSString *const kBSUncaughtExceptionSignalKey = @"UncaughtExceptionSignalKey";

static volatile int32_t kBSUncaughtExceptionCount = 0;
static const int32_t kBSUncaughtExceptionMaximum = 10;

static const NSInteger kBSUncaughtExceptionSkipAddressCount = 1;
static const NSInteger kBSUncaughtExceptionReportAddressCount = 5;

#pragma mark - Global Exception Function

void BSPerformSelectorWithException(NSException *exception);

void BSHandleException(NSException *exception){
    int32_t exceptionCount = OSAtomicIncrement32(&kBSUncaughtExceptionCount);
    if (exceptionCount > kBSUncaughtExceptionMaximum){
        return;
    }
    
    NSArray *fullCallStack = [exception callStackSymbols];
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithDictionary:[exception userInfo]];
    [userInfo setObject:fullCallStack forKey:kBSUncaughtExceptionInfoKey];
    
    NSException *newException = [NSException exceptionWithName:[exception name]
                                                       reason:[exception reason]
                                                     userInfo:userInfo];
    BSPerformSelectorWithException(newException);
}

void BSSignalHandler(int signal){
    int32_t exceptionCount = OSAtomicIncrement32(&kBSUncaughtExceptionCount);
    if (exceptionCount > kBSUncaughtExceptionMaximum){
        return;
    }
    
    NSMutableDictionary *userInfo =[NSMutableDictionary dictionaryWithObject:[NSNumber numberWithInt:signal]
                                                                      forKey:kBSUncaughtExceptionSignalKey];
    NSArray *callStack = [BSUncaughtExceptionHandler backtraceArray];
    [userInfo setObject:callStack forKey:kBSUncaughtExceptionInfoKey];
    
    NSException *newException = [NSException exceptionWithName:kBSUncaughtExceptionSignalException
                                                        reason:@"Signal was raised"
                                                      userInfo:userInfo];
    BSPerformSelectorWithException(newException);
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
        NSSetUncaughtExceptionHandler(&BSHandleException);
        signal(SIGABRT, BSSignalHandler);
        signal(SIGILL, BSSignalHandler);
        signal(SIGSEGV, BSSignalHandler);
        signal(SIGFPE, BSSignalHandler);
        signal(SIGBUS, BSSignalHandler);
        signal(SIGPIPE, BSSignalHandler);
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
	 	NSInteger i = kBSUncaughtExceptionSkipAddressCount;
	 	i < kBSUncaughtExceptionSkipAddressCount +
			kBSUncaughtExceptionReportAddressCount;
		i++)
     {
	 	[backtrace addObject:[NSString stringWithUTF8String:strs[i]]];
	 }
    
	 free(strs);
	 return [backtrace copy];
}

- (void)BSHandleException:(NSException *)exception{
    if (self.delegate)
        [self.delegate exceptionHandler:self handleException:exception];
    
	if ([[exception name] isEqual:kBSUncaughtExceptionSignalException]){
		kill(getpid(), [[[exception userInfo] objectForKey:kBSUncaughtExceptionSignalKey] intValue]);
	}else{
		[exception raise];
	}
}

@end

void BSPerformSelectorWithException(NSException *exception){
    if (!exception)
        return;
    
    BSUncaughtExceptionHandler *exceptionHandler = [BSUncaughtExceptionHandler sharedUncaughtExceptionHandler];
    [exceptionHandler performSelectorOnMainThread:@selector(BSHandleException:)
                                       withObject:exception
                                    waitUntilDone:YES];
}

