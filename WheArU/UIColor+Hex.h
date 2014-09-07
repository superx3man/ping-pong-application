//
//  UIColor+Hex.h
//  WheArU
//
//  Created by Calvin Ng on 9/1/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor (Hex)

+ (UIColor *)colorFromHexString:(NSString *)hexString;
+ (NSString *)hexStringFromColor:(UIColor *)color;

@end
