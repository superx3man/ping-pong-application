//
//  ContactMapAnnotationView.m
//  WheArU
//
//  Created by Calvin Ng on 9/22/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "ContactMapAnnotationView.h"


@implementation ContactMapAnnotationView
{
    UIImageView *userIconView;
}

- (id)initWithAnnotation:(ContactMapAnnotation *)contactMapAnnotation
{
    if (self = [super initWithAnnotation:contactMapAnnotation reuseIdentifier:@"ContactAnnotation"]) {
        _contactMapAnnotation = contactMapAnnotation;
        
        userIconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [userIconView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:userIconView];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[userIconView(==34)]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(userIconView)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[userIconView(==34)]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(userIconView)]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:userIconView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:userIconView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.f constant:0.f]];
        
        [userIconView setImage:[[contactMapAnnotation contactController] userIcon]];
        
        CAShapeLayer *circle = [CAShapeLayer layer];
        UIBezierPath *circularPath=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.f, 0.f, 34.f, 34.f) cornerRadius:34.f];
        [circle setPath:[circularPath CGPath]];
        [[userIconView layer] setMask:circle];
        
        [self setCanShowCallout:YES];
        [self setEnabled:YES];
    }
    return self;
}

#pragma mark - Properties

- (void)setContactMapAnnotation:(ContactMapAnnotation *)contactMapAnnotation
{
    [userIconView setImage:[[contactMapAnnotation contactController] userIcon]];
    [super setAnnotation:contactMapAnnotation];
}

@end
