//
//  RegistrationViewController.h
//  WheArU
//
//  Created by Calvin Ng on 9/2/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "UserController.h"

@interface RegistrationViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UserController *userController;

@end
