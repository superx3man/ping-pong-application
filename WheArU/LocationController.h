//
//  LocationController.h
//  WheArU
//
//  Created by Calvin Ng on 9/18/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>


@interface LocationController : NSObject <CLLocationManagerDelegate>

+ (LocationController *)sharedInstance;

- (void)retrieveLocationWithUpdateBlock:(void (^)(CLLocation *))updateHandler;

@end
