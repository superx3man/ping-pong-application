//
//  NotificationController.h
//  WheArU
//
//  Created by Calvin Ng on 9/16/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Security/Security.h>

#import "AppDelegate.h"
#import "ContactController.h"
#import "EncryptionController.h"


extern NSString *const kWAUNotificationCategoryIdentifierRequestLocation;
extern NSString *const kWAUNotificationActionIdentifierSend;

@protocol NotificationControllerDelegate;

@interface NotificationController : NSObject <EncryptionControllerDelegate, NotificationRegistrationDelegate, ApplicationStateChangeDelegate>

+ (NotificationController *)sharedInstance;

- (void)addDelegate:(id<NotificationControllerDelegate>)delegate;
- (void)removeDelegate:(id<NotificationControllerDelegate>)delegate;

- (void)requestForLocationFromContact:(ContactController *)contact;
- (void)requestForLocationFromContact:(ContactController *)contact inBackground:(UIBackgroundTaskIdentifier)taskIdentifier;
- (void)syncLocationRequestFromServer;
- (void)syncLocationRequestFromServerInBackground:(UIBackgroundTaskIdentifier)taskIdentifier;

@end

@protocol NotificationControllerDelegate <NSObject>

@end
