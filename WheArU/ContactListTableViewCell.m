//
//  ContactListTableViewCell.m
//  WheArU
//
//  Created by Calvin Ng on 9/1/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "ContactListTableViewCell.h"

#import "NotificationController.h"

#import "UIColor+Hex.h"
#import "UIView+Shake.h"
#import "WAUConstant.h"


@implementation ContactListTableViewCell
{
    IBOutlet UIImageView *userIconImageView;
    
    IBOutlet UIButton *usernameButton;
    IBOutlet UILabel *userLastUpdatedLabel;
    IBOutlet UILabel *userLastUpdatedDescriptionLabel;
    
    IBOutlet UILabel *instructionLabel;
    
    IBOutlet UIScrollView *buttonsScrollView;
    IBOutlet UIButton *locateButton;
    
    IBOutlet UIView *pingStatusView;
    IBOutlet UILabel *pingNumberLabel;
    IBOutlet UIActivityIndicatorView *pingSpinner;
    IBOutlet UIImageView *pingSuccessImageView;
    IBOutlet UIImageView *pingFailedImageView;
}

- (void)awakeFromNib
{
    CAShapeLayer *circle = [CAShapeLayer layer];
    UIBezierPath *circularPath=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, [userIconImageView frame].size.width, [userIconImageView frame].size.height) cornerRadius:MAX([userIconImageView frame].size.width, [userIconImageView frame].size.height)];
    [circle setPath:[circularPath CGPath]];
    [[userIconImageView layer] setMask:circle];
    
    [[pingStatusView layer] setCornerRadius:2.f];
    
    [locateButton setImage:[[[locateButton imageView] image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(locateContactWithGesture:)];
    [longPressGesture setMinimumPressDuration:1.5f];
    [longPressGesture setAllowableMovement:50.f];
    [usernameButton addGestureRecognizer:longPressGesture];
    
    UISwipeGestureRecognizer *swipeGesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(swipeContactWithGesture:)];
    [swipeGesture setDirection:UISwipeGestureRecognizerDirectionLeft];
    [buttonsScrollView addGestureRecognizer:swipeGesture];
    
    [pingSuccessImageView setImage:[[pingSuccessImageView image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [pingFailedImageView setImage:[[pingFailedImageView image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    
    [self scrollToOriginalPositionAnimated:NO];
}

#pragma mark - Controls

- (IBAction)showTextPlaceholder:(id)sender
{
    if ([self delegate] != nil) {
        if ([[self delegate] respondsToSelector:@selector(tableViewCell:didTapOnButton:)]) [[self delegate] tableViewCell:self didTapOnButton:[self contactController]];
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1.f delay:0.f options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState) animations:^
         {
             [instructionLabel setAlpha:1.f];
             [usernameButton setAlpha:0.f];
         } completion:nil];
    });
}

- (IBAction)restoreTextPlaceholder:(id)sender
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:1.f delay:0.f options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState) animations:^
         {
             [instructionLabel setAlpha:0.f];
             [usernameButton setAlpha:1.f];
         } completion:nil];
    });
    
    if ([self delegate] != nil) {
        if ([[self delegate] respondsToSelector:@selector(tableViewCell:didReleaseButton:)]) [[self delegate] tableViewCell:self didReleaseButton:[self contactController]];
    }
}

- (void)swipeContactWithGesture:(UIGestureRecognizer *)gesture
{
    [self restoreTextPlaceholder:nil];
    
    if ([self delegate] != nil) {
        if ([[self delegate] respondsToSelector:@selector(tableViewCell:didSwipeWithContactController:)]) [[self delegate] tableViewCell:self didSwipeWithContactController:[self contactController]];
    }
}

- (void)locateContactWithGesture:(UIGestureRecognizer *)gesture
{
    if ([gesture state] != UIGestureRecognizerStateBegan) return;
    
    [self restoreTextPlaceholder:nil];
    [self locateContact:nil];
}

