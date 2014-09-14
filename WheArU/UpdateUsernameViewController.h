//
//  UpdateUsernameViewController.h
//  WheArU
//
//  Created by Calvin Ng on 9/7/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UserController.h"

@interface UpdateUsernameViewController : UIViewController <UITextViewDelegate>

@property (nonatomic, strong) UserController *userController;

@end