//
//  MKCircle+ContactController.m
//  WheArU
//
//  Created by Calvin Ng on 9/22/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "MKCircle+ContactController.h"


static void *ContactControllerPropertyKey = &ContactControllerPropertyKey;

@implementation MKCircle (ContactController)

- (ContactController *)contactController
{
    return objc_getAssociatedObject(self, ContactControllerPropertyKey);
}

- (void)setContactController:(ContactController *)contactController
{
    objc_setAssociatedObject(self, ContactControllerPropertyKey, contactController, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
