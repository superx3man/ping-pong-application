//
//  AddContactWithFacebookViewController.m
//  WheArU
//
//  Created by Calvin Ng on 9/29/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "AddContactWithFacebookViewController.h"

#import "FacebookFriendListTableViewCell.h"
#import "FacebookUser.h"

#import "ContactListController.h"
#import "UserController.h"

#import "WAUConstant.h"
#import "WAULog.h"
#import "WAUServerConnector.h"
#import "WAUServerConnectorRequest.h"
#import "WAUUtilities.h"


NSString *const kWAUUserDictionaryKeyFacebookUserId = @"WAUFacebookUserId";

@interface AddContactWithFacebookViewController ()

@end

@implementation AddContactWithFacebookViewController
{
    IBOutlet UILabel *connectingLabel;
    IBOutlet UILabel *sorryLabel;
    IBOutlet UILabel *errorLabel;
    
    IBOutlet UIButton *tryAgainButton;
    IBOutlet UIButton *cancelButton;
    IBOutlet UIButton *connectButton;
    IBOutlet UIButton *loginButton;
    IBOutlet UIButton *errorOutButton;
    
    IBOutlet UITableView *friendListTableView;
    
    NSString *facebookUserId;
    NSMutableArray *facebookFriendList;
    NSMutableArray *selectedFacebookUserList;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *facebookUrlScheme = [NSString stringWithFormat:@"fb%@", [[NSBundle mainBundle] objectForInfoDictionaryKey:@"FacebookAppID"]];
    [[WAUUtilities applicationDelegate] addExternalURLSchemeDelegate:self forURLScheme:facebookUrlScheme];
    
    facebookUserId = [[NSUserDefaults standardUserDefaults] objectForKey:kWAUUserDictionaryKeyFacebookUserId];
    facebookFriendList = [[NSMutableArray alloc] init];
    selectedFacebookUserList = [[NSMutableArray alloc] init];
    
    [friendListTableView setDelegate:self];
    [friendListTableView setDataSource:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [connectingLabel setTextColor:[[UserController sharedInstance] wordColor]];
    [sorryLabel setTextColor:[[UserController sharedInstance] wordColor]];
    [errorLabel setTextColor:[[UserController sharedInstance] wordColor]];
    
    [tryAgainButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateNormal];
    [tryAgainButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateHighlighted];
    [tryAgainButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateSelected];
    [cancelButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateNormal];
    [cancelButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateHighlighted];
    [cancelButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateSelected];
    [connectButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateNormal];
    [connectButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateHighlighted];
    [connectButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateSelected];
    [loginButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateNormal];
    [loginButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateHighlighted];
    [loginButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateSelected];
    [errorOutButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateNormal];
    [errorOutButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateHighlighted];
    [errorOutButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateSelected];
    
    [[self view] setBackgroundColor:[[UserController sharedInstance] userColor]];
    
    [connectingLabel setAlpha:1.f];
    [sorryLabel setAlpha:0.f];
    [errorLabel setAlpha:0.f];
    
    [tryAgainButton setAlpha:1.f];
    [cancelButton setAlpha:0.f];
    [connectButton setAlpha:0.f];
    [loginButton setAlpha:0.f];
    [errorOutButton setAlpha:0.f];
    
    [friendListTableView setAlpha:0.f];
    
    [self validateFacebookSession:[[FBSession activeSession] state] != FBSessionStateCreatedTokenLoaded];
}

- (void)viewDidDisappear:(BOOL)animated
{
    for (FacebookUser *user in facebookFriendList) {
        [user purgePicture];
    }
    
    [super viewDidDisappear:animated];
}

#pragma mark - Controls
#pragma mark Button

- (IBAction)tapOnExitButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)tapOnConnectButton:(id)sender
{
    if ([selectedFacebookUserList count] != 0) {
        NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
        [userDictionary setObject:[[UserController sharedInstance] userId] forKey:kWAUDictionaryKeyUserId];
        [userDictionary setObject:selectedFacebookUserList forKey:kWAUDictionaryKeyExternalList];
        [userDictionary setObject:[NSNumber numberWithInt:WAUExternalPlatformFacebook] forKey:kWAUDictionaryKeyExternalType];
        
        WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUServerEndpointSyncLink method:@"POST" parameters:userDictionary];
        [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest)
         {
             [WAULog log:@"failed to get facebook friends' id" from:self];
         }];
        [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult)
         {
             [WAULog log:@"successfully retreive facebook friends' id" from:self];
             
             NSArray *friendList = [((NSDictionary *) requestResult) objectForKey:kWAUDictionaryKeyContactList];
             if (friendList != nil) {
                 for (NSDictionary *friendInfo in friendList) {
                     [[ContactListController sharedInstance] createContactWithContactInfo:friendInfo];
                 }
                 [[ContactListController sharedInstance] refreshContactList];
             }
         }];
        [[WAUServerConnector sharedInstance] sendRequest:request withTag:@"LinkFacebook"];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)tapOnLoginButton:(id)sender
{
    [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState) animations:^
     {
         [connectingLabel setAlpha:1.f];
         [sorryLabel setAlpha:0.f];
         [errorLabel setAlpha:0.f];
         
         [tryAgainButton setAlpha:1.f];
         [cancelButton setAlpha:0.f];
         [connectButton setAlpha:0.f];
         [loginButton setAlpha:0.f];
         [errorOutButton setAlpha:0.f];
         
         [friendListTableView setAlpha:0.f];
     } completion:nil];
    
    [self validateFacebookSession:YES];
}

