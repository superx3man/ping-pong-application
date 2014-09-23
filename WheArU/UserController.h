//
//  UserController.h
//  WheArU
//
//  Created by Calvin Ng on 9/15/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EntityController.h"


@protocol UserControllerDelegate;

@interface UserController : EntityController

@property (nonatomic, assign) int fetchCount;
@property (nonatomic, assign, setter = setModified:) BOOL isModified;

+ (UserController *)sharedInstance;

- (void)addDelegate:(id<UserControllerDelegate>)delegate;

- (BOOL)isUserRegistered;
- (void)createUser;

- (NSString *)QRCodeDescription;

@end

@protocol UserControllerDelegate <NSObject>

@optional
- (void)controllerDidSetUserId:(UserController *)controller;

- (void)userDidUpdateUsername:(UserController *)controller;
- (void)userDidUpdateUserIcon:(UserController *)controller;
- (void)userDidUpdateUserColor:(UserController *)controller;

@end
