//
//  BSStatisticCacheManager.m
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 6/8/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import "BSStatisticCacheManager.h"
#import "BSStatisticModel.h"
#import "NSDate+BSTimeInterval.h"
#import "BSUtilities.h"
#import "NSString+BSURLUtil.h"
#import <zlib.h>

static const NSUInteger kMaxFileSize = 2 * 1024;
typedef void (^success)();
typedef void (^failure)(NSError *error);

@interface BSStatisticCacheManager()
@property (strong, nonatomic) dispatch_queue_t statisticQueue;
@property (strong, nonatomic) BSMeterCache *cacheForDebug;
@end

@implementation BSStatisticCacheManager

+ (instancetype)sharedStatisticCacheManager{
    static dispatch_once_t once;
    static id instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self){
        _statisticQueue = dispatch_queue_create(NSStringFromClass([self class]).UTF8String, DISPATCH_QUEUE_SERIAL);
        return self;
    }
    return nil;
}

- (NSString *)dateStamp{
    return [[NSDate date] BSTimeIntervalString];
}

- (void)storeStatisticModel:(BSStatisticModel *)statisticModel{
    if (!statisticModel)
        return;
    NSDictionary *rawData = [statisticModel JSONData];
    if (![NSJSONSerialization isValidJSONObject:rawData])
        return;
    
    NSData *parametersData = [self dataToBeSendWithString:rawData];
    [self.meterCache storeData:parametersData forKey:[self dateStamp]];
    
    [self saveStatisticDataForSimulatorModeWithNSDictionary:rawData];
}

- (void)saveStatisticDataForSimulatorModeWithNSDictionary:(NSDictionary *)data{
#if TARGET_IPHONE_SIMULATOR
    if (!self.cacheForDebug)
        self.cacheForDebug = [[BSMeterCache alloc] initWithNamespace:@"stats_debug"];
    
    if (![NSJSONSerialization isValidJSONObject:data])
        return;
        
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:data
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:nil];
    [self.cacheForDebug storeData:jsonData forKey:[self dateStamp]];
#endif
}

- (NSData *)dataToBeSendWithString:(NSDictionary *)jsonData {
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:jsonData
                                                       options:0
                                                         error:nil];
    NSString *rawString = [[NSString alloc] initWithData:bodyData encoding:NSUTF8StringEncoding];
    NSString *encodeString = [rawString encodingUrlParameterString];
    NSData *parametersData = [encodeString dataUsingEncoding:NSUTF8StringEncoding];
    return parametersData;
}

- (void)sendCachedData{
    if (!self.needSending)
        return;
    
    __weak BSStatisticCacheManager *weakSelf  =self;
    dispatch_async(self.statisticQueue, ^{
        for (NSString *path in weakSelf.meterCache.filePaths) {
            NSData *parameters = [NSData dataWithContentsOfFile:path];
            NSString *string = [[NSString alloc]initWithData:parameters encoding:NSUTF8StringEncoding];
            string = [string decodingUrlParameterString];
            BSLog(@"send data: %@", string);
#if 0
            [weakSelf sendStatisticDataWithParameters:parameters success:^{
                [weakSelf.meterCache removeFileAtPath:path];
            }failure:^(NSError *error) {
            }];
#endif
        }
    });
}

- (BOOL)needSending{
    NSArray *filePaths = self.meterCache.filePaths;
    return filePaths.count > 0;
}

#if 0
- (void)sendStatisticDataWithParameters:(NSData *)parameters success:(success)success failure:(failure)failure{
    NSString *url = STAT_URL;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    
    NSData *bodyData = [parameters copy];
    if ([self needCompressData:parameters]){
        [request setValue:@"gzip" forHTTPHeaderField:@"Content-Encoding"];
        bodyData = [self dataByGZipCompressing:parameters error:nil];
    }else{
        [request addValue:@"application/json; charset=utf-8" forHTTPHeaderField:@"Content-Type"];
    }
    [request setHTTPBody:bodyData];
    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *connectionError) {
                               NSHTTPURLResponse *r = (NSHTTPURLResponse *)response;
                               if (r.statusCode == 200 && !connectionError && success)
                                   success();
                               else if(failure)
                                   failure(nil);
#if DEBUG
                               NSLog(@"%ld",(long)r.statusCode);
#endif
                           }];
}
#endif

- (BOOL)needCompressData:(NSData *)data{
    return data.length > kMaxFileSize;
}

- (NSData *)dataByGZipCompressing:(NSData *)rawData error:(NSError **)error {
    static const int kzippaChunkSize = 1024;
    static const int kDefaultMemoryLevel = 8;
    static const int kDefaultWindowBitsWithGZipHeader = 31;
    static NSString * const kZippaZlibErrorDomain = @"com.zlib.error";
    
    z_stream zStream;
    bzero(&zStream, sizeof(z_stream));
    zStream.zalloc = Z_NULL;
    zStream.zfree = Z_NULL;
    zStream.opaque = Z_NULL;
    zStream.next_in = (Bytef *)[rawData bytes];
    zStream.avail_in = (unsigned int)[rawData length];
    zStream.total_out = 0;
    
    OSStatus status;
    if ((status = deflateInit2(&zStream, Z_DEFAULT_COMPRESSION, Z_DEFLATED, kDefaultWindowBitsWithGZipHeader, kDefaultMemoryLevel, Z_DEFAULT_STRATEGY)) != Z_OK) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:kZippaZlibErrorDomain code:status userInfo:nil];
        }
        return nil;
    }
    
    NSMutableData *compressedData = [NSMutableData dataWithLength:kzippaChunkSize];
    do {
        if ((status == Z_BUF_ERROR) || (zStream.total_out == [compressedData length])) {
            [compressedData increaseLengthBy:kzippaChunkSize];
        }
        zStream.next_out = (Bytef*)[compressedData mutableBytes] + zStream.total_out;
        zStream.avail_out = (unsigned int)([compressedData length] - zStream.total_out);
        status = deflate(&zStream, Z_FINISH);
    } while ((status == Z_OK) || (status == Z_BUF_ERROR));
    
    deflateEnd(&zStream);
    
    if ((status != Z_OK) && (status != Z_STREAM_END)) {
        if (error) {
            *error = [[NSError alloc] initWithDomain:kZippaZlibErrorDomain code:status userInfo:nil];
        }
        return nil;
    }
    
    [compressedData setLength:zStream.total_out];
    return compressedData;
}


@end
