//
//  NSDate+BSTimeInterval.m
//  Beach Son Stat
//
//  Created by Beach Son Team on 8/13/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import "NSDate+BSTimeInterval.h"

@implementation NSDate(BSTimeInterval)

- (NSString *)BSTimeIntervalString {
    return [NSString stringWithFormat:@"%lu",
            (unsigned long)([self timeIntervalSince1970])];
}

- (NSString *)BSTimeIntervalStringForMS {
    return [NSString stringWithFormat:@"%lu",
            (unsigned long)([self timeIntervalSince1970] * 1000.0)];
}

- (unsigned long)BSTimeInterval {
    return (unsigned long)([self timeIntervalSince1970]);
}

- (unsigned long)BSTimeIntervalForMS {
    return (unsigned long)([self timeIntervalSince1970] * 1000.0);
}

@end
