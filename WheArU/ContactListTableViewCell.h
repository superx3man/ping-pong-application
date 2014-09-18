//
//  ContactListTableViewCell.h
//  WheArU
//
//  Created by Calvin Ng on 9/1/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ContactController.h"


extern float const kWAUContactListUpdateAnimationDuration;

@interface ContactListTableViewCell : UITableViewCell <ContactControllerDelegate>

@property (nonatomic, strong) ContactController *contactController;

- (void)setContact:(ContactController *)contactController;

@end
