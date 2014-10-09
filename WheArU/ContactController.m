//
//  ContactController.m
//  WheArU
//
//  Created by Calvin Ng on 9/15/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "ContactController.h"

#import "UserController.h"

#import "APAsyncDictionary.h"
#import "UIColor+Hex.h"
#import "WAUConstant.h"
#import "WAULog.h"
#import "WAUServerConnector.h"
#import "WAUServerConnectorRequest.h"
#import "WAUUtilities.h"


@implementation ContactController
{
    NSMutableArray *delegateList;
    
    Contact *currentContact;
}

- (id)initWithContact:(Contact *)contact
{
    if (self = [self init]) {
        delegateList = [[NSMutableArray alloc] init];
        currentContact = contact;
        
        [super setUserId:[currentContact userId]];
        
        [super setUsername:[currentContact username]];
        [super setUserColor:[UIColor colorFromHexString:[currentContact userColor]]];
        
        if ([currentContact userIcon] != nil) [super setUserIcon:[UIImage imageWithData:[currentContact userIcon]]];
        
        _version = [currentContact version];
        _ping = [currentContact ping];
        _lastUpdated = [currentContact lastUpdated];
        
        _latitude = [currentContact latitude];
        _longitude = [currentContact longitude];
        _altitude = [currentContact altitude];
        _accuracy = [currentContact accuracy];
        
        if (_version == 0) [self syncContact];
        _pingStatus = _ping == 0 ? WAUContactPingStatusNone : WAUContactPingStatusNotification;
    }
    return self;
}

#pragma mark - Functions
#pragma mark Support

- (void)syncContact
{
    if ([[UserController sharedInstance] userId] == nil) return;
    
    NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
    [userDictionary setObject:[[UserController sharedInstance] userId] forKey:kWAUDictionaryKeyUserId];
    [userDictionary setObject:[self userId] forKey:kWAUDictionaryKeyContactId];
    [userDictionary setObject:[NSNumber numberWithBool:[self version] == 0] forKey:kWAUDictionaryKeyIsNewContact];
    
    WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUServerEndpointContactSync method:@"POST" parameters:userDictionary];
    [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest)
     {
         [WAULog log:[NSString stringWithFormat:@"failed to sync contact: %@", [self userId]] from:self];
     }];
    [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult)
     {
         NSString *username = [(NSDictionary *) requestResult objectForKey:kWAUDictionaryKeyUsername];
         NSString *userColorString = [(NSDictionary *) requestResult objectForKey:kWAUDictionaryKeyUserColor];
         NSString *userIconString = [(NSDictionary *) requestResult objectForKey:kWAUDictionaryKeyUserIcon];
         NSNumber *version = [(NSDictionary *) requestResult objectForKey:kWAUDictionaryKeyVersion];
         
         [WAULog log:[NSString stringWithFormat:@"synced contact: %@ version: %d", [self userId], [version intValue]] from:self];
         
         [self setUsername:username];
         [self setUserColor:[UIColor colorFromHexString:userColorString]];
         if (userIconString != nil) [self setUserIcon:[[UIImage alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:userIconString options:kNilOptions]]];
         [self setVersion:[version intValue]];
     }];
    [[WAUServerConnector sharedInstance] sendRequest:request withTag:[NSString stringWithFormat:@"SyncContact-%@", [self userId]]];
}

#pragma mark External

- (void)addDelegate:(id<ContactControllerDelegate>)delegate;
{
    @synchronized(delegateList) {
        [delegateList addObject:[NSValue valueWithNonretainedObject:delegate]];
    }
}

- (void)removeDelegate:(id<ContactControllerDelegate>)delegate
{
    @synchronized(delegateList) {
        [delegateList removeObject:[NSValue valueWithNonretainedObject:delegate]];
    }
}

- (void)validateContactVersion:(int)version
{
    if ([self version] != version) [self syncContact];
}

