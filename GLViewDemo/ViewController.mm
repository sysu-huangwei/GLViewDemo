//
//  ViewController.m
//  GLViewDemo
//
//  Created by HW on 2019/1/29.
//  Copyright © 2019 meitu. All rights reserved.
//

#import "ViewController.h"
#import "MGLKViewController.h"
#import "MViewController.h"

@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

- (IBAction)presentGLKViewController:(id)sender {
    MGLKViewController* glView = [[MGLKViewController alloc] init];
    [self presentViewController:glView animated:YES completion:nil];
}


- (IBAction)presentViewController:(id)sender {
    MViewController* view = [[MViewController alloc] init];
    [self presentViewController:view animated:YES completion:nil];
}

@end
