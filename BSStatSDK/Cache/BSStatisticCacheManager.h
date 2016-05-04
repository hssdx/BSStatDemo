//
//  BSStatisticCacheManager.h
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 6/8/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BSMeterCache.h"

@class BSStatisticModel;

@interface BSStatisticCacheManager : MeterCacheManagerBase<MeterCacheSender>

+ (instancetype)sharedStatisticCacheManager;

- (void)storeStatisticModel:(BSStatisticModel *)statisticModel;

@end
