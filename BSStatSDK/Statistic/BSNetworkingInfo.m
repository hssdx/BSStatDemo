//
//  BSNetworkingInfo.m
//  Beach Son Stat
//
//  Created by Beach Son Team on 8/13/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import "BSNetworkingInfo.h"
#import "BSReachability.h"
#include <ifaddrs.h>
#include <arpa/inet.h>

@implementation BSNetworkingInfo

+ (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                    
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

/**
 *  get network infomation
 *
 *  @return 'wifi' or 'wwan' or 'no'
 */
+ (NSString *)getNetworkInfo {
    BSReachability *internetReachability = [BSReachability reachabilityForInternetConnection];
    NetworkStatus netStatus = [internetReachability currentReachabilityStatus];
    switch (netStatus) {
        case NotReachable:
            return @"";
        case ReachableViaWiFi:
            return @"WIFI";
        case ReachableViaWWAN:
            return @"WWAN";
    }
}

@end
