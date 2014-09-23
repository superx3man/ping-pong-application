//
//  ContactListController.h
//  WheArU
//
//  Created by Calvin Ng on 9/1/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Contact.h"
#import "ContactController.h"


@protocol ContactListControllerDelegate;

@interface ContactListController : NSObject

@property (nonatomic, strong) NSMutableArray *recentContactList;
@property (nonatomic, strong) NSMutableArray *contactList;

+ (ContactListController *)sharedInstance;

- (void)addDelegate:(id<ContactListControllerDelegate>)delegate;

- (ContactController *)createContactWithJSONDescription:(NSString *)encryptedJsonString;
- (ContactController *)createContactWithContactInfo:(NSDictionary *)contactInfo;

- (ContactController *)updateContactWithUserId:(NSString *)userId withLocationInfo:(NSString *)locationInfo;
- (ContactController *)validateContactWithUserId:(NSString *)userId withVersion:(int)version;

@end

@protocol ContactListControllerDelegate <NSObject>

@optional
- (void)newItemAddedToList:(ContactListController *)controller;

- (void)itemMovedToRecentContactList:(ContactListController *)controller;

@end
