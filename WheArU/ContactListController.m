//
//  ContactListController.m
//  WheArU
//
//  Created by Calvin Ng on 9/1/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "ContactListController.h"

#import "AppDelegate.h"

@implementation ContactListController
{
    NSManagedObjectContext *managedObjectContext;
}

- (id)init
{
    if (self = [super init]) {
        managedObjectContext = [(AppDelegate *) [[UIApplication sharedApplication] delegate] managedObjectContext];
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:kWAUCoreDataEntityContact inManagedObjectContext:managedObjectContext];
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entity];
        [request setReturnsObjectsAsFaults:NO];
        
        NSArray *requestResult = [managedObjectContext executeFetchRequest:request error:nil];
        
        NSMutableArray *recentContactList = [[NSMutableArray alloc] init];
        NSMutableArray *contactList = [[NSMutableArray alloc] init];
        
        if (requestResult != nil) {
            for (Contact *contact in requestResult) {
                int currentTimestamp = [[NSDate date] timeIntervalSince1970];
                if (currentTimestamp - [contact lastUpdated] <= 432000) {
                    [recentContactList addObject:contact];
                }
                else {
                    [contactList addObject:contact];
                }
            }
        }
        
        NSSortDescriptor *usernameDescriptor = [[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES];
        NSSortDescriptor *lastUpdatedDescriptor = [[NSSortDescriptor alloc] initWithKey:@"lastUpdated" ascending:NO];
        
        [self setRecentContactList:[[recentContactList sortedArrayUsingDescriptors:[NSArray arrayWithObjects:lastUpdatedDescriptor, usernameDescriptor, nil]] mutableCopy]];
        [self setContactList:[[contactList sortedArrayUsingDescriptors:[NSArray arrayWithObjects:usernameDescriptor, lastUpdatedDescriptor, nil]] mutableCopy]];
    }
    return self;
}

#pragma mark - Public Functions

@end
