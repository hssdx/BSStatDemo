//
//  UIApplication+BSEventInterceptor.h
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/13/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import "UIApplication+BSEventInterceptor.h"
#import "UIResponder+BSEventInterceptor.h"
#import "BSEventLogger.h"
#import <objc/runtime.h>

@implementation UIApplication (BSEventInterceptor)

+ (void)load{
    [UIResponder hookSelector:@selector(sendEvent:) withSelector:@selector(swizzledSendEvent:) class:self];
}

- (void)swizzledSendEvent:(UIEvent *) event{
    for (UITouch *touch in event.allTouches){
        if (touch.phase == UITouchPhaseBegan){
            [[BSEventLogger sharedEventLogger] logEvent:BSEventLoggerTypeTouch forObject:touch.view];
        }
    }
    [self swizzledSendEvent:event];
}

@end