#pragma mark - Functions
#pragma mark Support

- (void)validateFacebookSession:(BOOL)shouldShowLoginUI
{
    NSArray *permissionList = [NSArray arrayWithObjects:@"public_profile", @"user_friends", nil];
    [FBSession openActiveSessionWithReadPermissions:permissionList allowLoginUI:shouldShowLoginUI completionHandler:^(FBSession *session, FBSessionState state, NSError *error)
     {
         [self sessionStateChanged:session state:state error:error];
     }];
}

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error
{
    if (!error && state == FBSessionStateOpen) {
        [WAULog log:@"session opened" from:self];
        
        [self updateUserExternalId];
        [self retrieveFriendList];
    }
    if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed) {
        [WAULog log:@"session closed" from:self];
    }
    if (error) {
        [WAULog log:@"session errored out" from:self];
        [[FBSession activeSession] closeAndClearTokenInformation];
        
        [self performSelectorOnMainThread:@selector(showLoginScreen) withObject:nil waitUntilDone:NO];
    }
}

- (void)showLoginScreen
{
    [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState) animations:^
     {
         [connectingLabel setAlpha:0.f];
         [sorryLabel setAlpha:0.f];
         [errorLabel setAlpha:1.f];
         
         [tryAgainButton setAlpha:0.f];
         [cancelButton setAlpha:0.f];
         [connectButton setAlpha:0.f];
         [loginButton setAlpha:1.f];
         [errorOutButton setAlpha:1.f];
         
         [friendListTableView setAlpha:0.f];
     } completion:nil];
}

- (void)updateUserExternalId
{
    [FBRequestConnection startWithGraphPath:@"/me" parameters:nil HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error)
     {
         NSString *externalId = [(NSDictionary *) result objectForKey:@"id"];
         if (externalId == nil) return;
         
         if (![facebookUserId isEqualToString:externalId]) {
             facebookUserId = externalId;
             if ([[UserController sharedInstance] userId] == nil) return;
             
             NSMutableDictionary *userDictionary = [[NSMutableDictionary alloc] init];
             [userDictionary setObject:[[UserController sharedInstance] userId] forKey:kWAUDictionaryKeyUserId];
             [userDictionary setObject:facebookUserId forKey:kWAUDictionaryKeyExternalId];
             [userDictionary setObject:[NSNumber numberWithInt:WAUExternalPlatformFacebook] forKey:kWAUDictionaryKeyExternalType];
             
             WAUServerConnectorRequest *request = [[WAUServerConnectorRequest alloc] initWithEndPoint:kWAUServerEndpointLinkExternal method:@"POST" parameters:userDictionary];
             [request setFailureHandler:^(WAUServerConnectorRequest *connectorRequest)
              {
                  [WAULog log:@"failed to link facebook" from:self];
              }];
             [request setSuccessHandler:^(WAUServerConnectorRequest *connectorRequest, NSObject *requestResult)
              {
                  [WAULog log:@"successfully link to facebook" from:self];
                  
                  [[NSUserDefaults standardUserDefaults] setObject:facebookUserId forKey:kWAUUserDictionaryKeyFacebookUserId];
              }];
             [[WAUServerConnector sharedInstance] sendRequest:request withTag:@"LinkFacebook"];
         }
     }];
}

