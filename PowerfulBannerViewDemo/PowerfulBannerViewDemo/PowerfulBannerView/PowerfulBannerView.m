//
//  PowerfulBannerView.m
//
//  Created by gaoqiang xu on 5/26/15.
//  Copyright (c) 2015 SealedCompany. All rights reserved.
//

#import "PowerfulBannerView.h"
#import "InfiniteScrollView.h"

typedef NS_ENUM(NSInteger, BannerTouchState) {
    BannerTouchState_Began,
    BannerTouchState_Ended
};


@interface PowerfulBannerView ()
<InfiniteScrollViewDataSource, UIScrollViewDelegate>
@property (strong, nonatomic) InfiniteScrollView *scrollView;
@property (nonatomic) BannerTouchState touchState;
@end

@implementation PowerfulBannerView

#pragma mark - Getters
- (UIScrollView *)scrollView
{
    if (!_scrollView) {
        __weak typeof(self)weakSelf = self;
        _scrollView = [[InfiniteScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.dataSource = self;
        _scrollView.delegate = self;
        _scrollView.pagingEnabled = YES;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.indexChangeBlock = ^(NSInteger newIndex, NSInteger oldIndex) {
            [weakSelf scrollViewIndexChangedFromIndex:oldIndex _:newIndex];
        };
    }
    return _scrollView;
}

- (NSInteger)currentIndex
{
    return self.scrollView.currentIndex;
}

#pragma mark - Setters
- (void)setItems:(NSArray *)items
{
    _items = items;
    
    if (items.count <= 1) {
        self.scrollView.scrollEnabled = NO;
    } else {
        self.scrollView.scrollEnabled = YES;
    }
    
    self.scrollView.frame = self.scrollView.frame;
}

- (void)setInfiniteLooping:(BOOL)infiniteLooping
{
    if (_infiniteLooping == infiniteLooping) {
        return;
    }
    
    _infiniteLooping = infiniteLooping;
    if (!infiniteLooping) {
        self.autoLooping = NO;
    }
    
    self.scrollView.infiniteScrolling = infiniteLooping;
}

- (void)setAutoLooping:(BOOL)autoLooping
{
    if (_autoLooping == autoLooping) {
        return;
    }
    
    _autoLooping = autoLooping;
    
    if (autoLooping) {
        self.infiniteLooping = YES;
        [self autoSlide];
    } else {
        [self cancelSlide];
    }
}

#pragma mark -
- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupViews];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupViews];
    }
    
    return self;
}

- (void)dealloc
{
    _scrollView.delegate = nil;
}

- (void)setupViews
{
    _loopingInterval = 2;
    _infiniteLooping = NO;
    _autoLooping = NO;
    _touchState = BannerTouchState_Ended;
    self.backgroundColor = [UIColor whiteColor];
    
    [self addSubview:self.scrollView];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    _scrollView.frame = self.bounds;
}

- (void)didMoveToWindow
{
    if (self.window) {
        // 这里检查并修正在移出屏幕时位置不正的位移
        
        CGFloat scale = self.scrollView.contentOffset.x / CGRectGetWidth(self.scrollView.frame);
        CGFloat fragment = scale - (long)scale;
        if (fragment > FLT_EPSILON) {
            scale = (long)scale + round(fragment);
            self.scrollView.contentOffset = CGPointMake(CGRectGetWidth(self.scrollView.frame)*scale, self.scrollView.contentOffset.y);
        }
        
        [self autoSlide];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    if (!newWindow) {
        [self cancelSlide];
    }
}

- (void)didMoveToSuperview
{
    if (!self.superview) {
        return;
    }
    
    [self autoSlide];
}

- (void)autoSlide
{
    if (self.superview
        && self.window
        && self.autoLooping
        && self.infiniteLooping
        && BannerTouchState_Ended == self.touchState) {
        
        [self.scrollView performSelector:@selector(slideToNext) withObject:nil afterDelay:self.loopingInterval];
    }
}

- (void)cancelSlide
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self.scrollView selector:@selector(slideToNext) object:nil];
}

#pragma mark - InfiniteScrollViewDataSource

- (UIView *)itemViewForIndex:(NSInteger)index reusableItemView:(UIView *)view
{
    if (self.items.count == 0
        || !self.bannerItemConfigurationBlock) {
        return [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    id item = self.items[index];
    view = self.bannerItemConfigurationBlock(self, item, view);
 
    return view;
}

- (NSInteger)viewCycleCount
{
    return self.items.count;
}

- (void)scrollViewIndexChangedFromIndex:(NSInteger)fromIndex _:(NSInteger)toIndex
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(bannerView:didScrollFrom:toIndex:)]) {
        
        [self.delegate bannerView:self didScrollFrom:fromIndex toIndex:toIndex];
    }
    
    [self autoSlide];
}

- (void)touchesBegan
{
    // 取消自动滑动
    [self cancelSlide];
    
    self.touchState = BannerTouchState_Began;
}

- (void)touchesEnded
{
    self.touchState = BannerTouchState_Ended;
    
    // 尝试恢复自动滑动
    [self autoSlide];
    
    !self.bannerDidSelectBlock ?: self.bannerDidSelectBlock(self, self.currentIndex);
}

- (void)touchesCancelled
{
    
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self touchesBegan];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    self.touchState = BannerTouchState_Ended;
    
    // 尝试恢复自动滑动
    [self autoSlide];
}

@end
