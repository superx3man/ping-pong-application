//
//  MKCircle+ContactController.h
//  WheArU
//
//  Created by Calvin Ng on 9/22/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <MapKit/MapKit.h>
#import <objc/runtime.h>

#import "ContactController.h"


@interface MKCircle (ContactController)

@property (nonatomic, retain) ContactController *contactController;

@end
