//
//  BSStatisticModel.m
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/13/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import "BSStatisticModel.h"
#import <UIKit/UIKit.h>
#import <CommonCrypto/CommonDigest.h>
#import "BSNetworkingInfo.h"
#import "NSDate+BSTimeInterval.h"
#import "BSUtilities.h"

#pragma mark - FlowEventItem

@interface FlowEventItem : BSStatisticBaseModel
@property (copy, nonatomic) NSString *event_id;
@property (strong, nonatomic) NSMutableArray *happened;

- (void)addHappenedValue:(NSNumber *)value;
@end

@implementation FlowEventItem

- (void)addHappenedValue:(NSNumber *)value{
    if (!_happened)
        _happened = [NSMutableArray array];
    [self.happened addObject:value];
}
@end

#pragma mark - EventModel

@interface EventBaseModel : BSStatisticBaseModel
@property (copy, nonatomic) NSString *account;
@property (strong, nonatomic) NSNumber *type;
@end

@implementation EventBaseModel
@end

@interface FlowEventModel : EventBaseModel
@property (strong, nonatomic) NSMutableArray *flow;
- (void)addFlowItem:(FlowEventItem *)item;
@end

@implementation FlowEventModel

- (void)addFlowItem:(FlowEventItem *)item{
    if (!_flow)
        _flow = [NSMutableArray array];
    [self.flow addObject:item];
}

- (NSNumber *)type{
    return @1;
}

@end

@interface CustomEventModel : EventBaseModel
@end

@implementation CustomEventModel

- (NSNumber *)type{
    return @2;
}

@end

#pragma mark - Error

@interface ErrorItem : NSObject
@property (strong, nonatomic) NSNumber *time;
@property (copy, nonatomic) NSString *errorString;
@end

@implementation ErrorItem

- (NSNumber *)time{
    if (!_time){
        _time = @([[NSDate date] BSTimeIntervalForMS]);
    }
    return _time;
}
@end

@interface Error : NSObject
@property (copy, nonatomic) NSString *version;
@property (strong, nonatomic) NSMutableArray *errorArray;
@end

@implementation Error

- (NSString *)version{
    if (!_version){
        _version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    }
    return _version;
}

- (void)addErrorItem:(ErrorItem *)item{
    if (!_errorArray)
        _errorArray = [NSMutableArray array];
    [self.errorArray addObject:item];
}

- (NSArray*)errorArrayToExport{
    if (!self.errorArray.count)
        return [NSArray array];
    
    NSMutableArray *errorArrayPerVersion = [NSMutableArray array];
    for (ErrorItem *item in self.errorArray) {
        NSDictionary *itemDictionary = @{[NSString stringWithFormat:@"%@", item.time]
                                         :item.errorString};
        [errorArrayPerVersion addObject:itemDictionary];
    }
    
    NSDictionary *dictionaryData = @{self.version : errorArrayPerVersion};
    return @[dictionaryData];
}

- (void)reset{
    [self.errorArray removeAllObjects];
}
@end

#pragma mark - History

@interface HistoryItem : BSStatisticBaseModel
@property (copy, nonatomic) NSNumber *date;
@property (strong, nonatomic) NSMutableArray *duration;
@end

@implementation HistoryItem
- (instancetype)init {
    if (self = [super init]) {
        _duration = [NSMutableArray array];
    }
    return self;
}
@end

#pragma mark - FakeFlowEventItem

@interface FakeFlowEventItem : NSObject
@property (copy, nonatomic) NSString *event_id;
@property (strong, nonatomic) NSNumber *happenedNumber;
@end

@implementation FakeFlowEventItem
@end

#pragma mark - StatisticModel

@interface BSStatisticModel()
//TODO: need imp
//@property (strong, nonatomic) NSDictionary *video;
//@property (strong, nonatomic) NSDictionary *cpu;
//@property (strong, nonatomic) NSDictionary *board;
//@property (strong, nonatomic) NSDictionary *disk;
//@property (strong, nonatomic) NSDictionary *memory;

@property (strong, nonatomic) NSArray *packageNames;
@property (strong, nonatomic) NSMutableArray *events;
@property (strong, nonatomic) Error *error;
@property (strong, nonatomic) NSMutableDictionary *customFields;
@property (strong, nonatomic) NSMutableArray *history;

//None JsonData fields
@property (strong, nonatomic) NSMutableArray *fakeFlowEvents;

@end

@implementation BSStatisticModel

- (instancetype)init{
    self = [super init];
    if (self){
        [self initFixedFields];
        [self updateVariableFields];
        return self;
    }
    return nil;
}

- (void)reset{
    [self.events removeAllObjects];
    [self.history removeAllObjects];
    [self.customFields removeAllObjects];
    [self.fakeFlowEvents removeAllObjects];
    [self.error reset];
    [self updateVariableFields];
}

- (NSDictionary *)infoPlistDict {
    static NSDictionary *dict = nil;
    if (!dict) {
        NSString *infoPath = [[NSBundle mainBundle]pathForResource:@"Info" ofType:@"plist"];
        dict = [NSDictionary dictionaryWithContentsOfFile:infoPath];
    }
    return dict;
}

- (id)infoPlistWithInfoKey:(NSString *)key defaultValue:(id)defaultObject {
    id result = [self.infoPlistDict objectForKey:key];
    if (!result) {
        result = defaultObject;
    }
    return result;
}

