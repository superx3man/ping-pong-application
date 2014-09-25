//
//  ContactListTableViewCell.h
//  WheArU
//
//  Created by Calvin Ng on 9/1/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ContactController.h"


@protocol ContactListTableViewCellDelegate;

@interface ContactListTableViewCell : UITableViewCell <ContactControllerDelegate>

@property (nonatomic, strong) ContactController *contactController;
@property (nonatomic, weak) id<ContactListTableViewCellDelegate> delegate;

- (void)scrollToOriginalPositionAnimated:(BOOL)animated;

@end

@protocol ContactListTableViewCellDelegate <NSObject>

@optional
- (void)tableViewCell:(ContactListTableViewCell *)cell didTapOnButton:(ContactController *)controller;
- (void)tableViewCell:(ContactListTableViewCell *)cell didReleaseButton:(ContactController *)controller;

- (void)tableViewCell:(ContactListTableViewCell *)cell didSwipeWithContactController:(ContactController *)controller;

@end
