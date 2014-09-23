//
//  EntityController.m
//  WheArU
//
//  Created by Calvin Ng on 9/15/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "EntityController.h"

#import "AppDelegate.h"

#import "UIColor+Hex.h"


@implementation EntityController

- (id)init
{
    if (self = [super init]) {
        _managedObjectContext = [(AppDelegate *) [[UIApplication sharedApplication] delegate] managedObjectContext];
    }
    return self;
}

#pragma mark - Class Functions

+ (NSArray *)availableUserColor
{
    NSArray *colorHexList = [[NSArray alloc] initWithObjects:@"FFAAAA", @"FFD8AA", @"FFECAA", @"FFFFAA", @"C4E79A", @"70A897", @"7887AB", @"8D79AE", @"B77AAB", nil];
    
    NSMutableArray *colorList = [[NSMutableArray alloc] initWithCapacity:[colorHexList count]];
    for (NSString *colorHex in colorHexList) {
        [colorList addObject:[UIColor colorFromHexString:colorHex]];
    }
    return [NSArray arrayWithArray:colorList];
}

#pragma mark - Properties

- (void)setUserColor:(UIColor *)userColor
{
    if ([_userColor isEqual:userColor]) return;
    _userColor = userColor;
    
    CGFloat red, green, blue;
    [[self userColor] getRed:&red green:&green blue:&blue alpha:nil];
    
    int lightCount = 0;
    if (red >= 0.8f) lightCount++;
    if (green >= 0.8f) lightCount++;
    if (blue >= 0.8f) lightCount++;
    
    _wordColor = lightCount >= 2 ? [UIColor lightGrayColor] : [UIColor whiteColor];
}

@end