- (IBAction)locateContact:(id)sender
{
    [instructionLabel shakeWithDuration:0.05f offset:3.f count:2];
    [[NotificationController sharedInstance] requestForLocationFromContact:[self contactController]];
}

#pragma mark - Functions
#pragma mark Support

- (void)updateLastUpdatedLabelWithCurrentTime
{
    if ([self contactController] == nil) return;
    
    int64_t lastUpdated = [[self contactController] lastUpdated];
    int64_t timeElpased = [[NSDate date] timeIntervalSince1970] - lastUpdated;
    
    NSTimeInterval nextTimeInterval = -1;
    int64_t count = 0;
    NSString *unit = @"";
    if (timeElpased < 60) {
        nextTimeInterval = 60 - timeElpased;
        count = 0;
        unit = @"!!!";
    }
    else if (timeElpased < 3600) {
        nextTimeInterval = 60 - timeElpased % 60;
        count = timeElpased / 60;
        unit = @"mn";
    }
    else if (timeElpased < 86400) {
        nextTimeInterval = 3600 - timeElpased % 3600;
        count = timeElpased / 3600;
        unit = @"hr";
    }
    else {
        nextTimeInterval = 86400 - timeElpased % 86400;
        count = timeElpased / 86400;
        unit = @"dy";
    }
    
    if (count > 1) unit = [NSString stringWithFormat:@"%@s", unit];
    NSString *lastUpdatedDescription = count > 0 ? [NSString stringWithFormat:@"%lld%@", count, unit] : [NSString stringWithFormat:@"%@", unit];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView transitionWithView:userLastUpdatedLabel duration:kWAUContactUpdateAnimationDuration options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState) animations:^
         {
             [userLastUpdatedLabel setText:lastUpdatedDescription];
         } completion:nil];
    });
    
    if (nextTimeInterval > 0) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLastUpdatedLabelWithCurrentTime) object:nil];
        [self performSelector:@selector(updateLastUpdatedLabelWithCurrentTime) withObject:nil afterDelay:nextTimeInterval];
    }
}

- (void)layoutPingStatusView
{
    WAUContactPingStatus pingStatus = [[self contactController] pingStatus];
    
    float pingStatusViewAlpha = 0.f;
    float pingSpinnerAlpha = 0.f;
    float pingSuccessImageViewAlpha = 0.f;
    float pingFailedImageViewAlpha = 0.f;
    
    if (pingStatus == WAUContactPingStatusNotification) pingStatusViewAlpha = 1.f;
    else if (pingStatus == WAUContactPingStatusPinging) pingSpinnerAlpha = 1.f;
    else if (pingStatus == WAUContactPingStatusSuccess) pingSuccessImageViewAlpha = 1.f;
    else if (pingStatus == WAUContactPingStatusFailed) pingFailedImageViewAlpha = 1.f;
    
    if (pingStatusViewAlpha == 1.f && [pingStatusView alpha] == 1.f) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView transitionWithView:pingNumberLabel duration:kWAUContactUpdateAnimationDuration options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState) animations:^
             {
                 [pingNumberLabel setText:[NSString stringWithFormat:@"%d", MIN([[self contactController] ping], 99)]];
             } completion:nil];
        });
    }
    else {
        [pingNumberLabel setText:[NSString stringWithFormat:@"%d", MIN([[self contactController] ping], 99)]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:UIViewAnimationOptionTransitionCrossDissolve animations:^
             {
                 [pingStatusView setAlpha:pingStatusViewAlpha];
                 [pingSpinner setAlpha:pingSpinnerAlpha];
                 [pingSuccessImageView setAlpha:pingSuccessImageViewAlpha];
                 [pingFailedImageView setAlpha:pingFailedImageViewAlpha];
             } completion:^(BOOL finished)
             {
                 if (pingSpinnerAlpha == 1.f) [pingSpinner startAnimating];
                 else [pingSpinner stopAnimating];
             }];
        });
    }
}

