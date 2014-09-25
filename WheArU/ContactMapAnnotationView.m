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
    UIView *userLabelBackgroundView;
    UILabel *userLabel;
    
    CAShapeLayer *circleMask;
}

- (id)initWithAnnotation:(ContactMapAnnotation *)contactMapAnnotation
{
    if (self = [super initWithAnnotation:contactMapAnnotation reuseIdentifier:@"ContactAnnotation"]) {
        _contactMapAnnotation = contactMapAnnotation;
        
        circleMask = [CAShapeLayer layer];
        UIBezierPath *circularPath=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.f, 0.f, 34.f, 34.f) cornerRadius:34.f];
        [circleMask setPath:[circularPath CGPath]];
        
        userIconView = [[UIImageView alloc] initWithFrame:CGRectZero];
        [userIconView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [self addSubview:userIconView];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[userIconView(==34)]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(userIconView)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[userIconView(==34)]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(userIconView)]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:userIconView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:userIconView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.f constant:0.f]];
        
        userLabelBackgroundView = [[UIView alloc] initWithFrame:CGRectZero];
        [userLabelBackgroundView setTranslatesAutoresizingMaskIntoConstraints:NO];
        [userLabelBackgroundView setClipsToBounds:YES];
        [self addSubview:userLabelBackgroundView];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[userLabelBackgroundView(==34)]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(userLabelBackgroundView)]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[userLabelBackgroundView(==34)]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(userLabelBackgroundView)]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:userLabelBackgroundView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:userLabelBackgroundView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterY multiplier:1.f constant:0.f]];
        
        userLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [userLabel setTranslatesAutoresizingMaskIntoConstraints:NO];
        [userLabel setFont:[UIFont fontWithName:@"Avenir-Roman" size:20.f]];
        [userLabel setTextAlignment:NSTextAlignmentCenter];
        [userLabelBackgroundView addSubview:userLabel];
        
        [userLabelBackgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[userLabel(==34)]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(userLabel)]];
        [userLabelBackgroundView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[userLabel(==34)]" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(userLabel)]];
        [userLabelBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:userLabel attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:userLabelBackgroundView attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
        [userLabelBackgroundView addConstraint:[NSLayoutConstraint constraintWithItem:userLabel attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:userLabelBackgroundView attribute:NSLayoutAttributeCenterY multiplier:1.f constant:0.f]];
        
        [self setUserViewHiddenState:[contactMapAnnotation contactController]];
        
        [self setCanShowCallout:YES];
        [self setEnabled:YES];
    }
    return self;
}

#pragma mark - Functions
#pragma mark Support

- (void)setUserViewHiddenState:(ContactController *)contactController
{
    UIImage *userIcon = [contactController userIcon];
    NSString *usernameFirstLetter = [[[contactController username] substringToIndex:1] uppercaseString];
    if (userIcon != nil) {
        [userIconView setImage:userIcon];
        [[userIconView layer] setMask:circleMask];
        [userIconView setHidden:NO];
        [userLabelBackgroundView setHidden:YES];
    }
    else {
        [userLabel setText:usernameFirstLetter];
        [userLabel setTextColor:[contactController wordColor]];
        [userLabelBackgroundView setBackgroundColor:[contactController userColor]];
        [[userLabelBackgroundView layer] setMask:circleMask];
        [userLabelBackgroundView setHidden:NO];
        [userIconView setHidden:YES];
    }
}

#pragma mark - Properties

- (void)setContactMapAnnotation:(ContactMapAnnotation *)contactMapAnnotation
{
    [self setUserViewHiddenState:[contactMapAnnotation contactController]];
    [super setAnnotation:contactMapAnnotation];
}

@end
