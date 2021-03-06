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
        [[WAUUtilities applicationDelegate] addApplicationStateChangeDelegate:self];
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
    @synchronized(delegateList) {
        [delegateList addObject:[NSValue valueWithNonretainedObject:delegate]];
    }
}

- (void)removeDelegate:(id<NotificationControllerDelegate>)delegate
{
    @synchronized(delegateList) {
        [delegateList removeObject:[NSValue valueWithNonretainedObject:delegate]];
    }
}

- (void)requestForLocationFromContact:(ContactController *)contact
{
    [self requestForLocationFromContact:contact inBackground:UIBackgroundTaskInvalid];
}

- (void)requestForLocationFromContact:(ContactController *)contact inBackground:(UIBackgroundTaskIdentifier)taskIdentifier
{
    [contact setPingStatus:WAUContactPingStatusPinging];
    
    [[LocationController sharedInstance] retrieveLocationWithUpdateBlock:^(CLLocation *location)
     {
         if ([[UserController sharedInstance] userId] == nil) return;
         
         NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
         [userDictionary setObject:[[UserController sharedInstance] userId] forKey:kWAUDictionaryKeyUserId];
         [userDictionary setObject:[contact userId] forKey:kWAUDictionaryKeyContactId];
         [userDictionary setObject:[NSNumber numberWithInt:[contact ping] > 0 ? 1 : 0] forKey:kWAUDictionaryKeyPingType];
         
         NSMutableArray *locationInfo = [[NSMutableArray alloc] init];
         [locationInfo addObject:[NSNumber numberWithDouble:[location coordinate].latitude]];
         [locationInfo addObject:[NSNumber numberWithDouble:[location coordinate].longitude]];
         [locationInfo addObject:[NSNumber numberWithDouble:[location altitude]]];
         [locationInfo addObject:[NSNumber numberWithDouble:[location horizontalAccuracy]]];
         [locationInfo addObject:[NSNumber numberWithLongLong:[[location timestamp] timeIntervalSince1970]]];
         NSString *locationString = [locationInfo componentsJoinedByString:@":"];
         [userDictionary setObject:locationString forKey:kWAUDictionaryKeyLocationInfo];
         
         WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUServerEndpointPing method:@"POST" parameters:userDictionary];
         [request setBackgroundTaskIdentifier:taskIdentifier];
         [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest) {
             [WAULog log:[NSString stringWithFormat:@"failed to ping contact: %@", [contact userId]] from:self];
             [contact setPingStatus:WAUContactPingStatusFailed];
         }];
         [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult) {
             [WAULog log:[NSString stringWithFormat:@"ping contact: %@", [contact userId]] from:self];
             [contact setPing:0];
             [contact setPingStatus:WAUContactPingStatusSuccess];
         }];
         [[WAUServerConnector sharedInstance] sendRequest:request withTag:[NSString stringWithFormat:@"PingContact-%@", [contact userId]]];
     }];
}

- (void)syncLocationRequestFromServer
{
    [self syncLocationRequestFromServerInBackground:UIBackgroundTaskInvalid];
}

- (void)syncLocationRequestFromServerInBackground:(UIBackgroundTaskIdentifier)taskIdentifier
{
    static BOOL isSyncing = NO;
    if ([[UserController sharedInstance] userId] == nil || isSyncing) return;
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(syncLocationRequestFromServer) object:nil];
    isSyncing = YES;
    
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:[[UserController sharedInstance] userId] forKey:kWAUDictionaryKeyUserId];
    
    WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUServerEndpointPingSync method:@"POST" parameters:userDictionary];
    [request setBackgroundTaskIdentifier:taskIdentifier];
    [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest) {
        [WAULog log:@"failed to sync ping requests" from:self];
        
        [self performSelector:@selector(syncLocationRequestFromServer) withObject:nil afterDelay:300];
        
        isSyncing = NO;
    }];
    [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult) {
        [WAULog log:@"synced ping requests" from:self];
        
        for (NSDictionary *pingInfo in (NSArray *) requestResult) {
            [[ContactListController sharedInstance] updateOrCreateContactWithUserInfo:pingInfo];
        }
        [[ContactListController sharedInstance] refreshContactList];
        
        if (![WAUUtilities isApplicationRunningInBackground] && [WAUUtilities isUserNotificationBadgeEnabled]) [[UIApplication sharedApplication] setApplicationIconBadgeNumber:0];
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

#pragma mark ApplicationStateChangeDelegate

- (void)didBecomeActive
{
    [self performSelectorInBackground:@selector(syncLocationRequestFromServer) withObject:nil];
}

@end
