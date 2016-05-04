//
//  UIView+BSEventInterceptor.m
//  BSStatDemo
//
//  Created by quanxiong on 16/5/3.
//  Copyright © 2016年 BeachSon. All rights reserved.
//

#import "UIView+BSEventInterceptor.h"
#import "UIResponder+BSEventInterceptor.h"

@implementation UIView (BSEventInterceptor)

+ (void)load {
    [UIResponder hookSelector:@selector(addGestureRecognizer:)
                 withSelector:@selector(addSwizzledGestureRecognizer:)
                        class:self];
}

- (void)addSwizzledGestureRecognizer:(UIGestureRecognizer *)gestureRecognizer {
    if (!self.needTelemetry)
        self.needTelemetry = YES;
    [self addSwizzledGestureRecognizer:gestureRecognizer];
}

@end
