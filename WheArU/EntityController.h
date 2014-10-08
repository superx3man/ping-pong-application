//
//  EntityController.h
//  WheArU
//
//  Created by Calvin Ng on 9/15/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


typedef NS_ENUM(int, WAUUserPlatformType)
{
    WAUUserPlatformTypeIOS,
    WAUUserPlatformTypeIOSDev,
    WAUUserPlatformTypeAndroid
};

@interface EntityController : NSObject

@property (nonatomic, readonly, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSString *userId;

@property (nonatomic, assign) WAUUserPlatformType platform;
@property (nonatomic, strong) NSString *notificationKey;

@property (nonatomic, strong) NSString *username;

@property (nonatomic, strong) UIColor *userColor;
@property (nonatomic, readonly, strong) UIColor *wordColor;

@property (nonatomic, strong) UIImage *userIcon;

+ (NSArray *)availableUserColor;

@end
