//
//  ContactListViewController.h
//  WheArU
//
//  Created by Calvin Ng on 8/31/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ContactListController.h"
#import "UserController.h"


@interface ContactListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UserControllerDelegate, ContactListControllerDelegate>

@end
