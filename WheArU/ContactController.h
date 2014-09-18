//
//  ContactController.h
//  WheArU
//
//  Created by Calvin Ng on 9/15/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "EntityController.h"

#import "Contact.h"


typedef NS_ENUM(int, WAUContactLocationState)
{
    WAUContactLocationStateNotSet,
    WAUContactLocationStateAvailable,
    WAUContactLocationStatePending,
    WAUContactLocationStateNotAvailable
};

@protocol ContactControllerDelegate;

@interface ContactController : EntityController

@property (nonatomic, readonly, assign) int32_t version;
@property (nonatomic, assign) int64_t lastUpdated;

@property (nonatomic, assign) WAUContactLocationState locationState;

@property (nonatomic, assign) double latitude;
@property (nonatomic, assign) double longitude;
@property (nonatomic, assign) double altitude;
@property (nonatomic, assign) double accuracy;

@property (nonatomic, strong) id<ContactControllerDelegate> delegate;

- (id)initWithContact:(Contact *)contact;

@end

@protocol ContactControllerDelegate <NSObject>

@optional
- (void)contactDidUpdateUsername:(ContactController *)controller;
- (void)contactDidUpdateUserIcon:(ContactController *)controller;
- (void)contactDidUpdateUserColor:(ContactController *)controller;

@end