- (void)retrieveFriendList
{
    [FBRequestConnection startWithGraphPath:@"/me/friends" parameters:[NSDictionary dictionaryWithObjectsAndKeys:@"id,name,picture", @"fields", nil] HTTPMethod:@"GET" completionHandler:^(FBRequestConnection *connection, id result, NSError *error)
     {
         NSArray *friendList = [(NSDictionary *) result objectForKey:@"data"];
         for (NSDictionary *friendInfo in friendList) {
             NSString *friendId = [friendInfo objectForKey:@"id"];
             NSString *friendName = [friendInfo objectForKey:@"name"];
             
             NSString *friendPicture = nil;
             NSDictionary *friendPictureInfo = [[friendInfo objectForKey:@"picture"] objectForKey:@"data"];
             if (friendPictureInfo != nil) {
                 if (![[friendPictureInfo objectForKey:@"is_silhouette"] boolValue]) {
                     friendPicture = [friendPictureInfo objectForKey:@"url"];
                 }
             }
             
             [facebookFriendList addObject:[[FacebookUser alloc] initWithId:friendId name:friendName pictureLink:friendPicture]];
         }
         [self performSelectorOnMainThread:@selector(handleFriendList) withObject:nil waitUntilDone:NO];
     }];
}

- (void)handleFriendList
{
    if ([facebookFriendList count] == 0) {
        [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState) animations:^
         {
             [connectingLabel setAlpha:0.f];
             [sorryLabel setAlpha:1.f];
             [errorLabel setAlpha:0.f];
             
             [tryAgainButton setAlpha:1.f];
             [cancelButton setAlpha:0.f];
             [connectButton setAlpha:0.f];
             [loginButton setAlpha:0.f];
             [errorOutButton setAlpha:0.f];
             
             [friendListTableView setAlpha:0.f];
         } completion:nil];
    }
    else {
        [friendListTableView reloadData];
        [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState) animations:^
         {
             [connectingLabel setAlpha:0.f];
             [sorryLabel setAlpha:0.f];
             [errorLabel setAlpha:0.f];
             
             [tryAgainButton setAlpha:0.f];
             [cancelButton setAlpha:1.f];
             [connectButton setAlpha:1.f];
             [loginButton setAlpha:0.f];
             [errorOutButton setAlpha:0.f];
             
             [friendListTableView setAlpha:1.f];
         } completion:nil];
    }
}

#pragma mark - Delegate
#pragma mark ExternalURLSchemeDelegate

- (BOOL)handleOpenURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication
{
    return [FBAppCall handleOpenURL:url sourceApplication:sourceApplication];
}

#pragma mark ApplicationStateChangeDelegate

- (void)didBecomeActive
{
    [FBAppCall handleDidBecomeActive];
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [facebookFriendList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FacebookFriendListTableViewCell *cell = (FacebookFriendListTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"FacebookFriendCell"];
    
    FacebookUser *user = [facebookFriendList objectAtIndex:[indexPath row]];
    [cell setUser:user];
    return cell;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *selectedUserId = [[facebookFriendList objectAtIndex:[indexPath row]] userId];
    if ([selectedFacebookUserList containsObject:selectedUserId]) {
        [selectedFacebookUserList removeObject:selectedUserId];
        [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryNone];
    }
    else {
        [selectedFacebookUserList addObject:selectedUserId];
        [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
    }
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.f;
}

@end
