//
//  MKMapView+SharedInstance.h
//  WheArU
//
//  Created by Calvin Ng on 9/23/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <MapKit/MapKit.h>


@interface MKMapView (SharedInstance)

+ (MKMapView *)sharedInstance;

@end
