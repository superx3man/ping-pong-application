//
//  UpdateUserColorViewController.m
//  WheArU
//
//  Created by Calvin Ng on 9/7/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "UpdateUserColorViewController.h"

#import "UpdateUsernameViewController.h"

#import "UserController.h"


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
    [keepOriginalButton setBackgroundColor:[[UserController sharedInstance] userColor]];
    [keepOriginalButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateNormal];
    [keepOriginalButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateHighlighted];
    [keepOriginalButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateSelected];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"ColorPickSegue"]) {
        NSInteger selectedIndex = [[[colorCollectionView indexPathsForSelectedItems] objectAtIndex:0] row];
        UIColor *selectedColor = [colorList objectAtIndex:selectedIndex];
        if (![selectedColor isEqual:[[UserController sharedInstance] userColor]]) [[UserController sharedInstance] setUserColor:selectedColor];
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
