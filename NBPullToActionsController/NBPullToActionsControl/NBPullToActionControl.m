//
//  NBPullToActionControl.m
//  NBPullToActionControl
//
//  Created by Xu Zhe on 2013/09/04.
//  Copyright (c) 2014 xuzhe.com. All rights reserved.
//

#import "NBPullToActionControl.h"
#import <THObserversAndBinders/THObserversAndBinders.h>

#define kDefaultHeightOfMyself             58.0f
#define kDefaultMaxActionFireSpeed         500.0f
#define kShadowHeight                      1.0f
#define kImageAndTitleSpacing              1.0f

static __strong UIFont *__defaultFont = nil;

@interface NBPullToActionCellContentView : UIView

- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title;
@end

@implementation NBPullToActionCellContentView {
    UIImage *_image;
    NSString *_title;

    CGSize _titleSize;
}

- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title {
    self = [super init];
    if (self) {
        NSAssert(image || title, @"You should at least set a image or a title");
        
        self.backgroundColor = [UIColor clearColor];
        _image = image;
        _title = title;
        
        CGRect bounds = CGRectZero;
        
        if (image) {
            bounds.size = image.size;
        }
        if (title && [title length] > 0) {
            NSAssert(__defaultFont, @"You should always set default font first");
            
            _titleSize = [title sizeWithAttributes:@{NSFontAttributeName:__defaultFont}];
            if (image) {
                bounds.size.height += kImageAndTitleSpacing;
            }
            bounds.size.height += _titleSize.height;
            bounds.size.width = MAX(bounds.size.width, _titleSize.width);
        }
        
        self.frame = bounds;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    if (_image) {
        [_image drawAtPoint:CGPointMake(floorf((rect.size.width - _image.size.width) * 0.5f), 0)];
    }
    if (_title && [_title length] > 0) {
        [_title drawAtPoint:CGPointMake(floorf((rect.size.width - _titleSize.width) * 0.5f), _image ? _image.size.height + kImageAndTitleSpacing : 0.0f) withAttributes:@{NSFontAttributeName:__defaultFont}];
    }
}

@end

@implementation NBPullToActionCell {
    NBPullToActionCellContentView *_contentView;
    UIActivityIndicatorView *_indicatorView;
    CGFloat _displayPercent;
}

- (instancetype)initWithImage:(UIImage *)image title:(NSString *)title {
    self = [super init];
    if (self) {
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        
        [self addSubview:({
            _contentView = [[NBPullToActionCellContentView alloc] initWithImage:image title:title];
            _contentView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
            _contentView.center = self.center;
            _contentView;
        })];
        
        [self addSubview:({
            _arrowView = [[UIView alloc] initWithFrame:self.bounds];
            _arrowView.backgroundColor = [UIColor clearColor];
            _arrowView.clipsToBounds = NO;
            _arrowView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
            _arrowView;
        })];
        
        [self addSubview:({
            _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            _indicatorView.center = self.center;
            _indicatorView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleRightMargin;
            _indicatorView.hidesWhenStopped = YES;
            _indicatorView.hidden = YES;
            _indicatorView;
        })];
    }
    return self;
}

- (void)layoutSubviews {
    _contentView.center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    _indicatorView.center = _contentView.center;
}

- (void)showActivityIndicator {
    _contentView.hidden = YES;
    [_indicatorView startAnimating];
}

- (void)hideActivityIndicator {
    _contentView.hidden = NO;
    [_indicatorView stopAnimating];
}

- (void)rotateArrowView:(BOOL)toIdentity {
    if (!_arrowView) {
        return;
    }
    if (toIdentity) {
        _arrowView.transform = CGAffineTransformMakeRotation(M_PI);
        [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
            _arrowView.transform = CGAffineTransformIdentity;
        }];
    } else {
        _arrowView.transform = CGAffineTransformIdentity;
        [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
            _arrowView.transform = CGAffineTransformMakeRotation(M_PI);
        }];
    }
}

