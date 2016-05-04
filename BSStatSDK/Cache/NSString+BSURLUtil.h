//
//  NSString+BSURLUtil.h
//  BSStatDemo
//
//  Created by quanxiong on 16/5/4.
//  Copyright © 2016年 BeachSon. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (BSURLUtil)

/**
*  编码整个URL字符串
*
*  @return 编码后的URL字符串
*/
- (NSString *)encodingTotalUrlString;
/**
*  解码整个URL字符串
*
*  @return 解码后的URL字符串
*/
- (NSString *)decodingTotalUrlString;
/**
*  编码URL的Query字段中的参数(包含key和value)
*
*  @return 编码后的参数
*/
- (NSString *)encodingUrlParameterString;
/**
*  解码URL的Query字段中的参数(包含key和value)
*
*  @return 解码后的参数
*/
- (NSString *)decodingUrlParameterString;
@end
