//
//  RegistrationViewController.m
//  WheArU
//
//  Created by Calvin Ng on 9/2/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "RegistrationViewController.h"

#import "UsernameViewController.h"

#import "UserController.h"

#import "UIColor+Hex.h"


@interface RegistrationViewController ()

@end

@implementation RegistrationViewController
{
    IBOutlet UICollectionView *colorCollectionView;
    
    NSArray *colorList;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    colorList = [UserController availableUserColor];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ColorPickSegue"]) {
        UsernameViewController *usernameViewController = [segue destinationViewController];
        NSInteger selectedIndex = [[[colorCollectionView indexPathsForSelectedItems] objectAtIndex:0] row];
        [usernameViewController setUserColor:[colorList objectAtIndex:selectedIndex]];
    }
}

#pragma mark - Delegates
#pragma mark UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 9;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    UICollectionViewCell *viewCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ColorCollectionViewCell" forIndexPath:indexPath];
    [viewCell setBackgroundColor:[colorList objectAtIndex:[indexPath row]]];
    return viewCell;
}

@end
