//
//  BSStatisticBaseModel.h
//  Beach Son Stat lib
//
//  Created by Beach Son Team on 5/14/15.
//  Copyright (c) 2015 BeachSon. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol BSStatisticBaseModelProtocol <NSObject>
- (NSDictionary*)JSONData;
@end

@interface BSStatisticBaseModel : NSObject<BSStatisticBaseModelProtocol>
- (NSDictionary*)JSONData;
@end

