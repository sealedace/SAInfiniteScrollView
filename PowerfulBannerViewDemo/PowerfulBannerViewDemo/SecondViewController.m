//
//  SecondViewController.m
//  PowerfulBannerViewDemo
//
//  Created by gaoqiang xu on 5/26/15.
//  Copyright (c) 2015 SealedCompany. All rights reserved.
//

#import "SecondViewController.h"
#import "PowerfulBannerView.h"

@interface SecondViewController ()
@property (strong, nonatomic) PowerfulBannerView *bannerView;
@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect screenBounds = [UIScreen mainScreen].bounds;
    self.bannerView = [[PowerfulBannerView alloc] initWithFrame:CGRectMake(0, 200.f, CGRectGetWidth(screenBounds), 200.f)];
    [self.view addSubview:self.bannerView];
    
    
    // 内容配置block
    self.bannerView.bannerItemConfigurationBlock = ^UIView *(PowerfulBannerView *banner, id item, UIView *reusableView) {
        
        // 这里可以尽可能重用视图
        UIImageView *view = (UIImageView *)reusableView;
        if (!view) {
            // 没有重用的，在这里创建一个
            view = [[UIImageView alloc] initWithFrame:CGRectZero];
            view.contentMode = UIViewContentModeScaleAspectFill;
            view.clipsToBounds = YES;
        }
        
        // 视图配置
        view.image = [UIImage imageNamed:(NSString *)item];
        
        return view;
    };
    
    self.bannerView.bannerDidSelectBlock = ^(PowerfulBannerView *banner, NSInteger index) {
        printf("banner did select index at: %zd \n", index);
    };
    
    self.bannerView.bannerIndexChangeBlock = ^(PowerfulBannerView *banner, NSInteger fromIndex, NSInteger toIndex) {
        printf("banner changed index from %zd to %zd\n", fromIndex, toIndex);
    };
    
    self.bannerView.longTagGestureHandler = ^(PowerfulBannerView *banner, NSInteger index, id item) {
        printf("banner long gesture recognized on index: %zd !\n", index);
    };
    
    self.bannerView.items = @[ @"1.jpg", @"2.jpg", @"ss-detail1.jpg", @"4.png", @"5.jpg", @"6.jpg" ];
}

- (void)bannerView:(PowerfulBannerView *)banner didScrollFrom:(NSInteger)index toIndex:(NSInteger)toIndex
{
    printf("scrollview changed index from %zd to %zd\n", index, toIndex);
}

- (IBAction)previous
{
    [self.bannerView slideToPrevious];
}

- (IBAction)next:(id)sender
{
    [self.bannerView slideToNext];
}


@end
