//
//  UIScrollView+APParallaxHeader.m
//
//  Created by Mathias Amnell on 2013-04-12.
//  Copyright (c) 2013 Apping AB. All rights reserved.
//

#import "UIScrollView+APParallaxHeader.h"

#import <QuartzCore/QuartzCore.h>

@interface APParallaxView ()

@property (nonatomic, readwrite) BOOL isExtended;

@property (nonatomic, readwrite) APParallaxTrackingState state;
@property (nonatomic, readwrite) APParallaxAnimatingState animatingState;

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, readwrite) CGFloat originalTopInset;
@property (nonatomic) CGFloat parallaxHeight;

@property(nonatomic, assign) BOOL isObserving;

@end



#pragma mark - UIScrollView (APParallaxHeader)
#import <objc/runtime.h>

static char UIScrollViewParallaxView;

@implementation UIScrollView (APParallaxHeader)

- (void)addParallaxWithImage:(UIImage *)image andHeight:(CGFloat)height {
    if(self.parallaxView) {
        if(self.parallaxView.currentSubView) [self.parallaxView.currentSubView removeFromSuperview];
        [self.parallaxView.imageView setImage:image];
    }
    else
    {
        APParallaxView *view = [[APParallaxView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, height)];
        [view setClipsToBounds:YES];
        [view.imageView setImage:image];
        
        view.scrollView = self;
        view.parallaxHeight = height;
        view.animatingState = APParallaxAnimatingInactive;
        [self addSubview:view];
        
        view.originalTopInset = self.contentInset.top;
        
        UIEdgeInsets newInset = self.contentInset;
        newInset.top = height;
        self.contentInset = newInset;
        
        self.parallaxView = view;
        self.showsParallax = YES;
    }
}

- (void)addParallaxWithView:(UIView*)view andHeight:(CGFloat)height {
    if(self.parallaxView) {
        [self.parallaxView.currentSubView removeFromSuperview];
        [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [self.parallaxView addSubview:view];
    }
    else
    {
        APParallaxView *parallaxView = [[APParallaxView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, height)];
        [parallaxView setClipsToBounds:YES];
        [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        [parallaxView addSubview:view];
        
        parallaxView.scrollView = self;
        parallaxView.parallaxHeight = height;
        [self addSubview:parallaxView];
        
        parallaxView.originalTopInset = self.contentInset.top;
        
        UIEdgeInsets newInset = self.contentInset;
        newInset.top = height;
        self.contentInset = newInset;
        
        self.parallaxView = parallaxView;
        self.showsParallax = YES;
    }
}

- (void)setParallaxView:(APParallaxView *)parallaxView {
    objc_setAssociatedObject(self, &UIScrollViewParallaxView,
                             parallaxView,
                             OBJC_ASSOCIATION_ASSIGN);
}

- (APParallaxView *)parallaxView {
    return objc_getAssociatedObject(self, &UIScrollViewParallaxView);
}

- (void)setShowsParallax:(BOOL)showsParallax {
    self.parallaxView.hidden = !showsParallax;
    
    if(!showsParallax) {
        if (self.parallaxView.isObserving) {
            [self removeObserver:self.parallaxView forKeyPath:@"contentOffset"];
            [self removeObserver:self.parallaxView forKeyPath:@"frame"];
            self.parallaxView.isObserving = NO;
        }
    }
    else {
        if (!self.parallaxView.isObserving) {
            [self addObserver:self.parallaxView forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
            [self addObserver:self.parallaxView forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
            self.parallaxView.isObserving = YES;
        }
    }
}

- (BOOL)showsParallax {
    return !self.parallaxView.hidden;
}

@end

#pragma mark - ShadowLayer

@implementation APParallaxShadowView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setOpaque:NO];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    
    //// Gradient Declarations
    NSArray* gradient3Colors = [NSArray arrayWithObjects:
                                (id)[UIColor colorWithWhite:0 alpha:0.3].CGColor,
                                (id)[UIColor clearColor].CGColor, nil];
    CGFloat gradient3Locations[] = {0, 1};
    CGGradientRef gradient3 = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)gradient3Colors, gradient3Locations);
    
    //// Rectangle Drawing
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: CGRectMake(0, 0, CGRectGetWidth(rect), 8)];
    CGContextSaveGState(context);
    [rectanglePath addClip];
    CGContextDrawLinearGradient(context, gradient3, CGPointMake(0, CGRectGetHeight(rect)), CGPointMake(0, 0), 0);
    CGContextRestoreGState(context);
    
    
    //// Cleanup
    CGGradientRelease(gradient3);
    CGColorSpaceRelease(colorSpace);

}

