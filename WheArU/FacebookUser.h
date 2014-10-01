//
//  FacebookUser.h
//  WheArU
//
//  Created by Calvin Ng on 9/30/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface FacebookUser : NSObject

@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSString *pictureLink;
@property (nonatomic, strong) UIImage *picture;

- (id)initWithId:(NSString *)userId name:(NSString *)name pictureLink:(NSString *)pictureLink;

@end
