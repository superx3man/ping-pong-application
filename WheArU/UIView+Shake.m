//
//  UIView+Shake.m
//  WheArU
//
//  Created by Calvin Ng on 9/24/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "UIView+Shake.h"


@implementation UIView (Shake)

- (void)shakeWithDuration:(NSTimeInterval)duration offset:(float)offset
{
    CABasicAnimation *shake = [CABasicAnimation animationWithKeyPath:@"position"];
    [shake setDuration:duration];
    [shake setRepeatCount:2];
    [shake setAutoreverses:YES];
    [shake setFromValue:[NSValue valueWithCGPoint:CGPointMake([self center].x - offset, [self center].y)]];
    [shake setToValue:[NSValue valueWithCGPoint:CGPointMake([self center].x + offset, [self center].y)]];
    [[self layer] addAnimation:shake forKey:@"position"];
}

@end
