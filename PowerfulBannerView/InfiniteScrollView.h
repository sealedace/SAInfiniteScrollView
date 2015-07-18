//
//  InfiniteScrollView.h
//
//  Created by gaoqiang xu on 5/26/15.
//  Copyright (c) 2015 SealedCompany. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol InfiniteScrollViewDataSource <NSObject>
@required
/**
 @brief  获取需要展示的内容
 
 @param index 内容索引
 @param view  可以用来复用的内容
 
 @return 内容视图
 
 @since 1.0.0
 */
- (UIView *)itemViewForIndex:(NSInteger)index reusableItemView:(UIView *)view;

/**
 @brief  一个循环的总数
 
 @return 数量
 
 @since 1.0.0
 */
- (NSInteger)viewCycleCount;

/**
 @brief  触摸开始事件捕获
 
 @since 1.0.0
 */
- (void)touchesBegan;

/**
 @brief  触摸事件结束
 
 @since 1.0.0
 */
- (void)touchesEnded;

/**
 @brief  触摸事件移动
 
 @since 1.0.6
 */
- (void)touchesMoved;

/**
 @brief  触摸取消事件
 
 @since 1.0.0
 */
- (void)touchesCancelled;

/**
 @brief  转移scrollView的触摸事件，保证手势不会发生穿透
 
 @since 1.0.2
 */
- (void)transferScrollViewGesture;

/**
 @brief  InfiniteScrollView重新获取事件
 
 @since 1.0.2
 */
- (void)restoreScrollViewGesture;

@end

typedef void(^IndexChanged)(NSInteger newIndex, NSInteger oldIndex);


/**
 循环滑动的Scroll View
 */
@interface InfiniteScrollView : UIScrollView
@property (weak, nonatomic) id<InfiniteScrollViewDataSource> dataSource;
@property (nonatomic) BOOL infiniteScrolling;
@property (copy, nonatomic) IndexChanged indexChangeBlock;
@property (readonly, weak, nonatomic) UIView *currentContentView;

/**
 @brief  获取当前的索引
 
 @return 当前的索引
 
 @since 1.0.0
 */
- (NSInteger)currentIndex;

/**
 @brief  滑动到下一页
 
 @since 1.0.0
 */
- (void)slideToNext;

/**
 @brief  滑动到上一页
 
 @since 1.0.5
 */
- (void)slideToPrevious;

/**
 @brief  重置视图
 
 @since 1.0.2
 */
- (void)resetViews;

/**
 @brief  重新加载内容
 
 @since 1.0.2
 */
- (void)reloadViews;

@end
