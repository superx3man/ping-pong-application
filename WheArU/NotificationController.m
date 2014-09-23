//
//  NotificationController.m
//  WheArU
//
//  Created by Calvin Ng on 9/16/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "NotificationController.h"

#import "UserController.h"
#import "LocationController.h"

#import "NSData+Conversion.h"
#import "Reachability.h"
#import "WAUConstant.h"
#import "WAULog.h"
#import "WAUServerConnector.h"
#import "WAUServerConnectorRequest.h"


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
        
        [((AppDelegate *) [[UIApplication sharedApplication] delegate]) setNotificationRegistrationDelegate:self];
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
    [delegateList addObject:delegate];
}

- (void)requestForLocationFromContact:(ContactController *)contact
{
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
        
        WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUServerEndpointPing method:@"POST" parameters:userDictionary];
        [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest)
         {
             [WAULog log:[NSString stringWithFormat:@"failed to ping contact: %@", [contact userId]] from:self];
         }];
        [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult)
         {
             [WAULog log:[NSString stringWithFormat:@"ping contact: %@", [contact userId]] from:self];
         }];
        [[WAUServerConnector sharedInstance] sendRequest:request withTag:@"SyncUser"];
    }];
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
