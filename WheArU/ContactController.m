//
//  ContactController.m
//  WheArU
//
//  Created by Calvin Ng on 9/15/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "ContactController.h"

#import "UIColor+Hex.h"
#import "WAULog.h"
#import "WAUServerConnector.h"
#import "WAUServerConnectorRequest.h"


@implementation ContactController
{
    Contact *currentContact;
}

- (id)initWithContact:(Contact *)contact
{
    if (self = [self init]) {
        currentContact = contact;
        
        [super setUserId:[currentContact userId]];
        
        [super setPlatform:[currentContact platform]];
        [super setNotificationKey:[currentContact notificationKey]];
        
        [super setUsername:[currentContact username]];
        [super setUserColor:[UIColor colorFromHexString:[currentContact userColor]]];
        
        [super setUserIconState:WAUImageIconStateNoIcon];
        if ([currentContact userIconLink] != nil) {
            [super setUserIconLink:[currentContact userIconLink]];
            if ([currentContact userIcon] == nil) {
                [super setUserIconState:WAUImageIconStateNotSynced];
                [self downloadUserIcon];
            }
            else {
                [super setUserIcon:[UIImage imageWithData:[currentContact userIcon]]];
                [super setUserIconState:WAUImageIconStateSynced];
            }
        }
        
        _version = [currentContact version];
        _lastUpdated = [currentContact lastUpdated];
        
        _locationState = [currentContact locationState];
        if (_locationState == WAUContactLocationStateAvailable || _locationState == WAUContactLocationStatePending) {
            _latitude = [currentContact latitude];
            _longitude = [currentContact longitude];
            _altitude = [currentContact altitude];
            _accuracy = [currentContact accuracy];
        }
    }
    return self;
}

#pragma mark - Functions
#pragma mark Support

- (void)downloadUserIcon
{
    if ([self userIconLink] == nil || [self userIconState] != WAUImageIconStateNotSynced) return;
    
    [self setUserIconState:WAUImageIconStateSyncing];
    
    NSURL *url = [NSURL URLWithString:[self userIconLink]];
    WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithURL:url method:@"GET" parameters:nil];
    [request setEncryptionNeeded:NO];
    [request setDecryptionNeeded:NO];
    [request setResultInJSON:NO];
    [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest)
    {
        [WAULog log:[NSString stringWithFormat:@"icon link failed to download for contact %@", [self userId]] from:self];
        [self setUserIconState:WAUImageIconStateNotSynced];
    }];
    [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult)
    {
        UIImage *icon = [[UIImage alloc] initWithData:(NSData *)requestResult];
        [WAULog log:[NSString stringWithFormat:@"icon: %@ for contact %@", icon, [self userId]] from:self];
        
        [self setUserIcon:icon];
        [self setUserIconState:WAUImageIconStateSynced];
    }];
    [[WAUServerConnector sharedInstance] sendRequest:request withTag:[NSString stringWithFormat:@"DownloadContactIcon-%@", [currentContact userId]]];
}

#pragma mark External


#pragma mark - Properties

- (void)setUserIcon:(UIImage *)userIcon
{
    if ([UIImagePNGRepresentation([self userIcon]) isEqualToData:UIImagePNGRepresentation(userIcon)]) return;
    [super setUserIcon:userIcon];
    
    [currentContact setUserIcon:UIImageJPEGRepresentation(userIcon, 1.f)];
    [[self managedObjectContext] save:nil];
    
    if ([self delegate] != nil) {
        if ([[self delegate] respondsToSelector:@selector(contactDidUpdateUserIcon:)]) [[self delegate] contactDidUpdateUserIcon:self];
    }
}

@end
