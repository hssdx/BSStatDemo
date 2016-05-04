//
//  InterceptControlViewController.h
//  BSStatDemo
//
//  Created by quanxiong on 16/5/4.
//  Copyright © 2016年 BeachSon. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface InterceptControlViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *testButton;
@property (weak, nonatomic) IBOutlet UISwitch *testSwitch;
@property (weak, nonatomic) IBOutlet UISegmentedControl *testSegment;
@property (weak, nonatomic) IBOutlet UISlider *testSlider;
@property (weak, nonatomic) IBOutlet UIPageControl *testPageControl;
@property (weak, nonatomic) IBOutlet UIStepper *testStepper;

@end
