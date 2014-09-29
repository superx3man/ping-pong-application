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


typedef NS_ENUM(int, WAUUserRelation)
{
    WAUUserRelationBlock = 1
};

@protocol ContactListControllerDelegate;

@interface ContactListController : NSObject

@property (nonatomic, strong) NSMutableArray *recentContactList;
@property (nonatomic, strong) NSMutableArray *contactList;

+ (ContactListController *)sharedInstance;

- (void)addDelegate:(id<ContactListControllerDelegate>)delegate;

- (void)refreshContactList;

- (ContactController *)createContactWithJSONDescription:(NSString *)encryptedJsonString;
- (ContactController *)createContactWithPlaceholderContactInfo:(NSDictionary *)contactInfo;
- (ContactController *)createContactWithContactInfo:(NSDictionary *)contactInfo;

- (ContactController *)updateContactWithUserId:(NSString *)userId locationInfo:(NSString *)locationInfo;
- (ContactController *)updateContactWithUserId:(NSString *)userId locationInfo:(NSString *)locationInfo pingCount:(int)pingCount;
- (ContactController *)validateContactWithUserId:(NSString *)userId withVersion:(int)version;

- (ContactController *)updateOrCreateContactWithUserInfo:(NSDictionary *)userInfo;

- (ContactController *)getContactControllerWithUserId:(NSString *)userId;

- (void)blockContactController:(ContactController *)contactController;

@end

@protocol ContactListControllerDelegate <NSObject>

@optional
- (void)listUpdated:(ContactListController *)controller;

@end
