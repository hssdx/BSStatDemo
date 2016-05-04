//
//  UIControl+BSEventInterceptor.m
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/20/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import "UIControl+BSEventInterceptor.h"
#import "UIResponder+BSEventInterceptor.h"
#import <objc/runtime.h>

@implementation UIControl (BSEventInterceptor)

+ (void)load{
    [UIResponder hookSelector:@selector(addTarget:action:forControlEvents:)
                 withSelector:@selector(addSwizzledTarget:action:forControlEvents:)
                        class:self];
}

- (void)addSwizzledTarget:(id)target
                   action:(SEL)action
         forControlEvents:(UIControlEvents)controlEvents{
    if (!self.needTelemetry)
        self.needTelemetry = YES;
    [self addSwizzledTarget:target action:action forControlEvents:controlEvents];
}

@end
