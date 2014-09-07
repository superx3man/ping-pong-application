//
//  UpdateUserColorViewController.m
//  WheArU
//
//  Created by Calvin Ng on 9/7/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "UpdateUserColorViewController.h"

#import "UpdateUsernameViewController.h"

@interface UpdateUserColorViewController ()

@end

@implementation UpdateUserColorViewController
{
    IBOutlet UICollectionView *colorCollectionView;
    IBOutlet UIButton *keepOriginalButton;
    
    NSArray *colorList;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    colorList = [UserController availableUserColor];
    [keepOriginalButton setBackgroundColor:[[self userController] userColor]];
    [keepOriginalButton setTitleColor:[[self userController] wordColor] forState:UIControlStateNormal];
    [keepOriginalButton setTitleColor:[[self userController] wordColor] forState:UIControlStateHighlighted];
    [keepOriginalButton setTitleColor:[[self userController] wordColor] forState:UIControlStateSelected];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UpdateUsernameViewController *usernameViewController = [segue destinationViewController];
    [usernameViewController setUserController:[self userController]];
    
    if ([[segue identifier] isEqualToString:@"ColorPickSegue"]) {
        NSInteger selectedIndex = [[[colorCollectionView indexPathsForSelectedItems] objectAtIndex:0] row];
        UIColor *selectedColor = [colorList objectAtIndex:selectedIndex];
        if (![selectedColor isEqual:[[self userController] userColor]]) [[self userController] setUserColor:selectedColor];
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
