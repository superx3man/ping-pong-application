//
//  ContactListViewController.m
//  WheArU
//
//  Created by Calvin Ng on 8/31/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "ContactListViewController.h"

#import "ContactMapViewController.h"
#import "RegistrationViewController.h"
#import "UpdateUserColorViewController.h"
#import "AddContactWithQRCodeViewController.h"

#import "WAUUtilities.h"


@interface ContactListViewController ()

@end

@implementation ContactListViewController
{
    IBOutlet UITableView *contactListTableView;
    
    IBOutlet UIImageView *currentUserIcon;
    IBOutlet UILabel *currentUserLabel;
    IBOutlet UILabel *currentUserFetchCount;
    
    IBOutlet UILabel *currentUserPingLabel;
    
    IBOutlet UIScrollView *buttonsScrollView;
    IBOutlet UIButton *profileSettingsButton;
    IBOutlet UIButton *addContactButton;
    
    ContactListController *contactListController;
    UserController *userController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[WAUUtilities applicationDelegate] addApplicationStateChangeDelegate:self];
    
    contactListController = [ContactListController sharedInstance];
    [contactListController addDelegate:self];
    userController = [UserController sharedInstance];
    [userController addDelegate:self];
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    UIBezierPath *circularPath=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0.f, 0.f, [currentUserIcon frame].size.width, [currentUserIcon frame].size.height) cornerRadius:MAX([currentUserIcon frame].size.width, [currentUserIcon frame].size.height)];
    [circle setPath:[circularPath CGPath]];
    [[currentUserIcon layer] setMask:circle];
    
    [profileSettingsButton setImage:[[[profileSettingsButton imageView] image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [[profileSettingsButton imageView] setContentMode:UIViewContentModeScaleAspectFit];
    [addContactButton setImage:[[[addContactButton imageView] image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [[addContactButton imageView] setContentMode:UIViewContentModeScaleAspectFit];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (![userController isUserRegistered]) return;
    
    [currentUserLabel setText:[userController username]];
    [currentUserIcon setImage:[userController userIcon]];
    
    [currentUserFetchCount setText:[NSString stringWithFormat:@"%d", [userController fetchCount]]];
    
    [[self view] setBackgroundColor:[userController userColor]];
    
    [currentUserPingLabel setTextColor:[userController wordColor]];
    [currentUserLabel setTextColor:[userController wordColor]];
    [currentUserFetchCount setTextColor:[userController wordColor]];
    
    [profileSettingsButton setTintColor:[userController wordColor]];
    [addContactButton setTintColor:[userController wordColor]];
    
    [self scrollToOriginalPositionAnimated:NO];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (![userController isUserRegistered]) {
        [self performSegueWithIdentifier:@"RegisterUserSegue" sender:self];
        return;
    }
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [self scrollToOriginalPositionAnimated:YES];
     } completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"OpenMapViewSegue"]) {
        ContactMapViewController *contactMapViewController = (ContactMapViewController *) [segue destinationViewController];
        [contactMapViewController setContactController:(ContactController *) sender];
    }
}

#pragma mark - Controls
#pragma mark Buttons

- (IBAction)didTapOnAddUser:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Connect with a Friend" message:@"Select one of the below options to add a new contact for Ping + Pong" preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *qrCodeAction = [UIAlertAction actionWithTitle:@"QR Code" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
                                   {
                                       [self performSegueWithIdentifier:@"AddUserWithQRCodeSegue" sender:sender];
                                   }];
    [alertController addAction:qrCodeAction];
    UIAlertAction *facebookAction = [UIAlertAction actionWithTitle:@"Facebook" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
                                     {
                                         [self performSegueWithIdentifier:@"AddUserWithFacebookSegue" sender:sender];
                                   }];
    [alertController addAction:facebookAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [alertController addAction:cancelAction];
    
    [alertController setModalPresentationStyle:UIModalPresentationPopover];
    [[alertController popoverPresentationController] setSourceView:[self view]];
    [[alertController popoverPresentationController] setSourceRect:[[self view] bounds]];
    [[alertController popoverPresentationController] setPermittedArrowDirections:0];
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Functions
#pragma mark Support

- (void)scrollToOriginalPositionAnimated:(BOOL)animated
{
    [buttonsScrollView scrollRectToVisible:CGRectMake(0.f, 0.f, 1.f, 1.f) animated:animated];
    for (ContactListTableViewCell *tableViewCell in [contactListTableView visibleCells]) {
        [tableViewCell scrollToOriginalPositionAnimated:animated];
    };
}

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

#pragma mark ContactListControllerDelegate

- (void)listUpdated:(ContactListController *)controller
{
    if (![WAUUtilities isApplicationRunningInBackground]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [contactListTableView reloadData];
            [contactListTableView layoutIfNeeded];
        });
    }
}

#pragma mark UITableViewDataSource

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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactListTableViewCell *cell = (ContactListTableViewCell *) [tableView dequeueReusableCellWithIdentifier:@"ContactCell"];
    [cell setDelegate:self];
    
    NSInteger row = [indexPath row];
    NSInteger section = [indexPath section];
    if (section == 0) {
        [cell setContactController:[[contactListController recentContactList] objectAtIndex:row]];
    }
    else if (section == 1) {
        [cell setContactController:[[contactListController contactList] objectAtIndex:row]];
    }
    return cell;
}

#pragma mark ContactListTableViewCellDelegate

- (void)tableViewCell:(ContactListTableViewCell *)cell didTapOnButton:(ContactController *)controller
{
    [contactListTableView setScrollEnabled:NO];
}

- (void)tableViewCell:(ContactListTableViewCell *)cell didReleaseButton:(ContactController *)controller
{
    [contactListTableView setScrollEnabled:YES];
}

- (void)tableViewCell:(ContactListTableViewCell *)cell didSwipeWithContactController:(ContactController *)controller
{
    [self performSegueWithIdentifier:@"OpenMapViewSegue" sender:controller];
}

#pragma mark ApplicationStateChangeDelegate

- (void)willEnterForeground
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [contactListTableView reloadData];
    });
}

@end
