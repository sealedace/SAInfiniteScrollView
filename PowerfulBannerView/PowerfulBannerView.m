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
@property (nonatomic) BOOL isActive;// 用于标记app active状态
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;

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
        _scrollView.scrollsToTop = NO;
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

- (UIPanGestureRecognizer *)panGesture
{
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(doNothing)];
    }

    return _panGesture;
}

#pragma mark - Setters
- (void)setPageControl:(id)pageControl
{
    if (![pageControl respondsToSelector:@selector(setNumberOfPages:)]
        || ![pageControl respondsToSelector:@selector(setCurrentPage:)]) {
        
        _pageControl = nil;
    } else {
        
        _pageControl = pageControl;
    }
}

- (id)pageControl
{
    return _pageControl;
}

- (void)setItems:(NSArray *)items
{
    [self cancelSlide];
    
    BOOL shouldReConfigure = (_items.count != items.count);
    
    _items = items;
    
    if (items.count <= 1) {
        self.scrollView.scrollEnabled = NO;
    } else {
        self.scrollView.scrollEnabled = YES;
    }
    
    if (shouldReConfigure) {
        [self.scrollView resetViews];
    } else {
        [self reloadData];
    }
    
    _pageControl.numberOfPages = items.count;
    _pageControl.currentPage = self.currentIndex;
    
    self.autoLooping = self.autoLooping;
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
    [self cancelSlide];
    _autoLooping = autoLooping;
    
    if (autoLooping) {
        self.infiniteLooping = YES;
        [self autoSlide];
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
    [self cancelSlide];
    _scrollView.delegate = nil;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupViews
{
    _longTapTriggerTime = 1.f;// default is 1s
    _isActive = YES;
    _loopingInterval = 2;
    _infiniteLooping = NO;
    _autoLooping = NO;
    _touchState = BannerTouchState_Ended;
    self.backgroundColor = [UIColor whiteColor];
    
    [self addSubview:self.scrollView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
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
        && BannerTouchState_Ended == self.touchState
        && self.isActive
        && self.items.count > 1) {
        
        [self.scrollView performSelector:@selector(slideToNext) withObject:nil afterDelay:self.loopingInterval];
    }
}

- (void)cancelSlide
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self.scrollView selector:@selector(slideToNext) object:nil];
}

- (void)doNothing
{
    
}

- (void)transferScrollViewGesture
{
    [self addGestureRecognizer:self.panGesture];
}

- (void)restoreScrollViewGesture
{
    [self removeGestureRecognizer:self.panGesture];
}

- (void)appDidBecomeActive
{
    // app 激活 恢复轮播
    self.isActive = YES;
    [self autoSlide];
}

- (void)appWillResignActive
{
    // app 未激活状态取消自动轮播
    self.isActive = NO;
    [self cancelSlide];
}

#pragma mark - InfiniteScrollViewDataSource

- (UIView *)itemViewForIndex:(NSInteger)index reusableItemView:(UIView *)view
{
    if (self.items.count == 0
        || !self.bannerItemConfigurationBlock) {
        return nil;
    }
    
    if (index < 0 || index >= self.items.count) {
        return nil;
    }
    
    id item = self.items[index];
    view = self.bannerItemConfigurationBlock(self, item, view);
 
    _pageControl.numberOfPages = self.items.count;
    _pageControl.currentPage = self.currentIndex;
    
    return view;
}

- (NSInteger)viewCycleCount
{
    return self.items.count;
}

- (void)scrollViewIndexChangedFromIndex:(NSInteger)fromIndex _:(NSInteger)toIndex
{
    _pageControl.currentPage = toIndex;
    
    !self.bannerIndexChangeBlock ?: self.bannerIndexChangeBlock(self, fromIndex, toIndex);
    
    [self autoSlide];
}

- (void)touchesBegan
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longGestureTriggered) object:nil];
    // 取消自动滑动
    [self cancelSlide];
    
    self.touchState = BannerTouchState_Began;
    
    if (!self.scrollView.isDragging && self.longTapGestureHandler && self.longTapTriggerTime > 0) {
        [self performSelector:@selector(longGestureTriggered) withObject:nil afterDelay:self.longTapTriggerTime];
    }
}

- (void)touchesEnded
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longGestureTriggered) object:nil];
    
    self.touchState = BannerTouchState_Ended;
    
    // 尝试恢复自动滑动
    [self autoSlide];
  
    !self.bannerDidSelectBlock ?: self.bannerDidSelectBlock(self, self.currentIndex);
}

- (void)touchesMoved
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longGestureTriggered) object:nil];
}

- (void)touchesCancelled
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longGestureTriggered) object:nil];
    
    self.touchState = BannerTouchState_Ended;
    
    // 尝试恢复自动滑动
    [self autoSlide];
    
    if ([[UIApplication sharedApplication] isIgnoringInteractionEvents]) {
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
    }
}

- (void)longGestureTriggered
{
    [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
    self.longTapGestureHandler(self, self.currentIndex, self.items[self.currentIndex], self.currentContentView);
    
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self touchesBegan];
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(longGestureTriggered) object:nil];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    self.touchState = BannerTouchState_Ended;
    
    // 尝试恢复自动滑动
    [self autoSlide];
}

#pragma mark - Public
- (void)reloadData
{
    [self.scrollView reloadViews];
}

- (void)slideToNext
{
    if (self.currentIndex == self.items.count-1) {
        return;
    }
    
    [self.scrollView slideToNext];
}

- (void)slideToPrevious
{
    if (self.currentIndex == 0) {
        return;
    }
    
    [self.scrollView slideToPrevious];
}

- (UIView *)currentContentView
{
    return self.scrollView.currentContentView;
}

@end
