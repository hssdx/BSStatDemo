//
//  BSMeterCache.m
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/25/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import "BSMeterCache.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import "BSUtilities.h"

static const NSInteger kDefaultCacheMaxCacheAge = 60 * 60 * 24 * 7; // TODO, get value from setting
typedef void(^CompletionBlock)();

#pragma mark - MeterCache

@interface BSMeterCache()

@property (strong, nonatomic) NSCache *memoryCache;
@property (copy, nonatomic, readwrite) NSString *diskCachePath;
@property (strong, nonatomic) dispatch_queue_t ioQueue;
@property (strong, nonatomic) NSFileManager *fileManager;

@end


@implementation BSMeterCache

+ (instancetype)sharedMeterCache{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init{
    return [self initWithNamespace:nil];
}

- (instancetype)initWithNamespace:(NSString *)namespace{
    self = [super init];
    if (self){
        if (!namespace)
            namespace = @"default";
        NSString *fullNamespace = [@"com.meter.cache." stringByAppendingString:namespace];
        _memoryCache = [[NSCache alloc]init];
        _memoryCache.name = fullNamespace;
        
        _diskCachePath = [self diskCachePathForNamespace:fullNamespace];
        _fileManager = [[NSFileManager alloc] init];
        _ioQueue = dispatch_queue_create(fullNamespace.UTF8String, DISPATCH_QUEUE_SERIAL);
        
        _maxCacheAge = kDefaultCacheMaxCacheAge;
        _needsCleanInBackground = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(clearMemory)
                                                     name:UIApplicationDidReceiveMemoryWarningNotification
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(cleanDiskInBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        return self;
    }
    return nil;
}

- (NSArray *)filePaths{
    NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
    NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtURL:diskCacheURL
                                                   includingPropertiesForKeys:nil
                                                                      options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                 errorHandler:nil];
    NSMutableArray *paths = [NSMutableArray array];
    for (NSURL *fileURL in fileEnumerator) {
        [paths addObject:[fileURL path]];
    }
    return [paths copy];
}


- (NSString *)diskCachePathForNamespace:(NSString*)namespace{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:namespace];
}

