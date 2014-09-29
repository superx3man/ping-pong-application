//
//  WAUUtilities.h
//  WheArU
//
//  Created by Calvin Ng on 9/28/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface WAUUtilities : NSObject

+ (BOOL)isUserNotificationBadgeEnabled;
+ (BOOL)isApplicationRunningInBackground;

@end
