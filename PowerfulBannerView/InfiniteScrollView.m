//
//  InfiniteScrollView.m
//
//  Created by gaoqiang xu on 5/26/15.
//  Copyright (c) 2015 SealedCompany. All rights reserved.
//

#import "InfiniteScrollView.h"

static NSInteger const dequeueLevel = 4;

@interface InfiniteScrollView ()

@property (nonatomic, strong) NSMutableArray *visibleViews;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic) NSInteger currentIndex;
@property (weak, nonatomic) UIView *centerView;
@property (nonatomic) int centerViewLastPosition;

@end

@implementation InfiniteScrollView

- (NSMutableArray *)visibleViews
{
    if (!_visibleViews) {
        _visibleViews = [[NSMutableArray alloc] initWithCapacity:dequeueLevel];
    }
    return _visibleViews;
}

- (UIView *)containerView
{
    if (!_containerView) {
        _containerView = [[UIView alloc] init];
    }
    return _containerView;
}

- (void)setCurrentIndex:(NSInteger)currentIndex
{
    if (_currentIndex == currentIndex) {
        return;
    }
    
    NSInteger oldIndex = _currentIndex;
    _currentIndex = currentIndex;
    
    !self.indexChangeBlock ?: self.indexChangeBlock(currentIndex, oldIndex);
}

- (void)setInfiniteScrolling:(BOOL)infiniteScrolling
{
    _infiniteScrolling = infiniteScrolling;
    
    [self configure];
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self configure];
}

- (void)setContentSize:(CGSize)contentSize
{
    // 如果一样就不需要重新设置，避免内容发生不正确的偏移
    if (CGSizeEqualToSize(self.contentSize, contentSize)) {
        return;
    }

    [super setContentSize:contentSize];
}

- (void)configure
{
    if (self.infiniteScrolling) {
        CGSize contentSize = CGSizeMake(13*self.frame.size.width, self.frame.size.height);
        self.contentSize = contentSize;
    } else {
        if (self.dataSource) {
            self.contentSize = CGSizeMake([self.dataSource viewCycleCount] * CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
        }
    }
    
    self.containerView.frame = CGRectMake(0, 0, self.contentSize.width, self.contentSize.height);
    [self addSubview:self.containerView];
//        [self.containerView setUserInteractionEnabled:NO];
}

- (void)initialize
{
    _infiniteScrolling = NO;
    _currentIndex = 0;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
    {
        [self initialize];
        [self configure];
    }
    return self;
}

- (void)slideToPrevious
{
    if ([self.layer animationKeys].count > 0
        || [self.dataSource viewCycleCount] <= 1) {
        return;
    }
    
    CGPoint currentOffset = self.contentOffset;
    CGFloat scale = currentOffset.x / CGRectGetWidth(self.bounds);
    
    if ((scale-(int)scale) > FLT_EPSILON) {
        return;
    }
    
    currentOffset.x -= CGRectGetWidth(self.bounds);
    
    [self setContentOffset:currentOffset animated:YES];
}

- (void)slideToNext
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
    
    if ([self.layer animationKeys].count > 0
        || [self.dataSource viewCycleCount] <= 1) {
        return;
    }

    CGPoint currentOffset = self.contentOffset;
    CGFloat scale = currentOffset.x / CGRectGetWidth(self.bounds);
    
    if ((scale-(int)scale) > FLT_EPSILON) {
        return;
    }
    
    currentOffset.x += CGRectGetWidth(self.bounds);
    
    [self setContentOffset:currentOffset animated:YES];
}

- (void)resetViews
{
    [self.visibleViews removeAllObjects];
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    _currentIndex = 0;
    self.frame = self.frame;
}

- (void)reloadViews
{
    for (UIView *view in self.visibleViews) {
        if (view.subviews.count == 0) {
            continue;
        }

        [self.dataSource itemViewForIndex:[self getIndexForContentView:view] reusableItemView:[view.subviews firstObject]];
    }
}

- (UIView *)currentContentView
{
    if (self.visibleViews.count == 0) {
        return nil;
    }
    
    __block UIView *content = nil;
    
    [self.visibleViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIView *view = obj;
        CGRect rect = [self convertRect:view.frame toView:self.superview];
        if (CGRectContainsRect(self.superview.bounds, rect) ) {
            NSArray *sub = view.subviews;
            if (sub.count > 0) {
                content = sub[0];
            }
            *stop = YES;
        }
    }];
    
    return content;
}

#pragma mark - Layout

