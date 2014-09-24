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
#import "WAUConstant.h"
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
    [delegateList addObject:[NSValue valueWithNonretainedObject:delegate]];
}

- (ContactController *)createContactWithJSONDescription:(NSString *)encryptedJsonString
{
    NSString *jsonString = [[EncryptionController sharedInstance] decryptStringWithSystemKey:encryptedJsonString];
    NSData *contactInfoJSONData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error = nil;
    NSDictionary *contactInfo = [NSJSONSerialization JSONObjectWithData:contactInfoJSONData options:kNilOptions error:&error];
    
    ContactController *contactController = nil;
    return error == nil ? [self createContactWithContactInfo:contactInfo] : contactController;
}

- (ContactController *)createContactWithContactInfo:(NSDictionary *)contactInfo
{
    NSString *userId = [contactInfo objectForKey:kWAUDictionaryKeyUserId];
    ContactController *contactController = [userIdContactListDictionary objectForKey:userId];
    if (contactController == nil) {
        NSString *username = [contactInfo objectForKey:kWAUDictionaryKeyUsername];
        NSString *userColorString = [contactInfo objectForKey:kWAUDictionaryKeyUserColor];
        UIColor *userColor = [UIColor colorFromHexString:userColorString];
        
        if ([username length] > 0 && userColor != nil) {
            [WAULog log:[NSString stringWithFormat:@"new user userId: %@", userId] from:self];
            
            Contact *newContact = [NSEntityDescription insertNewObjectForEntityForName:kWAUCoreDataEntityContact inManagedObjectContext:managedObjectContext];
            [newContact setUserId:userId];
            
            [newContact setVersion:0];
            
            [newContact setUsername:username];
            [newContact setUserColor:userColorString];
            
            int64_t currentTimestamp = [[NSDate date] timeIntervalSince1970];
            [newContact setLastUpdated:currentTimestamp];
            
            [managedObjectContext save:nil];
            
            contactController = [[ContactController alloc] initWithContact:newContact];
            [userIdContactListDictionary setObject:contactController forKey:userId];
            [[self recentContactList] insertObject:contactController atIndex:0];
            
            for (id retainedDelegate in delegateList) {
                id<ContactListControllerDelegate> delegate = [retainedDelegate nonretainedObjectValue];
                if ([delegate respondsToSelector:@selector(newItemAddedToList:)]) [delegate newItemAddedToList:self];
            }
        }
    }
    return contactController;
}

- (ContactController *)updateContactWithUserId:(NSString *)userId withLocationInfo:(NSString *)locationInfo
{
    ContactController *contactController = nil;
    contactController = [userIdContactListDictionary objectForKey:userId];
    if (contactController != nil) {
        NSArray *locationInfoList = [locationInfo componentsSeparatedByString:@":"];
        [contactController setLatitude:[[locationInfoList objectAtIndex:0] doubleValue]];
        [contactController setLongitude:[[locationInfoList objectAtIndex:1] doubleValue]];
        [contactController setAltitude:[[locationInfoList objectAtIndex:2] doubleValue]];
        [contactController setAccuracy:[[locationInfoList objectAtIndex:3] doubleValue]];
        
        [contactController setLastUpdated:[[locationInfoList objectAtIndex:4] longLongValue]];
        
        if ([[self recentContactList] containsObject:contactController]) {
            [[self recentContactList] removeObject:contactController];
            [[self recentContactList] insertObject:contactController atIndex:0];
        }
        else if ([[self contactList] containsObject:contactController]) {
            [[self contactList] removeObject:contactController];
            [[self recentContactList] insertObject:contactController atIndex:0];
        }
        
        for (id retainedDelegate in delegateList) {
            id<ContactListControllerDelegate> delegate = [retainedDelegate nonretainedObjectValue];
            if ([delegate respondsToSelector:@selector(itemMovedToRecentContactList:)]) [delegate itemMovedToRecentContactList:self];
        }
    }
    return contactController;
}

- (ContactController *)validateContactWithUserId:(NSString *)userId withVersion:(int)version
{
    ContactController *contactController = nil;
    contactController = [userIdContactListDictionary objectForKey:userId];
    if (contactController != nil) {
        [contactController validateContactVersion:version];
    }
    return contactController;
}

@end
