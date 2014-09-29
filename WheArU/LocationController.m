//
//  LocationController.m
//  WheArU
//
//  Created by Calvin Ng on 9/18/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "LocationController.h"

#import "AppDelegate.h"


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

- (void)retrieveLocationWithUpdateBlock:(void (^)(CLLocation *))updateHandler synchrounous:(BOOL)isSynchrounous
{
    [locationManager startUpdatingLocation];
    if (isSynchrounous) {
        updateHandler([locationManager location]);
        [locationManager stopUpdatingLocation];
        if ([updateBlockList count] != 0) [locationManager startUpdatingLocation];
    }
    else {
        [updateBlockList addObject:updateHandler];
    }
}

#pragma mark - Delegates
#pragma mark CLLocationManagerDelegate

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *mostRecentLocation = [locations lastObject];
    for (void (^updateHandler)(CLLocation *) in updateBlockList) {
        updateHandler(mostRecentLocation);
        [updateBlockList removeObject:updateHandler];
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