- (void)rotateArrowViewWithPercent:(CGFloat)percent {
    // TODO: Rotate Arrow with gesture
}

- (void)displayPercent:(CGFloat)percent {
    percent = MIN(MAX(percent, 0.0f), 1.0f);    // make sure percent between 0 ~ 1.0
    _displayPercent = percent;
    
    _contentView.alpha = MAX(percent, 0.3f);
    
    CGFloat scale = 0.4f + 0.6f * percent;
    _contentView.transform = CGAffineTransformMakeScale(scale, scale);
}

- (CGFloat)displayPercent {
    return _displayPercent;
}

@end

@interface NBPullToActionControl ()

@property (nonatomic, assign) BOOL isRefreshing;
@property (nonatomic, assign) UIEdgeInsets originalEdgeInsets;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, assign) CGPoint offset;
@property (nonatomic, assign) CGFloat lastSpeed;

@end

@implementation NBPullToActionControl {
    THObserver *_contentOffsetObserver;
    THObserver *_contentSizeObserver;
    
    NBPullToActionCell *_actionCell;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _height = kDefaultHeightOfMyself;
        _maxActionFireSpeed = kDefaultMaxActionFireSpeed;
        
        self.frame = CGRectMake(0.0f, 0.0f, [UIScreen mainScreen].bounds.size.width, _height);
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.clipsToBounds = NO;
        self.backgroundColor = [UIColor clearColor];
        self.alpha = 0.0f;
        
        _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognized:)];
        _panGestureRecognizer.delegate = self;
        
        _actionCell = nil;
    }
    return self;
}

- (instancetype)initWithPullToActionCell:(NBPullToActionCell *)cell {
    if ((self = [self init])) {
        _actionCell = cell;
        [self addSubview:_actionCell];
        
        _actionCell.translatesAutoresizingMaskIntoConstraints = NO;
        _actionCell.frame = CGRectInset(self.bounds, 0.0f, kShadowHeight);
        _actionCell.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)dealloc {
    [self.superview removeGestureRecognizer:_panGestureRecognizer];
}

+ (void)setDefaultFont:(UIFont *)font {
    __defaultFont = font;
}

- (void)relayoutMe:(UIScrollView *)superview {
    if (![superview isKindOfClass:[UIScrollView class]]) return;
    
    CGRect frame = self.frame;
    frame.size.width = superview.frame.size.width;
    if (_style == NBPullToActionStyleBottom) {
        frame.origin.y = superview.contentSize.height;
    } else {
        frame.origin.y = -_height;
    }
    frame.size.height = _height;
    self.frame = frame;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (_style == NBPullToActionStyleBottom && [self.superview isKindOfClass:[UIScrollView class]]) {
        [self relayoutMe:(UIScrollView *)self.superview];
    }
}

- (void)setOffset:(CGPoint)offset {
    _offset = offset;
    [_actionCell displayPercent:MAX(MIN(offset.y / self.height, 1.0f), 0.0f)];
}

- (void)setStyle:(NBPullToActionStyle)style {
    if (style == _style) {
        return;
    }
    _style = style;
    [self setNeedsLayout];
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];
    if (!enabled) {
        self.hidden = YES;
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (newSuperview && [newSuperview isEqual:self.superview]) return;
    
    // Clean old stuffs
    if (self.superview) [self.superview removeGestureRecognizer:_panGestureRecognizer];
    if (_contentOffsetObserver) [_contentOffsetObserver stopObserving];
    if (_contentSizeObserver) [_contentSizeObserver stopObserving];
    
    if (!newSuperview || ![newSuperview isKindOfClass:[UIScrollView class]]) return;
    
    __weak UIScrollView *scrollView = (UIScrollView *)newSuperview;
    scrollView.alwaysBounceVertical = YES;
    [self relayoutMe:scrollView];
    
    __weak __typeof(self) weakMe = self;
    _contentOffsetObserver = [THObserver observerForObject:newSuperview keyPath:@"contentOffset" oldAndNewBlock:^(id oldValue, id newValue) {
        __strong UIScrollView *strongScrollView = scrollView;
        __strong __typeof(weakMe) strongMe = weakMe;
        if (!strongScrollView || !strongMe) return;
        
        CGPoint offset = [newValue CGPointValue];
        if (strongMe.style == NBPullToActionStyleBottom) {  // Do not merge the two "if" here for performance reason
            if (strongScrollView.contentSize.height > strongScrollView.bounds.size.height - strongScrollView.contentInset.top) {
                offset.y -= (strongScrollView.contentSize.height - strongScrollView.bounds.size.height);
            } else {
                offset.y += strongScrollView.contentInset.top;
            }
        } else {
            offset.y += strongScrollView.contentInset.top;
            offset.y = -offset.y;
        }
        strongMe.offset = offset;
        
        if (!strongMe.isRefreshing) {
            strongMe.alpha = offset.y < 0.0f ? 0.0f : MIN(((offset.y) / strongMe.height), 1.0f);
        }
        
    }];
    if (_style == NBPullToActionStyleBottom) {
        _contentSizeObserver = [THObserver observerForObject:newSuperview keyPath:@"contentSize" oldAndNewBlock:^(id oldValue, id newValue) {
            __strong UIScrollView *strongScrollView = scrollView;
            if (!strongScrollView) return;
            [weakMe relayoutMe:strongScrollView];
        }];
    }
    
    [newSuperview addGestureRecognizer:_panGestureRecognizer];
}

- (void)beginRefreshing {
    if (_isRefreshing) {
        return;
    }
    _isRefreshing = YES;
    if (_actionCell) [_actionCell showActivityIndicator];
    if (![self.superview isKindOfClass:[UIScrollView class]]) {
        return;
    }
    UIScrollView *scrollView = (UIScrollView *)self.superview;
    UIEdgeInsets edgeInsets = scrollView.contentInset;
    _originalEdgeInsets = edgeInsets;
    
    edgeInsets.top += self.frame.size.height;
    [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
        scrollView.contentInset = edgeInsets;
    }];
}

