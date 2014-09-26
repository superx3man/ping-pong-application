//
//  ContactMapViewController.h
//  WheArU
//
//  Created by Calvin Ng on 9/21/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "ContactController.h"


@interface ContactMapViewController : UIViewController <ContactControllerDelegate, MKMapViewDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, strong) ContactController *contactController;

@end
