//
//  ThirdViewController.m
//  
//
//  Created by gaoqiang xu on 1/9/2015.
//
//

#import "ThirdViewController.h"
#import "PowerfulBannerView.h"

@interface ThirdViewController ()
@property (weak, nonatomic) IBOutlet PowerfulBannerView *bannerView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation ThirdViewController

- (void)viewDidLoad {
    [super viewDidLoad];

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
    
    self.bannerView.longTapGestureHandler = ^(PowerfulBannerView *banner, NSInteger index, id item, UIView *view) {
        printf("banner long gesture recognized on index: %zd !\n", index);
    };
    
    self.bannerView.items = @[ @"1.jpg", @"2.jpg", @"ss-detail1.jpg", @"4.png", @"5.jpg", @"6.jpg" ];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)*2);
}

@end
