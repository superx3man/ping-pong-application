//
//  HelpNonAnimatedTransitioning.m
//  WheArU
//
//  Created by Calvin Ng on 10/1/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "HelpNonAnimatedTransitioning.h"


@implementation HelpNonAnimatedTransitioning

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.f;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext
{
}

@end