// recenter content periodically to achieve impression of infinite scrolling
- (void)recenterIfNecessary
{
    CGPoint currentOffset = [self contentOffset];
    CGFloat contentWidth = [self contentSize].width;
    CGFloat centerOffsetX = (contentWidth - [self bounds].size.width) / 2.f;
    CGFloat distanceFromCenter = fabs(currentOffset.x - centerOffsetX);
    
    CGFloat scale = fabs(currentOffset.x / self.bounds.size.width);
    long decimalPart = (long)scale;
    float fractionalPart = scale - decimalPart;
    
    if (distanceFromCenter > (contentWidth / 4.f)) {
        
        // 这里关闭事件来让scrollview获取一定时间恢复以重置offset
        self.userInteractionEnabled = NO;
        // 这里转移手势，目的是为了维持手势，否则手势可能会穿透到其他视图层
        [self.dataSource transferScrollViewGesture];
        
        if ((fractionalPart < FLT_EPSILON || (1-fractionalPart) < FLT_EPSILON)) {
            
            self.contentOffset = CGPointMake(centerOffsetX, currentOffset.y);
            
            // move content by the same amount so it appears to stay still
            for (UIView *view in self.visibleViews) {
                CGPoint center = [self.containerView convertPoint:view.center toView:self];
                center.x += (centerOffsetX - currentOffset.x);
                view.center = [self convertPoint:center toView:self.containerView];
            }
            
            // 重新开启事件
            self.userInteractionEnabled = YES;
            [self.dataSource restoreScrollViewGesture];
        }
    } else {
        self.userInteractionEnabled = YES;
        [self.dataSource restoreScrollViewGesture];
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    if ([self.dataSource viewCycleCount] == 0) {
        return;
    }
 
    if (self.infiniteScrolling) {
        [self recenterIfNecessary];
    }
    
    // tile content in visible bounds
    CGRect visibleBounds = [self convertRect:[self bounds] toView:self.containerView];
    CGFloat minimumVisibleX = CGRectGetMinX(visibleBounds) - CGRectGetWidth(visibleBounds);
    CGFloat maximumVisibleX = CGRectGetMaxX(visibleBounds) + CGRectGetWidth(visibleBounds);
    
    [self tileViewsFromMinX:minimumVisibleX toMaxX:maximumVisibleX _:visibleBounds];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(touchesBegan)]) {
        [self.dataSource touchesBegan];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(touchesMoved)]) {
        [self.dataSource touchesMoved];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(touchesEnded)]) {
        [self.dataSource touchesEnded];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    
    if (self.dataSource && [self.dataSource respondsToSelector:@selector(touchesCancelled)]) {
        [self.dataSource touchesCancelled];
    }
}

#pragma mark - View Tiling

- (CGFloat)placeNewViewOnCenter:(CGFloat)x
{
    UIView *view = [[UIView alloc] initWithFrame:self.bounds];
    CGRect frame = [view frame];
    frame.origin.x = x;
    frame.origin.y = [self.containerView bounds].size.height - frame.size.height;
    // will place the view to the destination position
    
    [view setFrame:frame];
    [self.containerView addSubview:view];
    
    self.centerView = view;
    _centerViewLastPosition = 0;
    
    [self.visibleViews addObject:view];
    
    UIView *contentView = [self.dataSource itemViewForIndex:0 reusableItemView:nil];
    contentView.frame = view.bounds;
    [view addSubview:contentView];
    
    return CGRectGetMaxX(frame);
}

