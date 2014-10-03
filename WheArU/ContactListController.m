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
#import "WAUServerConnector.h"
#import "WAUServerConnectorRequest.h"
#import "WAUUtilities.h"

@implementation ContactListController
{
    NSManagedObjectContext *managedObjectContext;
    
    NSMutableArray *delegateList;
    NSMutableDictionary *userIdContactListDictionary;
}

- (id)init
{
    if (self = [super init]) {
        managedObjectContext = [[WAUUtilities applicationDelegate] managedObjectContext];
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
        
        [self setRecentContactList:[recentContactList mutableCopy]];
        [self setContactList:[contactList mutableCopy]];
        [self sortContactList];
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

#pragma mark Support

- (void)sortContactList
{
    NSSortDescriptor *usernameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSSortDescriptor *lastUpdatedDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUpdated" ascending:NO];
    
    [self setRecentContactList:[[[self recentContactList] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:lastUpdatedDescriptor, usernameDescriptor, nil]] mutableCopy]];
    [self setContactList:[[[self contactList] sortedArrayUsingDescriptors:[NSArray arrayWithObjects:usernameDescriptor, lastUpdatedDescriptor, nil]] mutableCopy]];
}

- (void)sendRelation:(int)relationType withContactController:(ContactController *)contactController failureHandler:(void (^)())failureHandler successHandler:(void (^)(NSObject *))successHandler
{
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:[[UserController sharedInstance] userId] forKey:kWAUDictionaryKeyUserId];
    [userDictionary setObject:[contactController userId] forKey:kWAUDictionaryKeyContactId];
    [userDictionary setObject:[NSNumber numberWithInt:relationType] forKey:kWAUDictionaryKeyRelationType];
    
    WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUServerEndpointUserRelation method:@"POST" parameters:userDictionary];
    [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest)
     {
         [WAULog log:[NSString stringWithFormat:@"failed to set relation: %d with user: %@", relationType, [contactController userId]] from:self];
         if (failureHandler != nil) failureHandler();
     }];
    [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult)
     {
         [WAULog log:[NSString stringWithFormat:@"relation: %d set with user: %@", relationType, [contactController userId]] from:self];
         if (successHandler != nil) successHandler(requestResult);
     }];
    [[WAUServerConnector sharedInstance] sendRequest:request withTag:[NSString stringWithFormat:@"RelateUser-%d-%@", relationType, [contactController userId]]];
}

#pragma mark External

- (void)addDelegate:(id<ContactListControllerDelegate>)delegate
{
    [delegateList addObject:[NSValue valueWithNonretainedObject:delegate]];
}

- (void)refreshContactList
{
    [self sortContactList];
    
    for (id retainedDelegate in delegateList) {
        id<ContactListControllerDelegate> delegate = [retainedDelegate nonretainedObjectValue];
        if ([delegate respondsToSelector:@selector(listUpdated:)]) [delegate listUpdated:self];
    }
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

- (ContactController *)createContactWithPlaceholderContactInfo:(NSDictionary *)contactInfo
{
    NSMutableDictionary *placeholderInfo = [contactInfo mutableCopy];
    [placeholderInfo setObject:@"New Friend" forKey:kWAUDictionaryKeyUsername];
    
    NSArray *availableColor = [EntityController availableUserColor];
    NSString *colorString = [UIColor hexStringFromColor:[availableColor objectAtIndex:(arc4random() % [availableColor count])]];
    [placeholderInfo setObject:colorString forKey:kWAUDictionaryKeyUserColor];
    
    return [self createContactWithContactInfo:placeholderInfo];
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
        }
    }
    return contactController;
}

- (ContactController *)updateContactWithUserId:(NSString *)userId locationInfo:(NSString *)locationInfo
{
    return [self updateContactWithUserId:userId locationInfo:locationInfo pingCount:0];
}

- (ContactController *)updateContactWithUserId:(NSString *)userId locationInfo:(NSString *)locationInfo pingCount:(int)pingCount
{
    ContactController *contactController = nil;
    contactController = [userIdContactListDictionary objectForKey:userId];
    if (contactController != nil) {
        NSArray *locationInfoList = [locationInfo componentsSeparatedByString:@":"];
        [contactController setLatitude:[[locationInfoList objectAtIndex:0] doubleValue]];
        [contactController setLongitude:[[locationInfoList objectAtIndex:1] doubleValue]];
        [contactController setAltitude:[[locationInfoList objectAtIndex:2] doubleValue]];
        [contactController setAccuracy:[[locationInfoList objectAtIndex:3] doubleValue]];
        
        int64_t lastUpdated = [[locationInfoList objectAtIndex:4] longLongValue];
        if (pingCount > 0) {
            [contactController setLastUpdated:lastUpdated withPingCount:pingCount];
            [[UserController sharedInstance] incrementFetchCount:pingCount];
        }
        else [contactController setLastUpdated:lastUpdated];
        
        int64_t currentTimestamp = [[NSDate date] timeIntervalSince1970];
        if ([[self recentContactList] containsObject:contactController] && currentTimestamp - lastUpdated > 432000) {
            [[self recentContactList] removeObject:contactController];
            [[self contactList] insertObject:contactController atIndex:0];
        }
        else if ([[self contactList] containsObject:contactController] && currentTimestamp - lastUpdated <= 432000) {
            [[self contactList] removeObject:contactController];
            [[self recentContactList] insertObject:contactController atIndex:0];
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

- (ContactController *)updateOrCreateContactWithUserInfo:(NSDictionary *)userInfo
{
    NSString *userId = [userInfo objectForKey:kWAUDictionaryKeyUserId];
    ContactController *contactController = [self getContactControllerWithUserId:userId];
    if (contactController == nil) {
        contactController = [self createContactWithPlaceholderContactInfo:userInfo];
    }
    else {
        NSString *version = [userInfo objectForKey:kWAUDictionaryKeyVersion];
        if (version != nil) [[ContactListController sharedInstance] validateContactWithUserId:userId withVersion:[version intValue]];
    }
    
    NSString *locationInfo = [userInfo objectForKey:kWAUDictionaryKeyLocationInfo];
    if (locationInfo != nil) {
        int pingCount = [userInfo objectForKey:kWAUDictionaryKeyPingCount] == nil ? 0 : [[userInfo objectForKey:kWAUDictionaryKeyPingCount] intValue];
        [[ContactListController sharedInstance] updateContactWithUserId:userId locationInfo:locationInfo pingCount:pingCount];
    }

    return contactController;
}

- (ContactController *)getContactControllerWithUserId:(NSString *)userId
{
    return [userIdContactListDictionary objectForKey:userId];
}

- (void)blockContactController:(ContactController *)contactController
{
    [self sendRelation:WAUUserRelationBlock withContactController:contactController failureHandler:nil successHandler:^(NSObject *requestResult)
     {
         [contactController removeFromList];
     }];
    
    [userIdContactListDictionary removeObjectForKey:[contactController userId]];
    if ([[self recentContactList] containsObject:contactController]) [[self recentContactList] removeObject:contactController];
    if ([[self contactList] containsObject:contactController]) [[self contactList] removeObject:contactController];
}

@end
