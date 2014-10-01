//
//  NotificationController.m
//  WheArU
//
//  Created by Calvin Ng on 9/16/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "NotificationController.h"

#import "UserController.h"
#import "ContactListController.h"
#import "LocationController.h"

#import "NSData+Conversion.h"
#import "Reachability.h"
#import "WAUConstant.h"
#import "WAULog.h"
#import "WAUServerConnector.h"
#import "WAUServerConnectorRequest.h"
#import "WAUUtilities.h"


NSString *const kWAUNotificationCategoryIdentifierRequestLocation = @"kWAUNotificationCategoryIdentifierRequestLocation";
NSString *const kWAUNotificationActionIdentifierSend = @"kWAUNotificationActionIdentifierSend";

@implementation NotificationController
{
    NSMutableArray *delegateList;
}

- (id)init
{
    if (self = [super init]) {
        delegateList = [[NSMutableArray alloc] init];
        
        [[WAUUtilities applicationDelegate] setNotificationRegistrationDelegate:self];
    }
    return self;
}

#pragma mark - Singleton Class

+ (NotificationController *)sharedInstance
{
    static NotificationController *sharedInstance = nil;
    
    @synchronized(self) {
        if (sharedInstance == nil) sharedInstance = [[NotificationController alloc] init];
    }
    return sharedInstance;
}

#pragma mark - Functions
#pragma mark Support

- (void)registerRemoteNotification
{
    UIMutableUserNotificationAction *sendAction = [[UIMutableUserNotificationAction alloc] init];
    [sendAction setTitle:@"Send"];
    [sendAction setIdentifier:kWAUNotificationActionIdentifierSend];
    [sendAction setActivationMode:UIUserNotificationActivationModeBackground];
    [sendAction setAuthenticationRequired:NO];
    
    UIMutableUserNotificationCategory *locationRequestCategory = [[UIMutableUserNotificationCategory alloc] init];
    [locationRequestCategory setIdentifier:kWAUNotificationCategoryIdentifierRequestLocation];
    [locationRequestCategory setActions:[NSArray arrayWithObjects:sendAction, nil] forContext:UIUserNotificationActionContextDefault];
    
    NSSet *categorySet = [NSSet setWithObjects:locationRequestCategory, nil];
    UIUserNotificationSettings* notificationSettings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:categorySet];
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    [[UIApplication sharedApplication] registerForRemoteNotifications];
}

#pragma mark External

- (void)addDelegate:(id<NotificationControllerDelegate>)delegate
{
    [delegateList addObject:[NSValue valueWithNonretainedObject:delegate]];
}

- (void)removeDelegate:(id<NotificationControllerDelegate>)delegate
{
    [delegateList removeObject:[NSValue valueWithNonretainedObject:delegate]];
}

- (void)requestForLocationFromContact:(ContactController *)contact
{
    [contact setPingStatus:WAUContactPingStatusPinging];
    
    dispatch_semaphore_t semaphore = NULL;
    if ([WAUUtilities isApplicationRunningInBackground]) semaphore = dispatch_semaphore_create(0);
    
    [[LocationController sharedInstance] retrieveLocationWithUpdateBlock:^(CLLocation *location)
    {
        if ([[UserController sharedInstance] userId] == nil) return;
        
        NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
        [userDictionary setObject:[[UserController sharedInstance] userId] forKey:kWAUDictionaryKeyUserId];
        [userDictionary setObject:[contact userId] forKey:kWAUDictionaryKeyContactId];
        [userDictionary setObject:[NSNumber numberWithInt:0] forKey:kWAUDictionaryKeyPingType];
        
        NSMutableArray *locationInfo = [[NSMutableArray alloc] init];
        [locationInfo addObject:[NSNumber numberWithDouble:[location coordinate].latitude]];
        [locationInfo addObject:[NSNumber numberWithDouble:[location coordinate].longitude]];
        [locationInfo addObject:[NSNumber numberWithDouble:[location altitude]]];
        [locationInfo addObject:[NSNumber numberWithDouble:[location horizontalAccuracy]]];
        [locationInfo addObject:[NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970]]];
        NSString *locationString = [locationInfo componentsJoinedByString:@":"];
        [userDictionary setObject:locationString forKey:kWAUDictionaryKeyLocationInfo];
        
#ifdef DEBUG
        [userDictionary setObject:[NSNumber numberWithInt:1] forKey:kWAUDictionaryKeyDevelopment];
#endif
        
        WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUServerEndpointPing method:@"POST" parameters:userDictionary];
        [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest)
         {
             [WAULog log:[NSString stringWithFormat:@"failed to ping contact: %@", [contact userId]] from:self];
             [contact setPingStatus:WAUContactPingStatusFailed];
             [contact didSendNotification:NO];
             
             if (semaphore != NULL) dispatch_semaphore_signal(semaphore);
         }];
        [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult)
         {
             [WAULog log:[NSString stringWithFormat:@"ping contact: %@", [contact userId]] from:self];
             [contact setPing:0];
             [contact setPingStatus:WAUContactPingStatusSuccess];
             [contact didSendNotification:YES];
             
             if (semaphore != NULL) dispatch_semaphore_signal(semaphore);
         }];
        [[WAUServerConnector sharedInstance] sendRequest:request withTag:[NSString stringWithFormat:@"PingContact-%@", [contact userId]]];
    } synchrounous:[WAUUtilities isApplicationRunningInBackground]];
    
    [contact willSendNotification];
    
    if (semaphore != NULL) dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
}

- (void)syncLocationRequestFromServer
{
    static BOOL isSyncing = NO;
    if ([[UserController sharedInstance] userId] == nil || isSyncing) return;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncLocationRequestFromServer) object:nil];
    isSyncing = YES;
    
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:[[UserController sharedInstance] userId] forKey:kWAUDictionaryKeyUserId];
    
    WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUServerEndpointPingSync method:@"POST" parameters:userDictionary];
    [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest)
     {
         [WAULog log:@"failed to sync ping requests" from:self];
         
         [self performSelector:@selector(syncLocationRequestFromServer) withObject:nil afterDelay:300];
         
         isSyncing = NO;
     }];
    [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult)
     {
         [WAULog log:@"synced ping requests" from:self];
         
         for (NSDictionary *pingInfo in (NSArray *) requestResult) {
             [[ContactListController sharedInstance] updateOrCreateContactWithUserInfo:pingInfo];
         }
         [[ContactListController sharedInstance] refreshContactList];
         
         if ([WAUUtilities isUserNotificationBadgeEnabled]) [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
         isSyncing = NO;
     }];
     [[WAUServerConnector sharedInstance] sendRequest:request withTag:@"SyncRequest"];
}

#pragma mark - Delegates
#pragma mark EncryptionControllerDelegate

- (void)controllerDidSetGeneratedKey:(EncryptionController *)controller
{
    [self registerRemoteNotification];
}

#pragma mark NotificationRegistrationDelegate

- (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
}

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    [WAULog log:@"device registered for remote notification" from:self];
    [[UserController sharedInstance] setNotificationKey:[deviceToken hexadecimalString]];
}

- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    [WAULog log:[NSString stringWithFormat:@"device failed to register remote notification error: %@", [error localizedDescription]] from:self];
}

@end
