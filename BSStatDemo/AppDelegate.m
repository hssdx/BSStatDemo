//
//  AppDelegate.m
//  BSStatDemo
//
//  Created by quanxiong on 16/5/3.
//  Copyright © 2016年 BeachSon. All rights reserved.
//

#import "AppDelegate.h"
#import "BSStatSDK.h"

@interface AppDelegate () <BSEventLoggerDelegate>

@end

@implementation AppDelegate
- (void)eventLogger:(BSEventLogger *)logger didRecordEvent:(BSEventLoggerType)type withEventType:(NSString *)eventType {
    static NSDictionary *typeToString;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        typeToString = @{@(BSEventLoggerTypeTouch):@"touch",
                         @(BSEventLoggerTypeAppear):@"view appear",
                         @(BSEventLoggerTypeDisappear):@"view disappear"};
    });
    NSLog(@"<%@, %@>", typeToString[@(type)], eventType);
}

- (void)sendCachedDataWithEventLogger:(BSEventLogger *)logger {
    NSLog(@"<%@>", logger);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    /**
     *  回调代理
     */
    [BSStatSDK setLoggerDelegate:self];
    /**
     *  开始记录
     */
    [BSStatSDK startUpRecord];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
