//
//  UIResponder+BSEventInterceptor.h
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/13/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIResponder (BSEventInterceptor)

@property (copy, nonatomic) NSString *eventKey;
@property (copy, nonatomic) NSString *eventValue;

@property (assign, nonatomic) BOOL needTelemetry;

+ (void)hookSelector:(SEL)originalSelector withSelector:(SEL)newSelector class:(Class)class;
@end
