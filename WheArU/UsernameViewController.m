//
//  UsernameViewController.m
//  WheArU
//
//  Created by Calvin Ng on 9/2/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "UsernameViewController.h"

#import "AppDelegate.h"

@interface UsernameViewController ()

@end

@implementation UsernameViewController
{
    IBOutlet UILabel *questionLabel;
    IBOutlet UITextView *usernameTextView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self view] setBackgroundColor:[self userColor]];
    
    CGFloat red, green, blue;
    [[self userColor] getRed:&red green:&green blue:&blue alpha:nil];
    
    int lightCount = 0;
    if (red >= 0.8f) lightCount++;
    if (green >= 0.8f) lightCount++;
    if (blue >= 0.8f) lightCount++;
    
    UIColor *wordColor = lightCount >= 2 ? [UIColor lightGrayColor] : [UIColor whiteColor];
    [questionLabel setTextColor:wordColor];
    [usernameTextView setTextColor:wordColor];
    
    [usernameTextView becomeFirstResponder];
}

#pragma mark - Functions
#pragma mark Support

- (void)saveUser
{
    [[self userController] createUser];
    [[self userController] setUsername:[usernameTextView text]];
    [[self userController] setUserColor:[self userColor]];
}

#pragma mark - Delegates
#pragma mark UITextViewDelegate

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if (![text isEqual:@"\n"]) return YES;
    if ([text isEqual:@"\n"] && [[textView text] length] == 0) return NO;
    
    [textView resignFirstResponder];
   
    [self saveUser];
    [self dismissViewControllerAnimated:YES completion:nil];
    
    return NO;
}

@end
