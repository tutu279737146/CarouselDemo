//
//  ViewController.m
//  图片轮播器demo
//
//  Created by 涂世展 on 16/8/20.
//  Copyright © 2016年 涂世展. All rights reserved.
//

#import "ViewController.h"
//先导入头文件
#import "TTCarouselView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //创建需要轮播的图片数组
    UIImage *image1 = [UIImage imageNamed:@"汪婷1"];
    UIImage *image2 = [UIImage imageNamed:@"王师傅"];
    NSArray *arr = @[image1,image2];
    //将数组赋值给demo的数组
    TTCarouselView *cv = [[TTCarouselView alloc] init];
    cv.imageArray = arr;
    //一定要设置frame和添加到view上
    [self.view addSubview:cv];
    cv.frame = CGRectMake(0, 200, 300, 300);
    
    //url同上
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