- (CGFloat)placeNewViewOnRight:(CGFloat)rightEdge reusableView:(UIView *)view
{
    UIView *theView = view?:[[UIView alloc] initWithFrame:self.bounds];
    CGRect frame = [theView frame];
    frame.origin.x = rightEdge;
    frame.origin.y = [self.containerView bounds].size.height - frame.size.height;
    
    [theView setFrame:frame];
    [self.containerView addSubview:theView];
    
    UIView *reusableItemView = nil;
    if (view && view.subviews.count > 0) {
        reusableItemView = [theView.subviews firstObject];
    }

    
    [theView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    if (view) {
        
        NSInteger index = [self.visibleViews indexOfObject:view];
        [self.visibleViews removeObjectAtIndex:index];
    }
    
    [self.visibleViews addObject:theView]; // add rightmost view at the end of the array
    
    UIView *cv = [self.dataSource itemViewForIndex:[self getIndexForContentView:theView] reusableItemView:reusableItemView];
    cv.frame = theView.bounds;
    [theView addSubview:cv];
    
    return CGRectGetMaxX(frame);
}

- (CGFloat)placeNewViewOnLeft:(CGFloat)leftEdge reusableView:(UIView *)view
{
    UIView *theView = view?:[[UIView alloc] initWithFrame:self.bounds];
    CGRect frame = [theView frame];
    frame.origin.x = leftEdge - frame.size.width;
    frame.origin.y = [self.containerView bounds].size.height - frame.size.height;
    [theView setFrame:frame];
    [self.containerView addSubview:theView];
    
    UIView *reusableItemView = nil;
    if (view && view.subviews.count > 0) {
        reusableItemView = [theView.subviews firstObject];
    }
    
    [theView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    if (view) {
        
        NSInteger index = [self.visibleViews indexOfObject:theView];
        [self.visibleViews removeObjectAtIndex:index];
    }
    
    [self.visibleViews insertObject:theView atIndex:0]; // add leftmost view at the beginning of the array
    
    UIView *cv = [self.dataSource itemViewForIndex:[self getIndexForContentView:theView] reusableItemView:reusableItemView];
    cv.frame = theView.bounds;
    [theView addSubview:cv];
    
    return CGRectGetMinX(frame);
}

static inline NSInteger fixIndex(NSInteger index, NSInteger total)
{
    NSInteger newIndex = index;
    
    if (index >= total) {
        newIndex = index - total;
    } else if (index < 0) {
        newIndex = total + index;
    }
    
    return newIndex;
}

- (NSInteger)getIndexForContentView:(UIView *)view
{
    CGRect visibleBounds = [self convertRect:[self bounds] toView:self.containerView];
    
    NSInteger scale = round( (CGRectGetMinX(view.frame)-CGRectGetMinX(visibleBounds))/CGRectGetWidth(visibleBounds) );
    
    return fixIndex((self.currentIndex+scale), [self.dataSource viewCycleCount]);
}

- (void)tileViewsFromMinX:(CGFloat)minimumVisibleX toMaxX:(CGFloat)maximumVisibleX _:(CGRect)visibleBounds
{
    // the upcoming tiling logic depends on there already being at least one view in the visibleViews array, so
    // to kick off the tiling we need to make sure there's at least two views
    if ([self.visibleViews count] == 0) {
        
        CGFloat leftEdge = CGRectGetMinX(visibleBounds);
        if (self.infiniteScrolling) {
            [self placeNewViewOnLeft:leftEdge reusableView:nil];
        }
        [self placeNewViewOnCenter:leftEdge];
        
    }
    
    UIView *reusableView = nil;
    
    // get the view that have fallen off right edge for reuse
    UIView *lastView = [self.visibleViews lastObject];
    if ([lastView frame].origin.x > maximumVisibleX) {
        
        reusableView = lastView;
    }
    
    if (!reusableView) {
        // get the view that have fallen off left edge for reuse
        UIView *firstView = [self.visibleViews firstObject];
        if (CGRectGetMaxX([firstView frame]) < minimumVisibleX) {
            
            reusableView = firstView;
        }
    }
    
    // add views that are missing on right side
    lastView = [self.visibleViews lastObject];
    CGFloat rightEdge = CGRectGetMaxX([lastView frame]);
    if (rightEdge < maximumVisibleX) {
        
        if (!self.infiniteScrolling && maximumVisibleX > self.contentSize.width) {
            
        } else {
            [self placeNewViewOnRight:rightEdge reusableView:reusableView];
        }
        
    } else {
        
        // add views that are missing on left side
        UIView *firstView = [self.visibleViews firstObject];
        CGFloat leftEdge = CGRectGetMinX([firstView frame]);
        if (leftEdge > minimumVisibleX) {
            
            if (!self.infiniteScrolling && minimumVisibleX <= 0) {
                
            } else {
                [self placeNewViewOnLeft:leftEdge reusableView:reusableView];
            }
        }
    }
    
    CGFloat scale = ( CGRectGetMinX(self.centerView.frame) - CGRectGetMinX(visibleBounds) ) / CGRectGetWidth(visibleBounds);
    int s = round(scale);
    
    if (s - self.centerViewLastPosition == 1) {
        
        self.currentIndex = fixIndex(self.currentIndex-1, [self.dataSource viewCycleCount]);
        self.centerViewLastPosition = s;
        
    } else if (s - self.centerViewLastPosition == -1) {
        
        self.currentIndex = fixIndex(self.currentIndex+1, [self.dataSource viewCycleCount]);
        self.centerViewLastPosition = s;
        
    } else if (s - self.centerViewLastPosition == 4 || s - self.centerViewLastPosition == -4) {
        
        self.centerViewLastPosition = s;
    }
}

- (UIView *)contentViewAtIndex:(NSInteger)index
{
    return self.visibleViews[index];
}

@end