#pragma mark - External

- (void)scrollToOriginalPositionAnimated:(BOOL)animated
{
    [instructionLabel setAlpha:0.f];
    [usernameButton setAlpha:1.f];
    
    [buttonsScrollView scrollRectToVisible:CGRectMake(0.f, 0.f, 1.f, 1.f) animated:animated];
}

#pragma mark - Properties

- (void)setContactController:(ContactController *)contactController
{
    if (_contactController != nil) [_contactController removeDelegate:self];
    _contactController = contactController;
    [contactController addDelegate:self];
    
    [usernameButton setTitle:[contactController username] forState:UIControlStateNormal];
    [usernameButton setTitle:[contactController username] forState:UIControlStateHighlighted];
    [usernameButton setTitle:[contactController username] forState:UIControlStateSelected];
    [[self contentView] setBackgroundColor:[contactController userColor]];
    
    [self updateLastUpdatedLabelWithCurrentTime];
    
    [usernameButton setTitleColor:[contactController wordColor] forState:UIControlStateNormal];
    [usernameButton setTitleColor:[contactController wordColor] forState:UIControlStateHighlighted];
    [usernameButton setTitleColor:[contactController wordColor] forState:UIControlStateSelected];
    
    [userLastUpdatedLabel setTextColor:[contactController wordColor]];
    [userLastUpdatedDescriptionLabel setTextColor:[contactController wordColor]];
    
    [instructionLabel setTextColor:[contactController wordColor]];
    
    [locateButton setTintColor:[contactController wordColor]];
    
    [pingStatusView setBackgroundColor:[[self contactController] wordColor]];
    [pingNumberLabel setTextColor:[[self contactController] userColor]];
    [pingSpinner setColor:[[self contactController] wordColor]];
    [pingSuccessImageView setTintColor:[[self contactController] wordColor]];
    [pingFailedImageView setTintColor:[[self contactController] wordColor]];
    
    [self layoutPingStatusView];
    
    [userIconImageView setImage:[contactController userIcon]];
}

#pragma mark - Delegates
#pragma mark ContactControllerDelegate

- (void)contactDidUpdateLocation:(ContactController *)controller
{
    [self updateLastUpdatedLabelWithCurrentTime];
}

- (void)contactDidUpdateUsername:(ContactController *)controller
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView transitionWithView:usernameButton duration:kWAUContactUpdateAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^
         {
             [usernameButton setTitle:[controller username] forState:UIControlStateNormal];
             [usernameButton setTitle:[controller username] forState:UIControlStateHighlighted];
             [usernameButton setTitle:[controller username] forState:UIControlStateSelected];
         } completion:nil];
    });
}

- (void)contactDidUpdateUserIcon:(ContactController *)controller
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:UIViewAnimationOptionTransitionCrossDissolve animations:^
         {
             [userIconImageView setImage:[controller userIcon]];
         } completion:nil];
    });
}

- (void)contactDidUpdateUserColor:(ContactController *)controller
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:UIViewAnimationOptionTransitionCrossDissolve animations:^
         {
             [[self contentView] setBackgroundColor:[controller userColor]];
             
             [usernameButton setTitleColor:[controller wordColor] forState:UIControlStateNormal];
             [usernameButton setTitleColor:[controller wordColor] forState:UIControlStateHighlighted];
             [usernameButton setTitleColor:[controller wordColor] forState:UIControlStateSelected];
             
             [userLastUpdatedLabel setTextColor:[controller wordColor]];
             [userLastUpdatedDescriptionLabel setTextColor:[controller wordColor]];
             
             [locateButton setTintColor:[controller wordColor]];
         } completion:nil];
    });
}

- (void)controllerWillSendNotification:(ContactController *)controller
{
    [self layoutPingStatusView];
}

- (void)controller:(ContactController *)controller didSendNotifcation:(BOOL)isSuccess
{
    [self layoutPingStatusView];
}

@end
