//
//  BSUtilities.h
//  Beach Son Stat
//
//  Created by quanxiong on 16/5/3.
//  Copyright © 2016年 BeachSon. All rights reserved.
//

#ifndef BSUtilities_h
#define BSUtilities_h


#if DEBUG
#define BSLog(...) NSLog(__VA_ARGS__)
#define BSLogForFrame(frame)  KSLog(@"%s %s%@",__PRETTY_FUNCTION__,#frame,NSStringFromCGRect(frame))
#else
#define BSLog(...) (void)0
#define BSLogForFrame(frame) (void)0
#endif

#endif /* BSUtilities_h */
