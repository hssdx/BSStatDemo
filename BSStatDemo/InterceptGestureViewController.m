//
//  InterceptGestureViewController.m
//  BSStatDemo
//
//  Created by quanxiong on 16/5/4.
//  Copyright © 2016年 BeachSon. All rights reserved.
//

#import "InterceptGestureViewController.h"

@interface InterceptGestureViewController ()

@end

@implementation InterceptGestureViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
    [self.view1 addGestureRecognizer:panGesture];
    [self.view1 setValue:@"需要一个名称" forKey:@"eventKey"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handlePan:(id)sender {
    //NSLog(@"%s", __func__);
}

- (IBAction)handleTapOnce:(id)sender {
    //NSLog(@"%s", __func__);
}

- (IBAction)handleTapTwice:(id)sender {
    //NSLog(@"%s", __func__);
}
@end
