//
//  ViewController.m
//  GLViewDemo
//
//  Created by HW on 2019/1/29.
//  Copyright © 2019 meitu. All rights reserved.
//

#import "ViewController.h"
#import "MGLKViewController.h"

@interface ViewController ()

@end


@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    GLKView *view  = (GLKView *)self.view;
//    NSAssert([view isKindOfClass:[GLKView class]], @"viewcontroller’s view is not a GLKView");
    //创建OpenGL ES2.0上下文
//    view.context = [[EAGLContext alloc]initWithAPI:kEAGLRenderingAPIOpenGLES2];
    //设置当前上下文
//    [EAGLContext setCurrentContext:view.context];
    
//    const GLfloat vertices[] = {
//        1, -1, 0.0f,   //D
//        1, 1,  0.0f,   //B
//        -1, 1, 0.0f,   //A
//
//        1, -1, 0.0f,   //D
//        -1, 1, 0.0f,   //A
//        -1, -1, 0.0f,   //C
//    };
//
    NSString* path = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"IMG_3147.JPG"];
    UIImage* image = [[UIImage alloc] initWithContentsOfFile:path];

    UIImageView* imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    [imageView setImage:image];
    [imageView setContentMode:UIViewContentModeScaleAspectFit];
    
    
    
    
    
    
//    [self.view addSubview:imageView];
    
}

- (IBAction)present:(id)sender {
    MGLKViewController* glView = [[MGLKViewController alloc] init];
    [self presentViewController:glView animated:YES completion:nil];
}

@end
