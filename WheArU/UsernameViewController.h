//
//  UsernameViewController.h
//  WheArU
//
//  Created by Calvin Ng on 9/2/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UserController.h"

@interface UsernameViewController : UIViewController <UITextViewDelegate>

@property (nonatomic, strong) UserController *userController;

@property (nonatomic, strong) UIColor *userColor;

@end