- (void)removeFromList
{
    [[self managedObjectContext] deleteObject:currentContact];
    [[self managedObjectContext] save:nil];
}

#pragma mark - Properties

- (void)setUsername:(NSString *)username
{
    if ([[self username] isEqualToString:username]) return;
    [super setUsername:username];
    
    [currentContact setUsername:username];
    [[self managedObjectContext] save:nil];
    
    [WAUUtilities object:self performSelector:@selector(contactDidUpdateUsername:) onDelegateList:delegateList];
}

- (void)setUserIcon:(UIImage *)userIcon
{
    if ([UIImagePNGRepresentation([self userIcon]) isEqualToData:UIImagePNGRepresentation(userIcon)]) return;
    [super setUserIcon:userIcon];
    
    [currentContact setUserIcon:UIImageJPEGRepresentation(userIcon, 1.f)];
    [[self managedObjectContext] save:nil];
    
    [WAUUtilities object:self performSelector:@selector(contactDidUpdateUserIcon:) onDelegateList:delegateList];
}

- (void)setUserColor:(UIColor *)userColor
{
    if ([[self userColor] isEqual:userColor]) return;
    [super setUserColor:userColor];
    
    [currentContact setUserColor:[UIColor hexStringFromColor:userColor]];
    [[self managedObjectContext] save:nil];
    
    [WAUUtilities object:self performSelector:@selector(contactDidUpdateUserColor:) onDelegateList:delegateList];
}

- (void)setVersion:(int32_t)version
{
    if (_version == version) return;
    _version = version;
    
    [currentContact setVersion:version];
    [[self managedObjectContext] save:nil];
}

- (void)incrementPing:(int)count
{
    [self setPing:[self ping] + count];
}

- (void)setPing:(int16_t)ping
{
    if (_ping == ping) return;
    _ping = ping;
    
    [currentContact setPing:ping];
    [[self managedObjectContext] save:nil];
    
    if ([self pingStatus] != WAUContactPingStatusPinging) {
        [self setPingStatus:ping == 0 ? WAUContactPingStatusNone : WAUContactPingStatusNotification];
    }
}

- (void)setPingStatus:(WAUContactPingStatus)pingStatus
{
    if (_pingStatus == pingStatus) return;
    _pingStatus = pingStatus;
    
    if (pingStatus != WAUContactPingStatusNotification) [WAUUtilities object:self performSelector:@selector(contactDidUpdatePingStatus:) onDelegateList:delegateList];
}

- (void)setLastUpdated:(int64_t)lastUpdated
{
    [self setLastUpdated:lastUpdated withPingCount:0];
}

- (void)setLastUpdated:(int64_t)lastUpdated withPingCount:(int16_t)pingCount
{
    _lastUpdated = lastUpdated;
    
    [currentContact setLastUpdated:lastUpdated];
    [[self managedObjectContext] save:nil];
    
    [self incrementPing:pingCount];
    
    [WAUUtilities object:self performSelector:@selector(contactDidUpdateLocation:) onDelegateList:delegateList];
}

- (void)setLatitude:(double)latitude
{
    if (_latitude == latitude) return;
    _latitude = latitude;
    
    [currentContact setLatitude:latitude];
    [[self managedObjectContext] save:nil];
}

- (void)setLongitude:(double)longitude
{
    if (_longitude == longitude) return;
    _longitude = longitude;
    
    [currentContact setLongitude:longitude];
    [[self managedObjectContext] save:nil];
}

- (void)setAltitude:(double)altitude
{
    if (_altitude == altitude) return;
    _altitude = altitude;
    
    [currentContact setAltitude:altitude];
    [[self managedObjectContext] save:nil];
}

- (void)setAccuracy:(double)accuracy
{
    if (_accuracy == accuracy) return;
    _accuracy = accuracy;
    
    [currentContact setAccuracy:accuracy];
    [[self managedObjectContext] save:nil];
}

@end
