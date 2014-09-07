//
//  User.h
//  WheArU
//
//  Created by Calvin Ng on 9/6/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

extern NSString *const kWAUCoreDataEntityUser;

@property (nonatomic, retain) NSString *userId;

@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSData *userIcon;
@property (nonatomic, retain) NSString *userColor;

@property (nonatomic) int32_t fetchCount;
@property (nonatomic) int32_t version;

@end
