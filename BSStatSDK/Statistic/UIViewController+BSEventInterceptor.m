//
//  UIViewController+BSEventInterceptor.h
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/13/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import "UIViewController+BSEventInterceptor.h"
#import "UIResponder+BSEventInterceptor.h"
#import "BSEventLogger.h"
#import <objc/runtime.h>


static const char *kAppear = "Appear";
static const char *kDisappear = "DisAppear";
static NSString * const kDuration = @"duration";

@implementation UIViewController (BSEventInterceptor)

+(void)load{
    [UIResponder hookSelector:@selector(viewDidAppear:) withSelector:@selector(swizzledViewDidAppear:) class:self];
    [UIResponder hookSelector:@selector(init) withSelector:@selector(swizzledInit) class:self];
    [UIResponder hookSelector:@selector(initWithCoder:) withSelector:@selector(swizzledInitWithCoder:) class:self];
    [UIResponder hookSelector:@selector(viewDidDisappear:) withSelector:@selector(swizzledViewDidDisappear:) class:self];
}

- (instancetype)swizzledInit {
   self.needTelemetry = YES;
   return [self swizzledInit];
}

- (instancetype)swizzledInitWithCoder:(NSCoder *)aDecoder {
    self.needTelemetry = YES;
    return [self swizzledInitWithCoder:aDecoder];
}

-(void)swizzledViewDidAppear:(BOOL) animated{
    [self setViewAppearDate:[NSDate date]];
    [[BSEventLogger sharedEventLogger] logEvent:BSEventLoggerTypeAppear forObject:self];
    [self swizzledViewDidAppear:animated];
}

-(void)swizzledViewDidDisappear:(BOOL)animated{
    NSDate *currentDate = [NSDate date];
    [self setViewDisappearDate:currentDate];
    [[BSEventLogger  sharedEventLogger]logEvent:BSEventLoggerTypeDisappear forObject:self];
    
    NSDate *previousDate = [self viewAppearDate];
    NSTimeInterval timeInterval = [currentDate timeIntervalSinceDate:previousDate];
    [[BSEventLogger sharedEventLogger]logEventWithkey:kDuration value:[NSString stringWithFormat:@"%f",timeInterval] forObject:self];
    [self swizzledViewDidDisappear:animated];
}

-(void)setViewAppearDate:(NSDate *)dateValue{
    objc_setAssociatedObject (self, kAppear, dateValue, OBJC_ASSOCIATION_RETAIN);
}

-(NSDate *)viewAppearDate{
    return (NSDate *)objc_getAssociatedObject(self, kAppear);
}

-(void)setViewDisappearDate:(NSDate *)dateValue{
    objc_setAssociatedObject (self, kDisappear, dateValue, OBJC_ASSOCIATION_RETAIN);
}

-(NSDate *)viewDisappearDate{
    return (NSDate *)objc_getAssociatedObject(self, kDisappear);
}
@end
