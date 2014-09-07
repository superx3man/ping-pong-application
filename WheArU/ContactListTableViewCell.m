//
//  ContactListTableViewCell.m
//  WheArU
//
//  Created by Calvin Ng on 9/1/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "ContactListTableViewCell.h"

#import "UIColor+Hex.h"

@implementation ContactListTableViewCell
{
    IBOutlet UIImageView *userIconImageView;
    
    IBOutlet UILabel *usernameLabel;
    IBOutlet UILabel *userLastUpdatedLabel;
}

- (void)awakeFromNib
{
}

#pragma mark - Properties

- (void)setContact:(Contact *)contact
{
    _contact = contact;
    
    [usernameLabel setText:[contact username]];
    [[self contentView] setBackgroundColor:[UIColor colorFromHexString:[contact userColor]]];
}

@end
