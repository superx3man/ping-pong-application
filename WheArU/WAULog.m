//
//  WAULog.m
//  WheArU
//
//  Created by Calvin Ng on 9/13/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "WAULog.h"


@implementation WAULog

+ (void)log:(NSString *)message from:(id)sender
{
    NSLog(@"[%@] %@", NSStringFromClass([sender class]), message);
}

@end
