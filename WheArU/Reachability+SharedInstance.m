//
//  Reachability+SharedInstance.m
//  WheArU
//
//  Created by Calvin Ng on 9/17/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "Reachability+SharedInstance.h"

#import "AppDelegate.h"

#import "WAUConstant.h"


@implementation Reachability (SharedInstance)

#pragma mark - Singleton Class

+ (Reachability *)sharedInstance
{
    static Reachability *sharedInstance = nil;
    
    @synchronized(self) {
        if (sharedInstance == nil) {
            sharedInstance = [Reachability reachabilityWithHostname:kWAUServerEndpoint];
            [sharedInstance setReachableOnWWAN:YES];
            [sharedInstance startNotifier];
        }
    }
    return sharedInstance;
}

@end
