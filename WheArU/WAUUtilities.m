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
    return [[UIApplication sharedApplication] applicationState] == UIApplicationStateBackground;
}

+ (BOOL)shouldShowHelpScreen:(NSString *)identifier
{
    NSString *userDefaultKey = [NSString stringWithFormat:@"ShouldShowHelpScreen%@", identifier];
    BOOL shouldShow = [[NSUserDefaults standardUserDefaults] objectForKey:userDefaultKey] == nil;
    if (shouldShow) [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:userDefaultKey];
    return shouldShow;
}

+ (BOOL)shouldShowUserHelpScreen
{
    return [self shouldShowHelpScreen:@"User"];
}

+ (BOOL)shouldShowContactHelpScreen
{
    return [self shouldShowHelpScreen:@"Contact"];
}

+ (BOOL)shouldShowMapHelpScreen
{
    return [self shouldShowHelpScreen:@"Map"];
}

+ (void)callDelegateList:(NSArray *)delegateList withSelector:(SEL)selector
{
    @synchronized(delegateList) {
        for (id retainedDelegate in delegateList) {
            id delegate = [retainedDelegate nonretainedObjectValue];
            if ([delegate respondsToSelector:selector]) [delegate performSelector:selector withObject:self];
        }
    }
}

@end