- (void)hideActivityIndicators {
    if (_actionCell) [_actionCell hideActivityIndicator];
}

- (void)endRefreshing {
    [self endRefreshingWithCompletionBlock:nil];
}


- (void)endRefreshingWithCompletionBlock:(void (^)(void))block {
    if (!_isRefreshing) {
        return;
    }
    if (![self.superview isKindOfClass:[UIScrollView class]]) {
        [self hideActivityIndicators];
        _isRefreshing = NO;
        return;
    }
    
    [UIView animateWithDuration:kDefaultAnimationDuration animations:^{
        ((UIScrollView *)self.superview).contentInset = _originalEdgeInsets;
    } completion:^(BOOL finished) {
        if (block) block();
        [self hideActivityIndicators];
        _isRefreshing = NO;
    }];
}

- (void)panGestureRecognized:(UIPanGestureRecognizer *)gestureRecognizer {
    if (!self.enabled || _isRefreshing || ![gestureRecognizer isEqual:_panGestureRecognizer]) return;
    
    if (gestureRecognizer.state == UIGestureRecognizerStateChanged) {
        _lastSpeed = [gestureRecognizer velocityInView:self].y;
    } else if (gestureRecognizer.state == UIGestureRecognizerStateEnded && abs(_lastSpeed) <= self.maxActionFireSpeed) {
        if ((_style == NBPullToActionStyleTop && self.offset.y >= self.frame.size.height) ||
            (_style == NBPullToActionStyleBottom && -self.offset.y >= self.frame.size.height)) {
            [self sendActionsForControlEvents:UIControlEventValueChanged];
            [self beginRefreshing];
        }
    }
}

#pragma mark - UIGestureRecognizer
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}


@end
