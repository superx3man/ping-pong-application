//
//  AppDelegate.h
//  WheArU
//
//  Created by Calvin Ng on 8/31/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


extern NSString *const kWAUAppRemoteHost;

@protocol NotificationRegisteredDelegate;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) id<NotificationRegisteredDelegate> notificationDelegate;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end

@protocol NotificationRegisteredDelegate <NSObject>

@required
- (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
- (void)didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;

@end