//
//  Internal.h
//  WheArU
//
//  Created by Calvin Ng on 9/16/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


extern NSString *const kWAUCoreDataEntityInternal;

@interface Internal : NSManagedObject

@property (nonatomic, retain) NSString *android;
@property (nonatomic, retain) NSString *ios;

@property (nonatomic) int64_t expiration;

@end
