//
//  FacebookUser.m
//  WheArU
//
//  Created by Calvin Ng on 9/30/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "FacebookUser.h"


@implementation FacebookUser

- (id)initWithId:(NSString *)userId name:(NSString *)name pictureLink:(NSString *)pictureLink
{
    if (self = [super init]) {
        _userId = userId;
        _name = name;
        _pictureLink = pictureLink;
    }
    return self;
}

- (void)purgePicture
{
    _picture = nil;
}

@end
