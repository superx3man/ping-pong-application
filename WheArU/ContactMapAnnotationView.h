//
//  ContactMapAnnotationView.h
//  WheArU
//
//  Created by Calvin Ng on 9/22/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <MapKit/MapKit.h>

#import "ContactMapAnnotation.h"


@interface ContactMapAnnotationView : MKAnnotationView

@property (nonatomic, strong) ContactMapAnnotation *contactMapAnnotation;

- (id)initWithAnnotation:(ContactMapAnnotation *)contactMapAnnotation;

@end