- (void)initFixedFields{
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    self.screenInfo = [NSString stringWithFormat:@"%ld*%ld", (long)screenSize.width, (long)screenSize.height];
    self.protocol = [self infoPlistWithInfoKey:@"BSStatProtocol" defaultValue:@5];
    self.secretID = [self infoPlistWithInfoKey:@"BSStatCID" defaultValue:@12];
    self.version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    
    self.packageNames = @[[[NSBundle mainBundle] bundleIdentifier]];
    self.packageName = [[NSBundle mainBundle] bundleIdentifier];
    self.timeZone = [NSTimeZone localTimeZone].name;
    self.systemVersion = [[UIDevice currentDevice] systemVersion];
    
    NSString *rawUUID = [[[[UIDevice currentDevice]  identifierForVendor] UUIDString] lowercaseString];
    self.uuid = [rawUUID stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    self.error = [[Error alloc]init];
    self.events = [NSMutableArray array];
    self.history = [NSMutableArray array];
    
    self.customFields = [NSMutableDictionary dictionary];
    NSString *sdkVersion = [self infoPlistWithInfoKey:@"BSSdkVersion" defaultValue:@"1.0.0-RELEASE"];
    [self.customFields setValue:sdkVersion forKey:@"sdk_version"];
    self.fakeFlowEvents = [NSMutableArray array];
}

- (void)updateVariableFields{
    self.networkInfo = [BSNetworkingInfo getNetworkInfo];
    self.deviceModel = [[UIDevice currentDevice] model];
    self.time = @([[NSDate date] BSTimeIntervalForMS]);

    //self.d = @99;
    self.userip = [BSNetworkingInfo getIPAddress];
    //self.b = @0;
    
    static NSString *const signFormat = @"%@%@%@client_#&$%%";
    NSString *singString = [NSString stringWithFormat:signFormat, self.uuid, self.secretID, self.time];
    self.sign = [self md5HexDigest:singString];
}

- (NSArray *)arrayForExceptionalProperties {
    return @[@"accountName", @"fakeFlowEvents"];
}

- (NSDictionary*)JSONData {
    //collect real FlowEventItem
    
    NSMutableDictionary *flowEventIds = [NSMutableDictionary dictionary];
    for (FakeFlowEventItem *item in self.fakeFlowEvents) {
        FlowEventItem *targetItem = [flowEventIds objectForKey:item.event_id];
        if (targetItem) {
            [targetItem addHappenedValue:item.happenedNumber];
        }else{
            targetItem = [[FlowEventItem alloc]init];
            targetItem.event_id = [item.event_id copy];
            [targetItem addHappenedValue:item.happenedNumber];
            [flowEventIds setObject:targetItem forKey:item.event_id];
        }
    }
    
    if ([self.events count]){
        FlowEventModel *flowModel = self.events[0];
        [flowEventIds enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            [flowModel addFlowItem:obj];
        }];
    }

    NSMutableDictionary *jsonData = [[super JSONData] mutableCopy];
    [jsonData setValue:[self.error errorArrayToExport] forKey:@"error"];
    return jsonData;
}

- (void)addFlowEventWithKey:(NSString *)key value:(NSString *)value{
    if (![self.events count]){
        FlowEventModel *flowModel = [[FlowEventModel alloc]init];
        if (!self.accountName){
            BSLog(@"FlowEventModel need a valid accountName");
            self.accountName = @"test@beach_son.com";
        }
        flowModel.account = self.accountName;
        [self.events addObject:flowModel];
    }

    FakeFlowEventItem *fakeItem = [[FakeFlowEventItem alloc]init];
    fakeItem.event_id = key;
    fakeItem.happenedNumber = @(value.longLongValue);
    
    [self.fakeFlowEvents addObject:fakeItem];    
}

- (void)addErrorInfo:(NSString *)errorInfo{
    ErrorItem *item = [[ErrorItem alloc]init];
    item.errorString = [errorInfo copy];
    [self.error addErrorItem:item];
}

- (void)addHistoryWithStartDate:(NSDate *)startDate
                        endDate:(NSDate *)endDate {
    HistoryItem *item = nil;
    if (self.history.count > 0) {
        item = [self.history firstObject];
    } else {
        item = [[HistoryItem alloc]init];
        [self.history addObject:item];
    }
    NSNumber *durationItem = [[NSNumber alloc] initWithLong:
                              (long)([endDate BSTimeInterval] - [startDate BSTimeInterval])];
    [item.duration addObject:durationItem];
    item.date = @([[NSDate date] BSTimeIntervalForMS]);
}

- (NSString*)rawUUID{
    static NSString *uuid = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CFUUIDRef puuid = CFUUIDCreate(nil);
        CFStringRef uuidString = CFUUIDCreateString(nil, puuid);
        uuid = (NSString *)CFBridgingRelease(CFStringCreateCopy(NULL, uuidString));
        CFRelease(puuid);
        CFRelease(uuidString);
    });
    return uuid;
}

- (NSString *)md5HexDigest:(NSString *)string{
    const char *originalString = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(originalString, (CC_LONG)strlen(originalString), result);
    NSMutableString *hash = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSUInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [hash appendFormat:@"%02X", result[i]];
    return [[hash lowercaseString] copy];
}
@end
