//
//  WAUUtilities.m
//  WheArU
//
//  Created by Calvin Ng on 9/28/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "WAUUtilities.h"


@implementation WAUUtilities

+ (AppDelegate *)applicationDelegate
{
    return (AppDelegate *) [[UIApplication sharedApplication] delegate];
}

+ (BOOL)isUserNotificationBadgeEnabled
{
    UIUserNotificationSettings *settings = [[UIApplication sharedApplication] currentUserNotificationSettings];
    return ([settings types] & UIUserNotificationTypeBadge) == 1;
}

+ (BOOL)isApplicationRunningInBackground
{
    return [[UIApplication sharedApplication] applicationState] != UIApplicationStateActive;
}

@end
