//
//  AppDelegate.m
//  WheArU
//
//  Created by Calvin Ng on 8/31/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "AppDelegate.h"

#import "Contact.h"

@interface AppDelegate ()

@end

@implementation AppDelegate
            

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /*
    NSManagedObjectContext *context = [self managedObjectContext];
    Contact *contactInfo = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:context];
    [contactInfo setUsername:@"Ally Tam"];
    [contactInfo setLastUpdated:1409606089];
    [contactInfo setUserColor:@"FFAAAA"];
    
    Contact *contactInfo2 = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:context];
    [contactInfo2 setUsername:@"Emily Ng"];
    [contactInfo2 setLastUpdated:1409602489];
    [contactInfo2 setUserColor:@"FFE3AA"];
    
    Contact *contactInfo4 = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:context];
    [contactInfo4 setUsername:@"Simon Ng"];
    [contactInfo4 setLastUpdated:1409170389];
    [contactInfo4 setUserColor:@"7887AB"];
    
    Contact *contactInfo3 = [NSEntityDescription insertNewObjectForEntityForName:@"Contact" inManagedObjectContext:context];
    [contactInfo3 setUsername:@"Aki Zhuang"];
    [contactInfo3 setLastUpdated:1409170489];
    [contactInfo3 setUserColor:@"B77AAB"];
    
    NSError *error;
    if (![context save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
    else {
        NSLog(@"Saved");
    }
     */
    
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
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self saveContext];
}

#pragma mark - Core Data stack

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

#pragma mark - Core Data Saving support

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
