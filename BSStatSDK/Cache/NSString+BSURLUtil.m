//
//  NSString+BSURLUtil.m
//  BSStatDemo
//
//  Created by quanxiong on 16/5/4.
//  Copyright © 2016年 BeachSon. All rights reserved.
//

#import "NSString+BSURLUtil.h"

@implementation NSString (BSURLUtil)


- (NSString *)encodingTotalUrlString
{
    NSString *result = [self stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    result = [result stringByReplacingOccurrencesOfString:@" " withString:@"+"];
    return result;
}
- (NSString *)decodingTotalUrlString
{
    NSMutableString *tempUrl = [NSMutableString stringWithString:self];
    [tempUrl replaceOccurrencesOfString:@"+" withString:@" " options:NSLiteralSearch range:NSMakeRange(0, [tempUrl length])];
    NSString *result = [tempUrl stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return result;
}

- (NSString *)encodingUrlParameterString
{
    return (__bridge_transfer NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,  (__bridge CFStringRef)self,  NULL,  (CFStringRef)@"!*'();:@&=+$,/?%#[]", kCFStringEncodingUTF8);
}
- (NSString *)decodingUrlParameterString
{
    return  (__bridge_transfer NSString *)CFURLCreateStringByReplacingPercentEscapesUsingEncoding(NULL, (__bridge CFStringRef)self, CFSTR(""), kCFStringEncodingUTF8);
}
@end
