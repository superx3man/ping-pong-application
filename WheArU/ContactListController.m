//
//  ContactListController.m
//  WheArU
//
//  Created by Calvin Ng on 9/1/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "ContactListController.h"

#import "AppDelegate.h"
#import "UserController.h"
#import "EncryptionController.h"

#import "UIColor+Hex.h"
#import "WAULog.h"

@implementation ContactListController
{
    NSManagedObjectContext *managedObjectContext;
    
    NSMutableArray *delegateList;
    NSMutableDictionary *userIdContactListDictionary;
}

- (id)init
{
    if (self = [super init]) {
        managedObjectContext = [(AppDelegate *) [[UIApplication sharedApplication] delegate] managedObjectContext];
        delegateList = [[NSMutableArray alloc] init];
        userIdContactListDictionary = [[NSMutableDictionary alloc] init];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:kWAUCoreDataEntityContact inManagedObjectContext:managedObjectContext];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entity];
        [request setReturnsObjectsAsFaults:NO];
        
        NSArray *requestResult = [managedObjectContext executeFetchRequest:request error:nil];
        
        NSMutableArray *recentContactList = [[NSMutableArray alloc] init];
        NSMutableArray *contactList = [[NSMutableArray alloc] init];
        
        if (requestResult != nil) {
            for (Contact *contact in requestResult) {
                ContactController *contactController = [[ContactController alloc] initWithContact:contact];
                
                if ([userIdContactListDictionary objectForKey:[contactController userId]] != nil) continue;
                [userIdContactListDictionary setObject:contactController forKey:[contactController userId]];
                
                int64_t currentTimestamp = [[NSDate date] timeIntervalSince1970];
                if (currentTimestamp - [contact lastUpdated] <= 432000) [recentContactList addObject:contactController];
                else [contactList addObject:contactController];
            }
        }
        
        NSSortDescriptor *usernameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES];
        NSSortDescriptor *lastUpdatedDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUpdated" ascending:NO];
        
        [self setRecentContactList:[[recentContactList sortedArrayUsingDescriptors:[NSArray arrayWithObjects:lastUpdatedDescriptor, usernameDescriptor, nil]] mutableCopy]];
        [self setContactList:[[contactList sortedArrayUsingDescriptors:[NSArray arrayWithObjects:usernameDescriptor, lastUpdatedDescriptor, nil]] mutableCopy]];
    }
    return self;
}

#pragma mark - Singleton Class

+ (ContactListController *)sharedInstance
{
    static ContactListController *sharedInstance = nil;
    
    @synchronized(self) {
        if (sharedInstance == nil) sharedInstance = [[ContactListController alloc] init];
    }
    return sharedInstance;
}

#pragma mark - Functions
#pragma mark External

- (void)addDelegate:(id<ContactListControllerDelegate>)delegate
{
    [delegateList addObject:delegate];
}

- (ContactController *)createContactWithJSONDescription:(NSString *)encryptedJsonString
{
    NSString *jsonString = [[EncryptionController sharedInstance] decryptStringWithSystemKey:encryptedJsonString];
    NSData *contactInfoJSONData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *contactInfo = [NSJSONSerialization JSONObjectWithData:contactInfoJSONData options:kNilOptions error:&error];
    
    ContactController *contactController = nil;
    if (error == nil) {
        NSString *userId = [contactInfo objectForKey:kWAUUserDictionaryKeyUserId];
        contactController = [userIdContactListDictionary objectForKey:userId];
        if (contactController == nil) {
            NSString *base64NotificationKey = nil;
            if ((base64NotificationKey = [contactInfo objectForKey:kWAUUserDictionaryKeyNotificationKey])) {
                NSData *notificationKey = [[NSData alloc] initWithBase64EncodedString:base64NotificationKey options:kNilOptions];
                
                NSString *username = [contactInfo objectForKey:kWAUUserDictionaryKeyUsername];
                NSString *userColorString = [contactInfo objectForKey:kWAUUserDictionaryKeyUserColor];
                UIColor *userColor = [UIColor colorFromHexString:userColorString];
                
                int platform = [[contactInfo objectForKey:kWAUUserDictionaryKeyPlatform] intValue];
                int version = [[contactInfo objectForKey:kWAUUserDictionaryKeyVersion] intValue];
                
                if (notificationKey != nil && [username length] > 0 && userColor != nil) {
                    [WAULog log:[NSString stringWithFormat:@"new user userId: %@", userId] from:self];
                    NSString *userIconLink = [contactInfo objectForKey:kWAUUserDictionaryKeyUserIcon];
                    
                    Contact *newContact = [NSEntityDescription insertNewObjectForEntityForName:kWAUCoreDataEntityContact inManagedObjectContext:managedObjectContext];
                    [newContact setUserId:userId];
                    
                    [newContact setNotificationKey:notificationKey];
                    [newContact setPlatform:platform];
                    [newContact setVersion:version];
                    
                    [newContact setUsername:username];
                    [newContact setUserColor:userColorString];
                    if (userIconLink != nil) [newContact setUserIconLink:userIconLink];
                    
                    int64_t currentTimestamp = [[NSDate date] timeIntervalSince1970];
                    [newContact setLastUpdated:currentTimestamp];
                    [newContact setLocationState:WAUContactLocationStateNotSet];
                    
                    [managedObjectContext save:nil];
                    
                    contactController = [[ContactController alloc] initWithContact:newContact];
                    [userIdContactListDictionary setObject:contactController forKey:userId];
                    [[self recentContactList] insertObject:contactController atIndex:0];
                    
                    for (id<ContactListControllerDelegate>delegate in delegateList) {
                        if ([delegate respondsToSelector:@selector(newItemAddedToList:)]) [delegate newItemAddedToList:self];
                    }
                }
            }
        }
    }
    return contactController;
}

@end
