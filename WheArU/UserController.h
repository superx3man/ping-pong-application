//
//  UserController.h
//  WheArU
//
//  Created by Calvin Ng on 9/6/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "User.h"

@protocol UserControllerDelegate;

@interface UserController : NSObject

@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) UIImage *userIcon;
@property (nonatomic, strong) UIColor *userColor;

@property (nonatomic, readonly, strong) UIColor *wordColor;

@property (nonatomic, assign) int fetchCount;

- (void)addDelegate:(id<UserControllerDelegate>)delegate;

- (BOOL)isUserRegistered;
- (void)createUser;

+ (NSArray *)availableUserColor;

@end

@protocol UserControllerDelegate <NSObject>

- (void)userDidUpdateUsername:(UserController *)controller;
- (void)userDidUpdateUserIcon:(UserController *)controller;
- (void)userDidUpdateUserColor:(UserController *)controller;

@end