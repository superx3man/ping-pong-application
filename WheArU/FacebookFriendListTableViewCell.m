//
//  FacebookFriendListTableViewCell.m
//  WheArU
//
//  Created by Calvin Ng on 9/30/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "FacebookFriendListTableViewCell.h"

#import "UserController.h"


@implementation FacebookFriendListTableViewCell
{
    IBOutlet UILabel *nameLabel;
    IBOutlet UIImageView *pictureImageView;
}

- (void)awakeFromNib
{
    [nameLabel setTextColor:[[UserController sharedInstance] wordColor]];
    [self setTintColor:[[UserController sharedInstance] wordColor]];
    
    [[pictureImageView layer] setMasksToBounds:YES];
    [[pictureImageView layer] setCornerRadius:2.f];
}

#pragma mark - Functions
#pragma mark Support

- (void)downloadPicture
{
    if ([[self user] pictureLink] == nil) return;
    
    NSURL *url = [NSURL URLWithString:[[self user] pictureLink]];
    NSData *data = [NSData dataWithContentsOfURL:url];
    
    if (data != nil) {
        [[self user] setPicture:[[UIImage alloc] initWithData:data]];
        [self performSelectorInBackground:@selector(setPicture) withObject:nil];
    }
}

- (void)setPicture
{
    [pictureImageView setImage:[[self user] picture]];
}

#pragma mark - Properties

- (void)setUser:(FacebookUser *)user
{
    _user = user;
    
    [nameLabel setText:[user name]];
    if ([user pictureLink] != nil) {
        if ([user picture] == nil) [self performSelectorInBackground:@selector(downloadPicture) withObject:nil];
        else [self setPicture];
    }
}


@end
