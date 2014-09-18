//
//  Reachability+SharedInstance.h
//  WheArU
//
//  Created by Calvin Ng on 9/17/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "Reachability.h"


@interface Reachability (SharedInstance)

+ (Reachability *)sharedInstance;

@end
