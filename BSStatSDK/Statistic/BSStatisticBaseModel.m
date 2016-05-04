//
//  BSStatisticBaseModel.m
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/14/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import "BSStatisticBaseModel.h"
#import <objc/runtime.h>

static NSString *const kClassPropertiesKey;

#pragma mark - StatisticModelClassProperty

@interface StatisticJSONClassProperty : NSObject
@property (copy, nonatomic) NSString *name;
@property (assign, nonatomic) Class type;
@end

@implementation StatisticJSONClassProperty
@end

#pragma mark - StatisticBaseModel

@implementation BSStatisticBaseModel

- (void)inspectProperties{
    NSMutableDictionary* propertyDictionary = [NSMutableDictionary dictionary];
    Class class = [self class];
    NSScanner* scanner = nil;
    NSString* propertyType = nil;
    const NSArray *exceptionalArray = @[@"hpash", @"hash", @"superclass", @"debugDescription", @"description"];
    
    while ([class conformsToProtocol:@protocol(BSStatisticBaseModelProtocol)]){
        unsigned int propertyCount;
        objc_property_t *properties = class_copyPropertyList(class, &propertyCount);
        for (unsigned int i = 0; i < propertyCount; i++) {
            StatisticJSONClassProperty* jsonProperty = [[StatisticJSONClassProperty alloc] init];
            objc_property_t property = properties[i];
            const char *propertyName = property_getName(property);
            
            if ([exceptionalArray containsObject:@(propertyName)])
                continue;
            
            jsonProperty.name = @(propertyName);
            
            const char *attrs = property_getAttributes(property);
            NSString* propertyAttributes = @(attrs);
            scanner = [NSScanner scannerWithString: propertyAttributes];
            [scanner scanUpToString:@"T" intoString: nil];
            [scanner scanString:@"T" intoString:nil];
            if ([scanner scanString:@"@\"" intoString: &propertyType]) {
                [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"\"<"]
                                        intoString:&propertyType];
                jsonProperty.type = NSClassFromString(propertyType);
            }
            else if ([scanner scanString:@"{" intoString: &propertyType]) {
                NSAssert(NO, @"structure property is not supported now");
            }
            else {
                NSAssert(NO, @"primitive property is not supported now");
            }
            
            if (jsonProperty && ![propertyDictionary objectForKey:jsonProperty.name]) {
                [propertyDictionary setValue:jsonProperty forKey:jsonProperty.name];
            }
        }
        
        free(properties);
        class = [class superclass];
    }
    
    objc_setAssociatedObject(self.class,
                             &kClassPropertiesKey,
                             propertyDictionary,
                             OBJC_ASSOCIATION_COPY_NONATOMIC
                             );
    
}

- (BOOL)isNull:(id) value{
    if (!value)
        return YES;
    if ([value isKindOfClass:[NSNull class]])
        return YES;
    return NO;
}

- (NSDictionary*)JSONData{
    NSDictionary* classProperties = objc_getAssociatedObject(self.class, &kClassPropertiesKey);
    if (!classProperties){
        [self inspectProperties];
        classProperties = objc_getAssociatedObject(self.class, &kClassPropertiesKey);
    }
    
    NSArray* properties = [classProperties allValues];
    NSMutableDictionary* tempDictionary = [NSMutableDictionary dictionaryWithCapacity:properties.count];
    
    id value;
    for (StatisticJSONClassProperty* property in properties) {
        if ([self.arrayForExceptionalProperties containsObject:property.name])
            continue;
        
        //TODO 可以做变量名 -> key值映射字典
        NSString *keyPath = property.name;
        value = [self valueForKey: property.name];
        
        if ([self isNull:value]) {
            [tempDictionary setValue:[NSNull null] forKeyPath:keyPath];
            continue;
        }
        
        if ([value conformsToProtocol:@protocol(BSStatisticBaseModelProtocol)] && [self needTraverseForObject:value]) {
            value = [value performSelector:@selector(JSONData)];
            [tempDictionary setValue:value forKeyPath: keyPath];
        } else {
            if (property.type == [NSArray class]
                || property.type == [NSMutableSet class]
                || property.type == [NSMutableArray class]
                || property.type == [NSSet class]) {
                NSArray *dataArray;
                if (property.type == [NSSet class] || property.type == [NSMutableSet class])
                    dataArray = [(NSSet*)value allObjects];
                else
                    dataArray = (NSArray*)value;
                NSMutableArray *tempArray = [NSMutableArray arrayWithCapacity: [(NSArray*)dataArray count]];
                for (NSObject<BSStatisticBaseModelProtocol> *model in dataArray) {
                    if ([model respondsToSelector:@selector(JSONData)]) {
                        [tempArray addObject: [model JSONData]];
                    } else
                        [tempArray addObject: model];
                }
                value = [tempArray copy];
                [tempDictionary setValue:value forKeyPath: keyPath];
            }
            else{
                //not support primitive and structure
                value = [self objectWithOriginObject:value];
                [tempDictionary setValue:value forKeyPath: keyPath];
            }
        }
    }
    return [tempDictionary copy];
}

- (id)objectWithOriginObject:(id) object{
    return object;
}

- (BOOL)needTraverseForObject:(id)object{
    return NO;
}

- (NSArray *) arrayForExceptionalProperties{
    return nil;
}

@end
