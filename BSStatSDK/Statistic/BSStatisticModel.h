//
//  BSStatisticModel.h
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/13/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BSStatisticBaseModel.h"

#pragma mark - StatisticModel

@interface BSStatisticModel : BSStatisticBaseModel
@property (copy, nonatomic) NSString *screenInfo;
@property (copy, nonatomic) NSString *networkInfo;
@property (copy, nonatomic) NSString *version;
@property (copy, nonatomic) NSString *deviceModel;
@property (copy, nonatomic) NSString *sign;
@property (copy, nonatomic) NSString *timeZone;
@property (copy, nonatomic) NSString *systemVersion;
@property (copy, nonatomic) NSString *userip;
@property (copy, nonatomic) NSString *uuid;
@property (copy, nonatomic) NSString *packageName;

@property (strong, nonatomic) NSNumber *protocol;
@property (strong, nonatomic) NSNumber *secretID;
@property (strong, nonatomic) NSNumber *time;

//None JsonData fields
@property (copy, nonatomic) NSString *accountName;

- (void)addFlowEventWithKey:(NSString *)key value:(NSString *)value;
- (void)addErrorInfo:(NSString *) errorInfo;
- (void)addHistoryWithStartDate:(NSDate *)startDate endDate:(NSDate *)endDate;

- (void)reset;
@end
