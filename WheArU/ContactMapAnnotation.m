//
//  ContactMapAnnotation.m
//  WheArU
//
//  Created by Calvin Ng on 9/22/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "ContactMapAnnotation.h"

#import "MKCircle+ContactController.h"


@implementation ContactMapAnnotation

- (id)initWithContactController:(ContactController *)contactController
{
    if (self = [super init]) {
        _contactController = contactController;
        
        _title = [contactController username];
        _coordinate = CLLocationCoordinate2DMake([contactController latitude], [contactController longitude]);
        _accuracy = [contactController accuracy];
    }
    return self;
}

- (MKCircle *)accuracyOverlay
{
    MKCircle *overlay = [MKCircle circleWithCenterCoordinate:[self coordinate] radius:[self accuracy]];
    [overlay setContactController:[self contactController]];
    return overlay;
}

@end
