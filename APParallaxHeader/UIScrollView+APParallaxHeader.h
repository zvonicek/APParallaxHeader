//
//  UIScrollView+APParallaxHeader.h
//
//  Created by Mathias Amnell on 2013-04-12.
//  Copyright (c) 2013 Apping AB. All rights reserved.
//

#import <UIKit/UIKit.h>

@class APParallaxView;
@class APParallaxShadowView;

@interface UIScrollView (APParallaxHeader)

- (void)addParallaxWithImage:(UIImage *)image andHeight:(CGFloat)height;
- (void)addParallaxWithView:(UIView*)view andHeight:(CGFloat)height;

@property (nonatomic, strong, readonly) APParallaxView *parallaxView;
@property (nonatomic, assign) BOOL showsParallax;

@end

enum {
    APParallaxTrackingActive = 0,
    APParallaxTrackingInactive
};

typedef NSUInteger APParallaxTrackingState;


enum {
    APParallaxAnimatingInactive = 0,
    APParallaxAnimatingDown,
    APParallaxAnimatingUp,
};

typedef NSUInteger APParallaxAnimatingState;

@interface APParallaxView : UIView

@property (nonatomic, readonly) APParallaxTrackingState state;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *currentSubView;
@property (nonatomic, strong) APParallaxShadowView *shadowView;

@property (nonatomic) BOOL allowsExtension;
@property (nonatomic) CGFloat extensionHeight;
@property (nonatomic) CGFloat extensionThreshold;

@property (nonatomic, readonly) APParallaxAnimatingState animatingState;
@property (nonatomic, readonly) BOOL isExtended;

@end

@interface APParallaxShadowView : UIView

@end
