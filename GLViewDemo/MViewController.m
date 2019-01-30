//
//  MViewController.m
//  GLViewDemo
//
//  Created by HW on 2019/1/30.
//  Copyright © 2019 meitu. All rights reserved.
//

#import "MViewController.h"

@interface MViewController ()

@end

@implementation MViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString* path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"大图.jpg"];
    UIImage* image = [[UIImage alloc] initWithContentsOfFile:path];
    
    UIImageView* imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [imageView setImage:image];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    [self.view addSubview:imageView];
    
    self.view.userInteractionEnabled = YES;
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(removeSelfView:)];
    [self.view addGestureRecognizer:tapGesture];
}

- (void)removeSelfView:(UITapGestureRecognizer *)gesture {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
