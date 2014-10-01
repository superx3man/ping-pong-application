//
//  AppDelegate.h
//  WheArU
//
//  Created by Calvin Ng on 8/31/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import <FacebookSDK/FacebookSDK.h>


@protocol NotificationRegistrationDelegate;
@protocol ApplicationStateChangeDelegate;
@protocol ExternalURLSchemeDelegate;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;

@property (nonatomic, weak) id<NotificationRegistrationDelegate> notificationRegistrationDelegate;

@property (nonatomic, readonly, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, readonly, strong) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, readonly, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)addApplicationStateChangeDelegate:(id<ApplicationStateChangeDelegate>)delegate;

- (void)addExternalURLSchemeDelegate:(id<ExternalURLSchemeDelegate>)delegate forApplicationKeyWord:(NSString *)applicationKeyWord;
- (void)removeExternalURLSchemeDelegateforApplicationKeyWord:(NSString *)applicationKeyWord;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end

@protocol NotificationRegistrationDelegate <NSObject>

@optional
- (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;

- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

@end

@protocol ApplicationStateChangeDelegate <NSObject>

@optional
- (void)willEnterForeground;
- (void)didBecomeActive;

@end

@protocol ExternalURLSchemeDelegate <NSObject>

@required
- (BOOL)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication;

@end
