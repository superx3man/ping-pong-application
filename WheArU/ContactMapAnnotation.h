//
//  ContactMapAnnotation.h
//  WheArU
//
//  Created by Calvin Ng on 9/22/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

#import "ContactController.h"


@interface ContactMapAnnotation : NSObject <MKAnnotation>

@property (nonatomic, copy) NSString *title;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic, readonly) CLLocationAccuracy accuracy;

@property (nonatomic, strong) ContactController *contactController;

- (id)initWithContactController:(ContactController *)contactController;

- (MKCircle *)accuracyOverlay;

@end
