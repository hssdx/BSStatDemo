//
//  NSDate+BSTimeInterval.h
//  Beach Son Stat
//
//  Created by Beach Son Team on 8/13/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate(BSTimeInterval)

- (NSString *)BSTimeIntervalString;
- (NSString *)BSTimeIntervalStringForMS;
- (unsigned long)BSTimeInterval;
- (unsigned long)BSTimeIntervalForMS;

@end
