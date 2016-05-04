//
//  BSMeterCache.h
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/25/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma mark - MeterCacheSender

@protocol MeterCacheSender <NSObject>
@required
- (void)sendCachedData;
- (BOOL)needSending;
@end

#pragma mark - MeterCacheSender

@interface BSMeterCache : NSObject

@property (assign, nonatomic) NSInteger maxCacheAge;
@property (assign, nonatomic) BOOL needsCleanInBackground;
@property (copy, nonatomic, readonly) NSString *diskCachePath;
@property (strong, nonatomic, readonly) NSArray *filePaths;

+ (instancetype)sharedMeterCache;

- (id)initWithNamespace:(NSString *)namespae;

- (void)storeData:(NSData *)data forKey:(NSString *)key;
- (void)storeData:(NSData *)data forFileName:(NSString *)fileName inDirectory:(NSString *)directory;

- (void)removeDataForKey:(NSString *)key;
- (void)removeDataForFileName:(NSString *)filename directory:(NSString *)directory;
- (void)removeFileAtPath:(NSString *)path;

- (NSString *)cachePathForKey:(NSString *)key;
- (NSString *)cachePathForFileName:(NSString *)name directory:(NSString *)directory;

- (BOOL)fileExistsForFileName:(NSString *)fileName directory:(NSString *)directory;
- (BOOL)fileExistsForKey:(NSString *)key;

- (NSData *)dataFromCacheForKey:(NSString *)key;
- (NSData *)dataFromCacheForFileName:(NSString *)fileName directory:(NSString *)directory;

@end

#pragma mark - MeterCacheManagerBase

@interface MeterCacheManagerBase : NSObject
@property (strong, nonatomic, readonly) BSMeterCache *meterCache;
@end