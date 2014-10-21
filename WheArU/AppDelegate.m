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
#import "WAUUtilities.h"


@interface AppDelegate ()

@end

@implementation AppDelegate
{
    NSMutableArray *applicationStateChangeDelegateList;
    NSMutableDictionary *externalURLSchemeDelegateList;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Crashlytics startWithAPIKey:@"47c585f537b52af7f1f6f56f7fec15a0d3086467"];
    
    [FBFriendPickerViewController class];
    
    applicationStateChangeDelegateList = [[NSMutableArray alloc] init];
    externalURLSchemeDelegateList = [[NSMutableDictionary alloc] init];
    
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
    [WAUUtilities performSelector:@selector(willEnterForeground) onDelegateList:applicationStateChangeDelegateList withObject:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [WAUUtilities performSelector:@selector(didBecomeActive) onDelegateList:applicationStateChangeDelegateList withObject:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self saveContext];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    for (NSString *urlScheme in externalURLSchemeDelegateList) {
        if ([[url scheme] isEqualToString:urlScheme]) {
            id<ExternalURLSchemeDelegate> delegate = [[externalURLSchemeDelegateList objectForKey:urlScheme] nonretainedObjectValue];
            return [delegate handleOpenURL:url sourceApplication:sourceApplication];
        }
    }
    return false;
}

#pragma mark - Functions
#pragma mark External

- (void)addApplicationStateChangeDelegate:(id<ApplicationStateChangeDelegate>)delegate
{
    @synchronized(applicationStateChangeDelegateList) {
        [applicationStateChangeDelegateList addObject:[NSValue valueWithNonretainedObject:delegate]];
    }
}

- (void)addExternalURLSchemeDelegate:(id<ExternalURLSchemeDelegate>)delegate forURLScheme:(NSString *)urlScheme
{
    [externalURLSchemeDelegateList setObject:[NSValue valueWithNonretainedObject:delegate] forKey:urlScheme];
}

- (void)removeExternalURLSchemeDelegateforApplicationKeyWord:(NSString *)applicationKeyWord
{
    [externalURLSchemeDelegateList removeObjectForKey:applicationKeyWord];
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
        ContactController *contactController = [[ContactListController sharedInstance] updateOrCreateContactWithUserInfo:userInfo];
        [[NotificationController sharedInstance] requestForLocationFromContact:contactController];
        
        if ([WAUUtilities isUserNotificationBadgeEnabled]) [[UIApplication sharedApplication] setApplicationIconBadgeNumber:[[UIApplication sharedApplication] applicationIconBadgeNumber] - 1];
    }
    completionHandler();
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    NSString *messageType = [userInfo objectForKey:kWAUDictionaryKeyContentType];
    UIBackgroundFetchResult fetchResult = UIBackgroundFetchResultNoData;
    
    [WAULog log:[NSString stringWithFormat:@"Received notification type: %@", messageType] from:self];
    
    if ([messageType isEqualToString:@"contact"]) {
        ContactController *contactController = [[ContactListController sharedInstance] createContactWithContactInfo:userInfo];
        if (contactController != nil) {
            [[ContactListController sharedInstance] refreshContactList];
            fetchResult = UIBackgroundFetchResultNewData;
        }
    }
    else if ([messageType isEqualToString:@"ping"]) {
        if ([[UIApplication sharedApplication] applicationState] != UIApplicationStateInactive) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            
            [[NotificationController sharedInstance] syncLocationRequestFromServer];
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
