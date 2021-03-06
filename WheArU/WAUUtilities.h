//
//  WAUUtilities.h
//  WheArU
//
//  Created by Calvin Ng on 9/28/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "AppDelegate.h"


@interface WAUUtilities : NSObject

+ (AppDelegate *)applicationDelegate;

+ (BOOL)isUserNotificationBadgeEnabled;

+ (BOOL)isApplicationRunningInForeground;
+ (BOOL)isApplicationRunningInBackground;

+ (BOOL)shouldShowUserHelpScreen;
+ (BOOL)shouldShowContactHelpScreen;
+ (BOOL)shouldShowMapHelpScreen;

+ (void)performSelector:(SEL)selector onDelegateList:(NSArray *)delegateList withObject:(id)object;

+ (void)endBackgroundTask:(UIBackgroundTaskIdentifier)taskIdentifier;

@end
