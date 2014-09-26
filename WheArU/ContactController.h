//
//  ContactController.h
//  WheArU
//
//  Created by Calvin Ng on 9/15/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "EntityController.h"

#import "Contact.h"


typedef NS_ENUM(int, WAUContactPingStatus)
{
    WAUContactPingStatusNone,
    WAUContactPingStatusPinging,
    WAUContactPingStatusSuccess,
    WAUContactPingStatusFailed,
    WAUContactPingStatusNotification
};

@protocol ContactControllerDelegate;

@interface ContactController : EntityController

@property (nonatomic, readonly, assign) int32_t version;
@property (nonatomic, assign) int16_t ping;
@property (nonatomic, assign) int64_t lastUpdated;

@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double altitude;
@property (nonatomic, assign) double accuracy;

@property (nonatomic, assign) WAUContactPingStatus pingStatus;

- (id)initWithContact:(Contact *)contact;

- (void)addDelegate:(id<ContactControllerDelegate>)delegate;
- (void)removeDelegate:(id<ContactControllerDelegate>)delegate;

- (void)willSendNotification;
- (void)didSendNotification:(BOOL)isSuccess;

- (void)validateContactVersion:(int)version;

@end

@protocol ContactControllerDelegate <NSObject>

@optional
- (void)contactDidUpdateLocation:(ContactController *)controller;

- (void)contactDidUpdateUsername:(ContactController *)controller;
- (void)contactDidUpdateUserIcon:(ContactController *)controller;
- (void)contactDidUpdateUserColor:(ContactController *)controller;

- (void)controllerWillSendNotification:(ContactController *)controller;
- (void)controller:(ContactController *)controller didSendNotifcation:(BOOL)isSuccess;

@end
