//
//  Contact.h
//  WheArU
//
//  Created by Calvin Ng on 9/1/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface Contact : NSManagedObject

extern NSString *const kWAUCoreDataEntityContact;

@property (nonatomic, retain) NSString *userId;

@property (nonatomic, retain) NSData *notificationKey;

@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *userColor;

@property (nonatomic, retain) NSData *userIcon;
@property (nonatomic, retain) NSString *userIconLink;

@property (nonatomic) int16_t platform;
@property (nonatomic) int32_t version;

@property (nonatomic) int64_t lastUpdated;

@property (nonatomic) int16_t locationState;

@property (nonatomic) double latitude;
@property (nonatomic) double longitude;
@property (nonatomic) double altitude;
@property (nonatomic) double accuracy;

@end
