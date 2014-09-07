//
//  ContactListViewController.h
//  WheArU
//
//  Created by Calvin Ng on 8/31/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "HVTableView.h"

#import "UserController.h"

@interface ContactListViewController : UIViewController <UserControllerDelegate, HVTableViewDelegate, HVTableViewDataSource>

@end
