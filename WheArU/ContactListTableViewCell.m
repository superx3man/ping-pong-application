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
#import "WAUConstant.h"


@implementation ContactListTableViewCell
{
    IBOutlet UIImageView *userIconImageView;
    
    IBOutlet UIButton *usernameButton;
    IBOutlet UILabel *userLastUpdatedLabel;
    IBOutlet UILabel *userLastUpdatedDescriptionLabel;
    
    IBOutlet UIScrollView *buttonsScrollView;
    IBOutlet UIButton *locateButton;
}

- (void)awakeFromNib
{
    CAShapeLayer *circle = [CAShapeLayer layer];
    UIBezierPath *circularPath=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, [userIconImageView frame].size.width, [userIconImageView frame].size.height) cornerRadius:MAX([userIconImageView frame].size.width, [userIconImageView frame].size.height)];
    [circle setPath:[circularPath CGPath]];
    [[userIconImageView layer] setMask:circle];
    
    [locateButton setImage:[[[locateButton imageView] image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    
    [self scrollToOriginalPositionAnimated:NO];
}

#pragma mark - Controls

- (IBAction)locateContact:(id)sender
{
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
    
    [UIView transitionWithView:userLastUpdatedLabel duration:kWAUContactUpdateAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^
     {
         [userLastUpdatedLabel setText:lastUpdatedDescription];
     } completion:nil];
    
    if (nextTimeInterval > 0) [self performSelector:@selector(updateLastUpdatedLabelWithCurrentTime) withObject:nil afterDelay:nextTimeInterval];
}

#pragma mark - External

- (void)scrollToOriginalPositionAnimated:(BOOL)animated
{
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
    
    [locateButton setTintColor:[contactController wordColor]];
    
    if ([contactController userIcon] != nil) [userIconImageView setImage:[contactController userIcon]];
}

#pragma mark - Delegates
#pragma mark ContactControllerDelegate

- (void)contactDidUpdateLocation:(ContactController *)controller
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLastUpdatedLabelWithCurrentTime) object:nil];
    [self updateLastUpdatedLabelWithCurrentTime];
}

- (void)contactDidUpdateUsername:(ContactController *)controller
{
    [UIView transitionWithView:userIconImageView duration:kWAUContactUpdateAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^
     {
         [usernameButton setTitle:[controller username] forState:UIControlStateNormal];
         [usernameButton setTitle:[controller username] forState:UIControlStateHighlighted];
         [usernameButton setTitle:[controller username] forState:UIControlStateSelected];
     } completion:nil];
}

- (void)contactDidUpdateUserIcon:(ContactController *)controller
{
    [UIView transitionWithView:userIconImageView duration:kWAUContactUpdateAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^
     {
         [userIconImageView setImage:[controller userIcon]];
     } completion:nil];
}

- (void)contactDidUpdateUserColor:(ContactController *)controller
{
    [UIView transitionWithView:userIconImageView duration:kWAUContactUpdateAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^
     {
         [[self contentView] setBackgroundColor:[controller userColor]];
         
         [usernameButton setTitleColor:[controller wordColor] forState:UIControlStateNormal];
         [usernameButton setTitleColor:[controller wordColor] forState:UIControlStateHighlighted];
         [usernameButton setTitleColor:[controller wordColor] forState:UIControlStateSelected];
         
         [userLastUpdatedLabel setTextColor:[controller wordColor]];
         [userLastUpdatedDescriptionLabel setTextColor:[controller wordColor]];
         
         [locateButton setTintColor:[controller wordColor]];
     } completion:nil];
}

@end
