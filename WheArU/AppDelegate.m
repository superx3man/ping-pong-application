//
//  AppDelegate.m
//  WheArU
//
//  Created by Calvin Ng on 8/31/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "AppDelegate.h"

#import "ContactListController.h"
#import "UserController.h"
#import "EncryptionController.h"
#import "NotificationController.h"
#import "LocationController.h"

#import "NSData+Conversion.h"
#import "WAUConstant.h"
#import "WAULog.h"


@interface AppDelegate ()

@end

@implementation AppDelegate
{
    BOOL isAppLaunching;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [LocationController sharedInstance];
    
    [ContactListController sharedInstance];
    [UserController sharedInstance];
    
    [EncryptionController sharedInstance];
    [NotificationController sharedInstance];
    
    [[EncryptionController sharedInstance] addDelegate:[NotificationController sharedInstance]];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    if ([self applicationStateChangeDelegate] != nil) {
        if ([[self applicationStateChangeDelegate] respondsToSelector:@selector(willEnterForeground)]) [[self applicationStateChangeDelegate] willEnterForeground];
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[NotificationController sharedInstance] syncLocationRequestFromServer];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self saveContext];
}

#pragma mark - Protocol Delegates
#pragma mark Notifcations

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings
{
    if ([self notificationRegistrationDelegate] != nil) {
        if ([[self notificationRegistrationDelegate] respondsToSelector:@selector(didRegisterUserNotificationSettings:)]) [[self notificationRegistrationDelegate] didRegisterUserNotificationSettings:notificationSettings];
    }
}

#pragma mark Push Notifcations

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    if ([self notificationRegistrationDelegate] != nil) {
        if ([[self notificationRegistrationDelegate] respondsToSelector:@selector(didRegisterForRemoteNotificationsWithDeviceToken:)]) [[self notificationRegistrationDelegate] didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
    }
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    if ([self notificationRegistrationDelegate] != nil) {
        if ([[self notificationRegistrationDelegate] respondsToSelector:@selector(didFailToRegisterForRemoteNotificationsWithError:)]) [[self notificationRegistrationDelegate] didFailToRegisterForRemoteNotificationsWithError:error];
    }
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler
{
    if ([identifier isEqualToString:kWAUNotificationActionIdentifierSend]) {
        NSString *userId = [userInfo objectForKey:kWAUDictionaryKeyUserId];
        NSString *locationInfo = [userInfo objectForKey:kWAUDictionaryKeyLocationInfo];
        if (locationInfo != nil) [[ContactListController sharedInstance] updateContactWithUserId:userId locationInfo:locationInfo];
        
        NSString *version = [userInfo objectForKey:kWAUDictionaryKeyVersion];
        if (version != nil) [[ContactListController sharedInstance] validateContactWithUserId:userId withVersion:[version intValue]];
        
        ContactController *contactController = [[ContactListController sharedInstance] getContactControllerWithUserId:userId];
        [[NotificationController sharedInstance] requestForLocationFromContact:contactController];
        
        [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber] - 1];
    }
    completionHandler();
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSString *messageType = [userInfo objectForKey:kWAUDictionaryKeyContentType];
    UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultNoData;
    
    [WAULog log:[NSString stringWithFormat:@"Received notification type: %@", messageType] from:self];
    
    if ([messageType isEqualToString:@"contact"]) {
        [[ContactListController sharedInstance] createContactWithContactInfo:userInfo];
        fetchResult = UIBackgroundFetchResultNewData;
    }
    else if ([messageType isEqualToString:@"ping"]) {
        if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateInactive) {
            NSString *userId = [userInfo objectForKey:kWAUDictionaryKeyUserId];
            NSString *locationInfo = [userInfo objectForKey:kWAUDictionaryKeyLocationInfo];
            if (locationInfo != nil) [[ContactListController sharedInstance] updateContactWithUserId:userId locationInfo:locationInfo];
            
            NSString *version = [userInfo objectForKey:kWAUDictionaryKeyVersion];
            if (version != nil) [[ContactListController sharedInstance] validateContactWithUserId:userId withVersion:[version intValue]];
        }
        fetchResult = UIBackgroundFetchResultNewData;
    }
    completionHandler(fetchResult);
}

#pragma mark - Core Data

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"WheArU" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"WheArU.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    
    NSDictionary *options = [[NSDictionary alloc] initWithObjectsAndKeys:@YES, NSMigratePersistentStoresAutomaticallyOption, @YES, NSInferMappingModelAutomaticallyOption, nil];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark Save

- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
