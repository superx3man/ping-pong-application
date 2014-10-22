//
//  LocationController.m
//  WheArU
//
//  Created by Calvin Ng on 9/18/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "LocationController.h"

#import "AppDelegate.h"

#import "WAUConstant.h"
#import "WAULog.h"


@implementation LocationController
{
    CLLocationManager *locationManager;
    
    NSMutableArray *updateBlockList;
}

- (id)init
{
    if (self = [super init]) {
        updateBlockList = [[NSMutableArray alloc] init];
        
        locationManager = [[CLLocationManager alloc] init];
        [locationManager requestAlwaysAuthorization];
        
        [locationManager setDelegate:self];
        [locationManager setDesiredAccuracy:kCLLocationAccuracyBestForNavigation];
        [locationManager setDistanceFilter:kCLDistanceFilterNone];
    }
    return self;
}

#pragma mark - Singleton Class

+ (LocationController *)sharedInstance
{
    static LocationController *sharedInstance = nil;
    
    @synchronized(self) {
        if (sharedInstance == nil) sharedInstance = [[LocationController alloc] init];
    }
    return sharedInstance;
}

#pragma mark - Functions
#pragma mark Support

- (void)handleDeniedLocationPermission
{
    [locationManager stopUpdatingLocation];
}

#pragma mark External

- (void)retrieveLocationWithUpdateBlock:(void (^)(CLLocation *))updateHandler
{
    [locationManager startUpdatingLocation];
    @synchronized(updateBlockList) {
        [updateBlockList addObject:updateHandler];
    }
}

#pragma mark - Delegates
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    static float currentRetryCount = 0;
    if ([updateBlockList count] == 0) return;
    
    CLLocation *mostRecentLocation = [locations lastObject];
    float accuracy = [mostRecentLocation horizontalAccuracy];
    NSTimeInterval timeDifference = [[NSDate date] timeIntervalSinceDate:[mostRecentLocation timestamp]];
    [WAULog log:[NSString stringWithFormat:@"accuracy: %f time difference: %f", accuracy, timeDifference] from:self];
    
    if (accuracy > kWAULocationTargetAccuracy || timeDifference > 10.f) {
        currentRetryCount++;
        if (currentRetryCount <= kWAULocationMaximumRetryFetch) return;
    }
    currentRetryCount = 0;
    
    @synchronized(updateBlockList) {
        for (void (^updateHandler)(CLLocation *) in updateBlockList) {
            updateHandler(mostRecentLocation);
        }
        [updateBlockList removeAllObjects];
    }
    
    [locationManager stopUpdatingLocation];
    if ([updateBlockList count] != 0) [locationManager startUpdatingLocation];
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    if ([error code] != kCLErrorDenied) return;
    
    [self handleDeniedLocationPermission];
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
    if (status != kCLAuthorizationStatusDenied) return;
    
    [self handleDeniedLocationPermission];
}

@end
