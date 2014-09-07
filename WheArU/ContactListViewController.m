//
//  ContactListViewController.m
//  WheArU
//
//  Created by Calvin Ng on 8/31/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "ContactListViewController.h"

#import "ContactListTableViewCell.h"
#import "RegistrationViewController.h"
#import "UpdateUserColorViewController.h"

#import "ContactListController.h"
#import "UserController.h"

@interface ContactListViewController ()

@end

@implementation ContactListViewController
{
    IBOutlet HVTableView *contactListTableView;
    
    IBOutlet UIImageView *currentUserIcon;
    IBOutlet UILabel *currentUserLabel;
    IBOutlet UILabel *currentUserFetchCount;
    
    IBOutlet UILabel *currentUserPingLabel;
    
    ContactListController *contactListController;
    UserController *userController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [contactListTableView setHVTableViewDelegate:self];
    [contactListTableView setHVTableViewDataSource:self];
    
    contactListController = [[ContactListController alloc] init];
    userController = [[UserController alloc] init];
    [userController addDelegate:self];
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    UIBezierPath *circularPath=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, [currentUserIcon frame].size.width, [currentUserIcon frame].size.height) cornerRadius:MAX([currentUserIcon frame].size.width, [currentUserIcon frame].size.height)];
    [circle setPath:[circularPath CGPath]];
    [[currentUserIcon layer] setMask:circle];
}

- (void)viewDidAppear:(BOOL)animated
{
    if (![userController isUserRegistered]) {
        [self performSegueWithIdentifier:@"RegisterUserSegue" sender:self];
    }
    else {
        [currentUserLabel setText:[userController username]];
        [currentUserIcon setImage:[userController userIcon]];
        
        [currentUserFetchCount setText:[NSString stringWithFormat:@"%d", [userController fetchCount]]];
        
        [[self view] setBackgroundColor:[userController userColor]];
        
        [currentUserPingLabel setTextColor:[userController wordColor]];
        [currentUserLabel setTextColor:[userController wordColor]];
        [currentUserFetchCount setTextColor:[userController wordColor]];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"RegisterUserSegue"]) {
        RegistrationViewController *registerViewController = (RegistrationViewController *) [((UINavigationController *) [segue destinationViewController]) topViewController];
        [registerViewController setUserController:userController];
    }
    else if ([[segue identifier] isEqualToString:@"UpdateUserSegue"]) {
        UpdateUserColorViewController *updateUserColorViewController = (UpdateUserColorViewController *) [((UINavigationController *) [segue destinationViewController]) topViewController];
        [updateUserColorViewController setUserController:userController];
    }
}

#pragma mark - Controls
#pragma mark Long Press

- (IBAction)userDidLongPressOnUserInfo:(UILongPressGestureRecognizer *)sender
{
    if ([sender state] != UIGestureRecognizerStateBegan) return;
    
    [self performSegueWithIdentifier:@"UpdateUserSegue" sender:self];
}

#pragma mark - Functions
#pragma mark Support


#pragma mark - Delegates
#pragma mark UserControllerDelegate

- (void)userDidUpdateUsername:(UserController *)controller
{
    [currentUserLabel setText:[controller username]];
}

- (void)userDidUpdateUserIcon:(UserController *)controller
{
    [currentUserIcon setImage:[controller userIcon]];
}

- (void)userDidUpdateUserColor:(UserController *)controller
{
    [[self view] setBackgroundColor:[userController userColor]];
    
    [currentUserPingLabel setTextColor:[userController wordColor]];
    [currentUserLabel setTextColor:[userController wordColor]];
    [currentUserFetchCount setTextColor:[userController wordColor]];
}

#pragma mark HVTableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger count = 0;
    if (section == 0) {
        count = [[contactListController recentContactList] count];
    }
    else if (section == 1) {
        count = [[contactListController contactList] count];
    }
    return count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath isExpanded:(BOOL)isExpanded
{
    ContactListTableViewCell *cell = (ContactListTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    if (section == 0) {
        [cell setContact:[[contactListController recentContactList] objectAtIndex:row]];
    }
    else if (section == 1) {
        [cell setContact:[[contactListController contactList] objectAtIndex:row]];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView collapseCell: (UITableViewCell*)cell withIndexPath:(NSIndexPath*) indexPath
{
    
}

-(void)tableView:(UITableView *)tableView expandCell: (UITableViewCell*)cell withIndexPath:(NSIndexPath*) indexPath
{
    
}

#pragma mark HVTableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath isExpanded:(BOOL)isExpanded
{
    return 100.f;
}

@end
