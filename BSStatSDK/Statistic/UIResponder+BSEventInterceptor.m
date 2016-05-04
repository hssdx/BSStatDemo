//
//  UIResponder+BSEventInterceptor.h
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/13/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import "UIResponder+BSEventInterceptor.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

static const char *kTelemetry = "telemetry";
static const char *kEventKey = "eventType";
static const char *kEventValue = "eventValue";

@implementation UIResponder (BSEventInterceptor)

- (void)setNeedTelemetry:(BOOL)needTelemetry{
    if (needTelemetry){
        objc_setAssociatedObject(self, kTelemetry, [NSNumber numberWithBool:needTelemetry], OBJC_ASSOCIATION_COPY);
        if ([self isKindOfClass:[UIButton class]])
            [self setEventKey:((UIButton *)self).currentTitle];
        else if([self isKindOfClass:[UITextField class] ])
            [self setEventKey:((UITextField *)self).placeholder];
        else if([self isKindOfClass:[UIViewController class]])
            [self setEventKey:@(class_getName([self class]))];
    }
}

- (BOOL)needTelemetry{
   return ((NSNumber *)objc_getAssociatedObject(self, kTelemetry)).boolValue;
}

-(void)setEventValue:(NSString *)eventValue{
    objc_setAssociatedObject(self, kEventValue, eventValue, OBJC_ASSOCIATION_COPY);
}

-(NSString *)eventValue{
    return (NSString *)objc_getAssociatedObject(self, kEventValue);
}

-(void)setEventKey:(NSString *)eventType{
    objc_setAssociatedObject(self, kEventKey, eventType, OBJC_ASSOCIATION_COPY);
}

-(NSString *)eventKey{
    return (NSString *)objc_getAssociatedObject(self, kEventKey);
}

+ (void)hookSelector:(SEL)originalSelector withSelector:(SEL)swizzledSelector class:(Class)class{
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    BOOL didAddMethod = class_addMethod(class, originalSelector,
                                        method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (didAddMethod){
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

@end
