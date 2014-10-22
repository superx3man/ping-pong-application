//
//  ContactHelpViewController.m
//  WheArU
//
//  Created by Calvin Ng on 10/2/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "ContactHelpViewController.h"

#import "HelpNonAnimatedTransitioning.h"

@interface ContactHelpViewController ()

@end

@implementation ContactHelpViewController
{
    IBOutlet UIView *backgroundView;
    IBOutlet UIView *swipeView;
    IBOutlet UIView *holdTapView;
    
    IBOutlet UIImageView *swipeFingerImageView;
    IBOutlet UIImageView *holdTapFingerImageView;
    
    BOOL shouldAnimate;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self view] setBackgroundColor:[[UIColor darkGrayColor] colorWithAlphaComponent:0.3f]];
    [backgroundView setBackgroundColor:[[UIColor darkGrayColor] colorWithAlphaComponent:0.5f]];
    
    [swipeFingerImageView setImage:[[swipeFingerImageView image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [holdTapFingerImageView setImage:[[holdTapFingerImageView image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [swipeFingerImageView setTintColor:[UIColor whiteColor]];
    [holdTapFingerImageView setTintColor:[UIColor whiteColor]];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setViewMask];
    shouldAnimate = YES;
    [self animateSwipe];
    [self animateHoldTap];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animateSwipe) object:nil];
    shouldAnimate = NO;
    
    [super viewWillDisappear:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [self setViewMask];
     } completion:nil];
}

#pragma mark - Functions
#pragma mark Support

- (void)setViewMask
{
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    CGMutablePathRef maskPath = CGPathCreateMutable();
    CGPathAddRect(maskPath, NULL, CGRectMake(0.f, 0.f, [backgroundView frame].size.width, [backgroundView frame].size.height));
    CGPathAddPath(maskPath, nil, [[UIBezierPath bezierPathWithRoundedRect:CGRectMake([swipeView frame].origin.x - [backgroundView frame].origin.x, [swipeView frame].origin.y - [backgroundView frame].origin.y, [swipeView frame].size.width, [swipeView frame].size.height) cornerRadius:5.f] CGPath]);
    CGPathAddPath(maskPath, nil, [[UIBezierPath bezierPathWithRoundedRect:CGRectMake([holdTapView frame].origin.x - [backgroundView frame].origin.x, [holdTapView frame].origin.y - [backgroundView frame].origin.y, [holdTapView frame].size.width, [holdTapView frame].size.height) cornerRadius:5.f] CGPath]);
    [maskLayer setPath:maskPath];
    [maskLayer setFillRule:kCAFillRuleEvenOdd];
    CGPathRelease(maskPath);
    [[backgroundView layer] setMask:maskLayer];
}

- (void)animateSwipe
{
    [swipeFingerImageView setTransform:CGAffineTransformIdentity];
    [UIView animateWithDuration:1.f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^
     {
         [swipeFingerImageView setTransform:CGAffineTransformMakeTranslation(-([swipeView frame].size.width - 16.f - 32.f), 0.f)];
     } completion:^(BOOL finished)
     {
         if (finished && shouldAnimate) [self performSelector:@selector(animateSwipe) withObject:nil afterDelay:1.f];
     }];
}

- (void)animateHoldTap
{
    [holdTapFingerImageView setTransform:CGAffineTransformIdentity];
    [UIView animateWithDuration:1.f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^
     {
         [holdTapFingerImageView setTransform:CGAffineTransformMakeScale(0.85f, 0.85f)];
         [holdTapFingerImageView setTransform:CGAffineTransformMakeRotation(M_PI * -10.f / 180.0)];
     } completion:^(BOOL finished)
     {
         if (finished && shouldAnimate) [self performSelector:@selector(animateHoldTap) withObject:nil afterDelay:1.f];
     }];
}

#pragma mark - Controls
#pragma mark Gesture

- (IBAction)didTapOnScreen:(id)sender
{
    [self dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark - Delegates
#pragma mark UIViewControllerTransitioningDelegate

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source
{
    return [HelpNonAnimatedTransitioning new];
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    return [HelpNonAnimatedTransitioning new];
}

@end
