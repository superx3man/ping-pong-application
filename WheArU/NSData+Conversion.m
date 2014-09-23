//
//  NSData+Conversion.m
//  WheArU
//
//  Created by Calvin Ng on 9/18/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "NSData+Conversion.h"

@implementation NSData (Conversion)

- (NSString *)hexadecimalString
{
    const unsigned char *dataBuffer = (const unsigned char *) [self bytes];
    
    if (!dataBuffer) return [NSString string];
    
    NSUInteger dataLength = [self length];
    NSMutableString *hexString = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i) {
        [hexString appendString:[NSString stringWithFormat:@"%02lx", (unsigned long) dataBuffer[i]]];
    }
    return [NSString stringWithString:hexString];
}

@end
