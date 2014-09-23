//
//  MKMapView+SharedInstance.m
//  WheArU
//
//  Created by Calvin Ng on 9/23/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "MKMapView+SharedInstance.h"


@implementation MKMapView (SharedInstance)

+ (MKMapView *)sharedInstance
{
    static MKMapView *sharedInstance = nil;
    
    @synchronized(self) {
        if (sharedInstance == nil) sharedInstance = [[MKMapView alloc] init];
    }
    return sharedInstance;
}

@end