@end

#pragma mark - APParallaxView

@implementation APParallaxView

- (id)initWithFrame:(CGRect)frame {
    if(self = [super initWithFrame:frame]) {
        
        // default styling values
        [self setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [self setState:APParallaxTrackingActive];
        [self setAutoresizesSubviews:YES];
        
        self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), CGRectGetHeight(frame))];
        [self.imageView setAutoresizingMask:UIViewAutoresizingFlexibleHeight];
        [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
        [self.imageView setClipsToBounds:YES];
        [self addSubview:self.imageView];
        
        self.shadowView = [[APParallaxShadowView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(frame)-8, CGRectGetWidth(frame), 8)];
        [self.shadowView setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
        [self addSubview:self.shadowView];
        
        UITapGestureRecognizer* recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(toggleFullView)];
        recognizer.numberOfTapsRequired = 1;
        [self addGestureRecognizer:recognizer];
        
        self.isExtended = NO;
        self.allowsExtension = NO;
        self.extensionHeight = 400.0f;
        self.extensionThreshold = -300.0f;
    }
    
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (self.superview && newSuperview == nil) {
        UIScrollView *scrollView = (UIScrollView *)self.superview;
        if (scrollView.showsParallax) {
            if (self.isObserving) {
                //If enter this branch, it is the moment just before "APParallaxView's dealloc", so remove observer here
                [scrollView removeObserver:self forKeyPath:@"contentOffset"];
                [scrollView removeObserver:self forKeyPath:@"frame"];
                self.isObserving = NO;
            }
        }
    }
}

- (void)addSubview:(UIView *)view
{
    [super addSubview:view];
    self.currentSubView = view;
}

#pragma mark - Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"contentOffset"])
        [self scrollViewDidScroll:[[change valueForKey:NSKeyValueChangeNewKey] CGPointValue]];
    else if([keyPath isEqualToString:@"frame"])
        [self layoutSubviews];
}

- (void)scrollViewDidScroll:(CGPoint)contentOffset {
    
    if (self.allowsExtension && contentOffset.y < self.extensionThreshold && self.animatingState == APParallaxAnimatingInactive) {
        [self toggleFullView];
    }
    
    // We do not want to track when the parallax view is hidden
    if (contentOffset.y > 0) {
        [self setState:APParallaxTrackingInactive];
    } else {
        [self setState:APParallaxTrackingActive];
    }
    
    if(self.state == APParallaxTrackingActive && ((self.animatingState == APParallaxAnimatingInactive && contentOffset.y != -self.scrollView.contentInset.top)||
                                                  (self.animatingState == APParallaxAnimatingDown && contentOffset.y == -self.extensionHeight) ||
                                                  (self.animatingState == APParallaxAnimatingUp && contentOffset.y == -self.scrollView.contentInset.top)))
    {
        CGFloat yOffset = contentOffset.y*-1;
        [self setFrame:CGRectMake(0, contentOffset.y, CGRectGetWidth(self.frame), yOffset)];
    }
    
}

- (void)toggleFullView {
    CGPoint offset;
    CGPoint prevOffset = self.scrollView.contentOffset;

    if (!self.isExtended) {
        self.animatingState = APParallaxAnimatingDown;
        [self.scrollView setScrollEnabled:NO];
        offset = CGPointMake(0, -self.extensionHeight);
    } else {
        [self.scrollView setScrollEnabled:NO];
        self.animatingState = APParallaxAnimatingUp;
        offset = CGPointMake(0, -self.scrollView.contentInset.top);
    }
    
    // workaround to prevent "jump" before the animation starts
    [self.scrollView setContentOffset:prevOffset animated:NO];
    
    [UIView animateWithDuration:0.0 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        // workaround for a case when header is being extended while not scrolled to top
        if (self.scrollView.contentOffset.y > -self.scrollView.contentInset.top) {
            self.scrollView.contentOffset = CGPointMake(self.scrollView.contentOffset.x, -self.scrollView.contentInset.top);
            [self setFrame:CGRectMake(0, self.scrollView.contentOffset.y, CGRectGetWidth(self.frame), -self.scrollView.contentOffset.y)];
        }
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.scrollView.contentOffset = offset;
        } completion:^(BOOL finished) {
            [self.scrollView setScrollEnabled:YES];
            
            self.isExtended = !self.isExtended;
            self.animatingState = APParallaxAnimatingInactive;
        }];
    }];
}

@end
