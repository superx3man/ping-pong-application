//
//  ContactListTableViewCell.m
//  WheArU
//
//  Created by Calvin Ng on 9/1/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "ContactListTableViewCell.h"

#import "UIColor+Hex.h"


float const kWAUContactListUpdateAnimationDuration = 0.3f;

@implementation ContactListTableViewCell
{
    IBOutlet UIImageView *userIconImageView;
    
    IBOutlet UILabel *usernameLabel;
    IBOutlet UILabel *userLastUpdatedLabel;
    IBOutlet UILabel *userLastUpdatedDescriptionLabel;
}

- (void)awakeFromNib
{
    CAShapeLayer *circle = [CAShapeLayer layer];
    UIBezierPath *circularPath=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, [userIconImageView frame].size.width, [userIconImageView frame].size.height) cornerRadius:MAX([userIconImageView frame].size.width, [userIconImageView frame].size.height)];
    [circle setPath:[circularPath CGPath]];
    [[userIconImageView layer] setMask:circle];
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
        unit = @"just now";
    }
    else if (timeElpased < 3600) {
        nextTimeInterval = 60 - timeElpased % 60;
        count = timeElpased / 60;
        unit = @"min";
    }
    else if (timeElpased < 86400) {
        nextTimeInterval = 3600 - timeElpased % 3600;
        count = timeElpased / 3600;
        unit = @"hr";
    }
    else {
        nextTimeInterval = 86400 - timeElpased % 86400;
        count = timeElpased / 86400;
        unit = @"day";
    }
    
    if (count > 1) unit = [NSString stringWithFormat:@"%@s", unit];
    NSString *lastUpdatedDescription = count > 0 ? [NSString stringWithFormat:@"%lld%@", count, unit] : [NSString stringWithFormat:@"%@", unit];
    
    [UIView transitionWithView:userLastUpdatedLabel duration:kWAUContactListUpdateAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^
     {
         [userLastUpdatedLabel setText:lastUpdatedDescription];
     } completion:nil];
    
    if (nextTimeInterval > 0) [self performSelector:@selector(updateLastUpdatedLabelWithCurrentTime) withObject:nil afterDelay:nextTimeInterval];
}

#pragma mark - Properties

- (void)setContact:(ContactController *)contactController
{
    _contactController = contactController;
    [contactController setDelegate:self];
    
    [usernameLabel setText:[contactController username]];
    [[self contentView] setBackgroundColor:[contactController userColor]];
    
    [self updateLastUpdatedLabelWithCurrentTime];
    
    [usernameLabel setTextColor:[contactController wordColor]];
    [userLastUpdatedLabel setTextColor:[contactController wordColor]];
    [userLastUpdatedDescriptionLabel setTextColor:[contactController wordColor]];
    
    if ([contactController userIcon] != nil) [userIconImageView setImage:[contactController userIcon]];
}

#pragma mark - Delegates
#pragma mark ContactControllerDelegate

- (void)contactDidUpdateUserIcon:(ContactController *)controller
{
    [UIView transitionWithView:userIconImageView duration:kWAUContactListUpdateAnimationDuration options:UIViewAnimationOptionTransitionCrossDissolve animations:^
     {
         [userIconImageView setImage:[controller userIcon]];
     } completion:nil];
}

@end
