//
//  ContactListController.h
//  WheArU
//
//  Created by Calvin Ng on 9/1/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Contact.h"

@interface ContactListController : NSObject

@property (nonatomic, strong) NSMutableArray *recentContactList;
@property (nonatomic, strong) NSMutableArray *contactList;

@end
