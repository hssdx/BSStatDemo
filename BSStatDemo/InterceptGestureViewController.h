//
//  InterceptGestureViewController.h
//  BSStatDemo
//
//  Created by quanxiong on 16/5/4.
//  Copyright © 2016年 BeachSon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InterceptGestureViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIView *view1;
@property (weak, nonatomic) IBOutlet UILabel *label1;
@property (weak, nonatomic) IBOutlet UILabel *label2;

- (void)handlePan:(id)sender;
- (IBAction)handleTapOnce:(id)sender;
- (IBAction)handleTapTwice:(id)sender;

@end
