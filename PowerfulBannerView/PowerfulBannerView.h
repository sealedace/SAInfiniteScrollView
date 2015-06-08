//
//  PowerfulBannerView.h
//
//  Created by gaoqiang xu on 5/26/15.
//  Copyright (c) 2015 SealedCompany. All rights reserved.
//  Version 1.0.3

#import <UIKit/UIKit.h>

@class PowerfulBannerView;
@protocol PowerfulBannerPageControl;

/**
 @brief  返回一个需要展示的内容视图，相当于dataSource回调
 
 @param banner PowerfulBannerView对象
 @param item   需要展示的视图数据
 @param reusableView  重用的视图（如果有的话，没有即nil）
 
 @return 内容页视图
 
 @since 1.0.0
 */
typedef UIView *(^PowerfulBannerViewItemConfigration)(PowerfulBannerView *banner, id item, UIView *reusableView);
typedef void(^PowerfulBannerViewDidSelectAtIndex)(PowerfulBannerView *banner, NSInteger index);
typedef void(^PowerfulBannerViewDidUpdateIndex)(PowerfulBannerView *banner, NSInteger fromIndex, NSInteger toIndex);

@interface PowerfulBannerView : UIView
{
    __strong id <PowerfulBannerPageControl> _pageControl;
}

// banner内容的model数组
@property (strong, nonatomic) NSArray *items;
// banner当前展示的index
@property (readonly, nonatomic) NSInteger currentIndex;
// 设置自动循环的时间间隔(单位:s), 默认2s
@property (nonatomic) CFTimeInterval loopingInterval;
// banner展示内容的数据源配置
@property (copy, nonatomic) PowerfulBannerViewItemConfigration bannerItemConfigurationBlock;
// banner点击事件回调
@property (copy, nonatomic) PowerfulBannerViewDidSelectAtIndex bannerDidSelectBlock;
// banner滑动index变动的回调
@property (copy, nonatomic) PowerfulBannerViewDidUpdateIndex bannerIndexChangeBlock;

// 开启/关闭循环模式 注：infiniteLooping设为NO 会自动把 autoLooping 设为NO
@property (nonatomic) BOOL infiniteLooping;
// 开启/关闭自动循环滚动  注：autoLooping设为YES 会自动把 infiniteLooping 设为YES
@property (nonatomic) BOOL autoLooping;
// PageControl
@property (strong, nonatomic) id pageControl;

/**
 @brief  重新加载视图数据
 
 @since 1.0.2
 */
- (void)reloadData;

@end

/**
 @brief  支持PageControl
 
 @since 1.0.3
 */
@protocol PowerfulBannerPageControl<NSObject>
@required
@property (nonatomic) NSInteger numberOfPages;
@property (nonatomic) NSInteger currentPage;

@end
