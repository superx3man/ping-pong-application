//
//  NSString+Hash.h
//  WheArU
//
//  Created by Calvin Ng on 9/21/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>


@interface NSString (Hash)

- (NSString *)sha1;
- (NSString *)md5;

@end