- (void)storeData:(NSData *)data forKey:(NSString *)key{
    if (!data || !key)
        return;
    
    [self.memoryCache setObject:data forKey:key];
    dispatch_async(self.ioQueue, ^{
        if (![self.fileManager fileExistsAtPath:self.diskCachePath])
            [self.fileManager createDirectoryAtPath:self.diskCachePath withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *path = [self cachePathForKey:key];
        [self createFileAtPath:path contents:data attributes:nil];
    });
}

- (void)storeData:(NSData *)data forFileName:(NSString *)fileName inDirectory:(NSString *)directory{
    if (!data)
        return;
    BSLog(@"%@",self.diskCachePath);
    
    dispatch_sync(self.ioQueue, ^{
        NSString *directoryPath = [self cachePathForFileName:nil directory:directory];
        if (![self.fileManager fileExistsAtPath:directoryPath])
            [self.fileManager createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        
        NSString *path = [self cachePathForFileName:fileName directory:directory];
        [self createFileAtPath:path contents:data attributes:nil];
    });
}

- (void)createFileAtPath:(NSString *)path contents:(NSData *)data attributes:(NSDictionary *)attr{
    if (![self.fileManager fileExistsAtPath:path]){
        [self.fileManager createFileAtPath:path contents:data attributes:attr];
    }
}

- (NSString *)cachePathForFileName:(NSString *)name directory:(NSString *)directory{
    NSString *filePath = self.diskCachePath;
    NSArray *directoryArray = [directory componentsSeparatedByString:@"."];
    for (NSString *directory in directoryArray ) {
        filePath = [filePath stringByAppendingPathComponent:directory];
    }
    return [filePath stringByAppendingPathComponent:name];
}

- (NSString *)cachePathForKey:(NSString *)key{
    NSString *filename = [self cachedFileNameForKey:key];
    return [self.diskCachePath stringByAppendingPathComponent:filename];
}

- (NSString *)cachedFileNameForKey:(NSString *)key { //TODO move this to utils
    if (!key || [key isEqualToString:@""])
        return nil;

    const char *original = [key UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(original, (CC_LONG)strlen(original), result);
    
    NSMutableString *filename = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [filename appendFormat:@"%02X", result[i]];
    return [[filename lowercaseString] copy];
}

- (BOOL)fileExistsForKey:(NSString *)key{
    if ([self.memoryCache objectForKey:key])
        return YES;
    else
        return [self.fileManager fileExistsAtPath:[self cachePathForKey:key]];
}

- (BOOL)fileExistsForFileName:(NSString *)fileName directory:(NSString *)directory{
    return [self.fileManager fileExistsAtPath:[self cachePathForFileName:fileName directory:directory]];
}

- (NSData *)dataFromCacheForKey:(NSString *)key{
    if (![self fileExistsForKey:key])
        return nil;
    
    NSData *data = [self.memoryCache objectForKey:key];
    if (data){
        return data;
    }else{
        NSData *data = [NSData dataWithContentsOfFile:[self cachePathForKey:key]];
        [self.memoryCache setObject:data forKey:key];
        return data;
    }
}

- (NSData *)dataFromCacheForFileName:(NSString *)fileName directory:(NSString *)directory{
    return [NSData dataWithContentsOfFile:[self cachePathForFileName:fileName directory:directory]];
}

- (void)removeDataForKey:(NSString *)key{
    if (!key)
        return;
    
    [self.memoryCache removeObjectForKey:key];
    [self removeFileAtPath:[self cachePathForKey:key]];
}

- (void)removeDataForFileName:(NSString *)filename directory:(NSString *)directory{
    if (!filename && !directory)
        return;
    
    NSString *filePath = [self cachePathForFileName:filename directory:directory];
    [self removeFileAtPath:filePath];
}

- (void)removeFileAtPath:(NSString *)path{
    if (![self.fileManager fileExistsAtPath:path])
        return ;
    
    dispatch_sync(self.ioQueue, ^{
        [self.fileManager removeItemAtPath:path error:nil];
    });
}

- (void)clearMemory{
    [self.memoryCache removeAllObjects];
}

- (void)cleanDiskInBackground{
    if (!self.needsCleanInBackground)
        return;
    
    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier task = [application beginBackgroundTaskWithExpirationHandler:^{
        [application endBackgroundTask:task];
        task = UIBackgroundTaskInvalid;
    }];
    
    [self cleanDiskWithCompletion:^{
        [application endBackgroundTask:task];
        task = UIBackgroundTaskInvalid;
    }];
}

- (void)cleanDiskWithCompletion:(CompletionBlock)completion{
    dispatch_async(self.ioQueue, ^{
        NSURL *diskCacheURL = [NSURL fileURLWithPath:self.diskCachePath isDirectory:YES];
        NSArray *resourceKeys = @[NSURLIsDirectoryKey, NSURLContentModificationDateKey, NSURLTotalFileAllocatedSizeKey];
        NSDirectoryEnumerator *fileEnumerator = [self.fileManager enumeratorAtURL:diskCacheURL
                                                       includingPropertiesForKeys:resourceKeys
                                                                          options:NSDirectoryEnumerationSkipsHiddenFiles
                                                                     errorHandler:nil];
        
        NSDate *expirationDate = [NSDate dateWithTimeIntervalSinceNow:-self.maxCacheAge];
        NSMutableArray *urlsToDelete = [NSMutableArray array];
        for (NSURL *fileURL in fileEnumerator) {
            NSDictionary *resourceValues = [fileURL resourceValuesForKeys:resourceKeys error:nil];
            
            if ([resourceValues[NSURLIsDirectoryKey] boolValue]) {
                continue;
            }
            
            NSDate *modificationDate = resourceValues[NSURLContentModificationDateKey];
            if ([[modificationDate laterDate:expirationDate] isEqualToDate:expirationDate]) {
                [urlsToDelete addObject:fileURL];
                continue;
            }
        }
        
        for (NSURL *fileURL in urlsToDelete) {
            [self.fileManager removeItemAtURL:fileURL error:nil];
        }
        
        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion();
            });
        }
    });
}


@end

#pragma mark - MeterCacheManagerBase

@implementation MeterCacheManagerBase

- (instancetype)init{
    self = [super init];
    if (self){
        _meterCache = [[BSMeterCache alloc]initWithNamespace:NSStringFromClass([self class])];
        return self;
    }
    return nil;
}

@end
