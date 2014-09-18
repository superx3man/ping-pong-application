//
//  UpdateUsernameViewController.m
//  WheArU
//
//  Created by Calvin Ng on 9/7/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "UpdateUsernameViewController.h"

#import "UpdateUserIconViewController.h"

#import "UserController.h"


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
    
    [[self view] setBackgroundColor:[[UserController sharedInstance] userColor]];
    [questionLabel setTextColor:[[UserController sharedInstance] wordColor]];
    [usernameTextView setTextColor:[[UserController sharedInstance] wordColor]];
    
    [usernameTextView setText:[[UserController sharedInstance] username]];
    [usernameTextView becomeFirstResponder];
}

#pragma mark - Delegates
#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (![text isEqual:@"\n"]) return YES;
    if ([text isEqual:@"\n"] && [[textView text] length] == 0) return NO;
    
    [textView resignFirstResponder];
    if (![[textView text] isEqualToString:[[UserController sharedInstance] username]]) [[UserController sharedInstance] setUsername:[textView text]];
    
    [self performSegueWithIdentifier:@"UsernameSetSegue" sender:self];
    
    return NO;
}

@end
