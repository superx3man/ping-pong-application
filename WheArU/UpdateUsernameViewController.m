//
//  UpdateUsernameViewController.m
//  WheArU
//
//  Created by Calvin Ng on 9/7/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "UpdateUsernameViewController.h"

#import "UpdateUserIconViewController.h"

@interface UpdateUsernameViewController ()

@end

@implementation UpdateUsernameViewController
{
    IBOutlet UILabel *questionLabel;
    IBOutlet UITextView *usernameTextView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self view] setBackgroundColor:[[self userController] userColor]];
    [questionLabel setTextColor:[[self userController] wordColor]];
    [usernameTextView setTextColor:[[self userController] wordColor]];
    
    [usernameTextView setText:[[self userController] username]];
    [usernameTextView becomeFirstResponder];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UpdateUserIconViewController *userIconViewController = [segue destinationViewController];
    [userIconViewController setUserController:[self userController]];
}

#pragma mark - Delegates
#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (![text isEqual:@"\n"]) return YES;
    if ([text isEqual:@"\n"] && [[textView text] length] == 0) return NO;
    
    [textView resignFirstResponder];
    if (![[textView text] isEqualToString:[[self userController] username]]) [[self userController] setUsername:[textView text]];
    
    [self performSegueWithIdentifier:@"UsernameSetSegue" sender:self];
    
    return NO;
}

@end
