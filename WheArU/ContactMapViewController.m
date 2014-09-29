//
//  ContactMapViewController.m
//  WheArU
//
//  Created by Calvin Ng on 9/21/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "ContactMapViewController.h"

#import "ContactMapAnnotation.h"
#import "ContactMapAnnotationView.h"

#import "NotificationController.h"
#import "ContactListController.h"

#import "MKCircle+ContactController.h"
#import "MKMapView+SharedInstance.h"
#import "UIView+Shake.h"
#import "WAUConstant.h"


@interface ContactMapViewController ()

@end

@implementation ContactMapViewController
{
    IBOutlet UIImageView *userIconImageView;
    
    IBOutlet UILabel *usernameLabel;
    IBOutlet UILabel *userLastUpdatedLabel;
    IBOutlet UILabel *userLastUpdatedDescriptionLabel;
    
    IBOutlet UIView *mapContainerView;
    MKMapView *contactMapView;
    
    IBOutlet UIScrollView *buttonsScrollView;
    IBOutlet UIButton *locateButton;
    IBOutlet UIButton *deleteButton;
    
    IBOutlet UIView *pingStatusView;
    IBOutlet UILabel *pingNumberLabel;
    IBOutlet UIActivityIndicatorView *pingSpinner;
    IBOutlet UIImageView *pingSuccessImageView;
    IBOutlet UIImageView *pingFailedImageView;
    
    NSMutableDictionary *annotationDictionary;
    BOOL isMapViewFirstAppeared;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    UIBezierPath *circularPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, [userIconImageView frame].size.width, [userIconImageView frame].size.height) cornerRadius:MAX([userIconImageView frame].size.width, [userIconImageView frame].size.height)];
    [circle setPath:[circularPath CGPath]];
    [[userIconImageView layer] setMask:circle];
    
    [[pingStatusView layer] setCornerRadius:2.f];
    
    annotationDictionary = [[NSMutableDictionary alloc] init];
    isMapViewFirstAppeared = YES;
    
    contactMapView = [MKMapView sharedInstance];
    [contactMapView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [mapContainerView addSubview:contactMapView];
    [mapContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contactMapView]|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(contactMapView)]];
    [mapContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contactMapView]|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(contactMapView)]];
    
    [locateButton setImage:[[[locateButton imageView] image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [[locateButton imageView] setContentMode:UIViewContentModeScaleAspectFit];
    [deleteButton setImage:[[[deleteButton imageView] image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [[deleteButton imageView] setContentMode:UIViewContentModeScaleAspectFit];
    
    [pingSuccessImageView setImage:[[pingSuccessImageView image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    [pingFailedImageView setImage:[[pingFailedImageView image] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [[self contactController] addDelegate:self];
    [contactMapView setDelegate:self];
    
    [usernameLabel setText:[[self contactController] username]];
    [[self view] setBackgroundColor:[[self contactController] userColor]];
    
    [self updateLastUpdatedLabelWithCurrentTime];
    
    [usernameLabel setTextColor:[[self contactController] wordColor]];
    [userLastUpdatedLabel setTextColor:[[self contactController] wordColor]];
    [userLastUpdatedDescriptionLabel setTextColor:[[self contactController] wordColor]];
    
    [locateButton setTintColor:[[self contactController] wordColor]];
    [deleteButton setTintColor:[[self contactController] wordColor]];
    
    [pingStatusView setBackgroundColor:[[self contactController] wordColor]];
    [pingNumberLabel setTextColor:[[self contactController] userColor]];
    [pingSpinner setColor:[[self contactController] wordColor]];
    [pingSuccessImageView setTintColor:[[self contactController] wordColor]];
    [pingFailedImageView setTintColor:[[self contactController] wordColor]];
    
    [self layoutPingStatusView];
    
    if ([[self contactController] userIcon] != nil) [userIconImageView setImage:[[self contactController] userIcon]];
    
    [self createAnnotationForContactController:[self contactController]];
    [self zoomToFitMapAnnotations:contactMapView withCurrentLocation:NO];
    
    [contactMapView setShowsUserLocation:YES];
    
    [self scrollToOriginalPositionAnimated:NO];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [contactMapView setShowsUserLocation:NO];
    
    [[self contactController] removeDelegate:self];
    [contactMapView setDelegate:nil];
    
    for (NSString *userId in annotationDictionary) {
        NSArray *annotationInfo = [annotationDictionary objectForKey:userId];
        [contactMapView removeAnnotation:[annotationInfo objectAtIndex:0]];
        [contactMapView removeOverlay:[annotationInfo objectAtIndex:1]];
    }
    [annotationDictionary removeAllObjects];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [self scrollToOriginalPositionAnimated:YES];
     } completion:nil];
}

#pragma mark - Controls

- (IBAction)tapOnDelete:(id)sender
{
    [[ContactListController sharedInstance] blockContactController:[self contactController]];
    [[ContactListController sharedInstance] refreshContactList];
    [[self navigationController] popViewControllerAnimated:YES];
}

- (IBAction)tapOnLocate:(id)sender
{
    [[NotificationController sharedInstance] requestForLocationFromContact:[self contactController]];
}

- (IBAction)tapOnSideSpace:(id)sender
{
    [[self navigationController] popViewControllerAnimated:YES];
}

#pragma mark - Functions
#pragma mark Support

- (void)scrollToOriginalPositionAnimated:(BOOL)animated
{
    [buttonsScrollView scrollRectToVisible:CGRectMake(0.f, 0.f, 1.f, 1.f) animated:animated];
}

- (void)createAnnotationForContactController:(ContactController *)contactController
{
    NSArray *annotationInfo = [annotationDictionary objectForKey:[contactController userId]];
    if (annotationInfo != nil) {
        [contactMapView removeAnnotation:[annotationInfo objectAtIndex:0]];
        [contactMapView removeOverlay:[annotationInfo objectAtIndex:1]];
    }
    
    if (!([contactController latitude] == 0.f && [contactController longitude] == 0.f && [contactController altitude] == 0.f && [contactController accuracy] == 0.f)) {
        ContactMapAnnotation *contactAnnotation = [[ContactMapAnnotation alloc] initWithContactController:contactController];
        [contactMapView addAnnotation:contactAnnotation];
        MKCircle *accuracyOverlay = [contactAnnotation accuracyOverlay];
        [contactMapView addOverlay:accuracyOverlay];
        [annotationDictionary setObject:[NSArray arrayWithObjects:contactAnnotation, accuracyOverlay, nil] forKey:[contactController userId]];
    }
}

- (void)updateLastUpdatedLabelWithCurrentTime
{
    if ([self contactController] == nil) return;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLastUpdatedLabelWithCurrentTime) object:nil];
    
    int64_t lastUpdated = [[self contactController] lastUpdated];
    int64_t timeElpased = [[NSDate date] timeIntervalSince1970] - lastUpdated;
    
    NSTimeInterval nextTimeInterval = -1;
    int64_t count = 0;
    NSString *unit = @"";
    if (timeElpased < 60) {
        nextTimeInterval = 60 - timeElpased;
        count = 0;
        unit = @"!!!";
    }
    else if (timeElpased < 3600) {
        nextTimeInterval = 60 - timeElpased % 60;
        count = timeElpased / 60;
        unit = @"mn";
    }
    else if (timeElpased < 86400) {
        nextTimeInterval = 3600 - timeElpased % 3600;
        count = timeElpased / 3600;
        unit = @"hr";
    }
    else {
        nextTimeInterval = 86400 - timeElpased % 86400;
        count = timeElpased / 86400;
        unit = @"dy";
    }
    
    if (count > 1) unit = [NSString stringWithFormat:@"%@s", unit];
    NSString *lastUpdatedDescription = count > 0 ? [NSString stringWithFormat:@"%lld%@", count, unit] : [NSString stringWithFormat:@"%@", unit];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (userLastUpdatedLabel == nil) return;
        
        [UIView transitionWithView:userLastUpdatedLabel duration:kWAUContactUpdateAnimationDuration options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState) animations:^
         {
             [userLastUpdatedLabel setText:lastUpdatedDescription];
         } completion:nil];
    });
    
    if (nextTimeInterval > 0) [self performSelector:@selector(updateLastUpdatedLabelWithCurrentTime) withObject:nil afterDelay:nextTimeInterval];
}

- (void)zoomToFitMapAnnotations:(MKMapView *)mapView withCurrentLocation:(BOOL)currentLocationTracked
{
    NSMutableArray *mapAnnotation = [[mapView annotations] mutableCopy];
    if (currentLocationTracked && [mapView showsUserLocation]) [mapAnnotation addObject:[mapView userLocation]];
    if ([mapAnnotation count] == 0) return;
    
    CLLocationCoordinate2D topLeftCoord;
    topLeftCoord.latitude = -90.f;
    topLeftCoord.longitude = 180.f;
    
    CLLocationCoordinate2D bottomRightCoord;
    bottomRightCoord.latitude = 90.f;
    bottomRightCoord.longitude = -180.f;
    
    for(id<MKAnnotation> annotation in mapAnnotation) {
        topLeftCoord.longitude = fmin(topLeftCoord.longitude, annotation.coordinate.longitude);
        topLeftCoord.latitude = fmax(topLeftCoord.latitude, annotation.coordinate.latitude);
        bottomRightCoord.longitude = fmax(bottomRightCoord.longitude, annotation.coordinate.longitude);
        bottomRightCoord.latitude = fmin(bottomRightCoord.latitude, annotation.coordinate.latitude);
    }
    
    MKCoordinateRegion region;
    region.center.latitude = topLeftCoord.latitude - (topLeftCoord.latitude - bottomRightCoord.latitude) * 0.5f;
    region.center.longitude = topLeftCoord.longitude + (bottomRightCoord.longitude - topLeftCoord.longitude) * 0.5f;
    
    // Add a little extra space on the sides
    region.span.latitudeDelta = fabs(topLeftCoord.latitude - bottomRightCoord.latitude) * 1.2f;
    region.span.longitudeDelta = fabs(bottomRightCoord.longitude - topLeftCoord.longitude) * 1.2f;
    
    region = [mapView regionThatFits:region];
    [mapView setRegion:region animated:YES];
}

- (void)layoutPingStatusView
{
    WAUContactPingStatus pingStatus = [[self contactController] pingStatus];
    
    float pingStatusViewAlpha = 0.f;
    float pingSpinnerAlpha = 0.f;
    float pingSuccessImageViewAlpha = 0.f;
    float pingFailedImageViewAlpha = 0.f;
    
    if (pingStatus == WAUContactPingStatusNotification) pingStatusViewAlpha = 1.f;
    else if (pingStatus == WAUContactPingStatusPinging) pingSpinnerAlpha = 1.f;
    else if (pingStatus == WAUContactPingStatusSuccess) pingSuccessImageViewAlpha = 1.f;
    else if (pingStatus == WAUContactPingStatusFailed) pingFailedImageViewAlpha = 1.f;
    
    if (pingStatusViewAlpha == 1.f && [pingStatusView alpha] == 1.f) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (pingNumberLabel == nil) return;
            
            [UIView transitionWithView:pingNumberLabel duration:kWAUContactUpdateAnimationDuration options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState) animations:^
             {
                 [pingNumberLabel setText:[NSString stringWithFormat:@"%d", MIN([[self contactController] ping], 99)]];
             } completion:nil];
        });
    }
    else {
        [pingNumberLabel setText:[NSString stringWithFormat:@"%d", MIN([[self contactController] ping], 99)]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState) animations:^
             {
                 [pingStatusView setAlpha:pingStatusViewAlpha];
                 [pingSpinner setAlpha:pingSpinnerAlpha];
                 [pingSuccessImageView setAlpha:pingSuccessImageViewAlpha];
                 [pingFailedImageView setAlpha:pingFailedImageViewAlpha];
             } completion:^(BOOL finished)
             {
                 if (pingSpinnerAlpha == 1.f) [pingSpinner startAnimating];
                 else [pingSpinner stopAnimating];
             }];
        });
    }
}

#pragma mark - Delegates
#pragma mark MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[ContactMapAnnotation class]]) {
        ContactMapAnnotation *contactAnnotation = (ContactMapAnnotation *) annotation;
        ContactMapAnnotationView *annotationView = (ContactMapAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"ContactAnnotation"];
        
        if (annotationView == nil) annotationView = [[ContactMapAnnotationView alloc] initWithAnnotation:contactAnnotation];
        else [annotationView setContactMapAnnotation:contactAnnotation];
        
        return annotationView;
    }
    else return nil;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay
{
    if ([overlay isKindOfClass:[MKCircle class]]) {
        MKCircle *accuracyOverlay = (MKCircle *) overlay;
        MKCircleRenderer *accuracyOverlayRanderer = [[MKCircleRenderer alloc] initWithCircle:accuracyOverlay];
        
        UIColor *userColor = [[accuracyOverlay contactController] userColor];
        UIColor *alphaUserColor = [userColor colorWithAlphaComponent:0.5f];
        [accuracyOverlayRanderer setFillColor:alphaUserColor];
        return accuracyOverlayRanderer;
    }
    else return nil;
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation
{
    if (!isMapViewFirstAppeared) return;
    
    [self zoomToFitMapAnnotations:mapView withCurrentLocation:YES];
    isMapViewFirstAppeared = NO;
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error
{
    if ([error code] != kCLErrorDenied) return;
    
    [mapView setShowsUserLocation:NO];
}

#pragma mark ContactControllerDelegate

- (void)contactDidUpdateLocation:(ContactController *)controller
{
    [self layoutPingStatusView];
    
    [self updateLastUpdatedLabelWithCurrentTime];
    [self createAnnotationForContactController:controller];
    
    [self zoomToFitMapAnnotations:contactMapView withCurrentLocation:YES];
}

- (void)contactDidUpdateUsername:(ContactController *)controller
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (usernameLabel == nil) return;
        
        [UIView transitionWithView:usernameLabel duration:kWAUContactUpdateAnimationDuration options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState) animations:^
         {
             [usernameLabel setText:[controller username]];
         } completion:nil];
    });
}

- (void)contactDidUpdateUserIcon:(ContactController *)controller
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState) animations:^
         {
             [userIconImageView setImage:[controller userIcon]];
         } completion:nil];
    });
}

- (void)contactDidUpdateUserColor:(ContactController *)controller
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:(UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState) animations:^
         {
             [[self view] setBackgroundColor:[controller userColor]];
             
             [usernameLabel setTextColor:[controller wordColor]];
             [userLastUpdatedLabel setTextColor:[controller wordColor]];
             [userLastUpdatedDescriptionLabel setTextColor:[controller wordColor]];
             
             [locateButton setTintColor:[[self contactController] wordColor]];
             [deleteButton setTintColor:[[self contactController] wordColor]];
             
             [pingStatusView setBackgroundColor:[[self contactController] wordColor]];
             [pingNumberLabel setTextColor:[[self contactController] userColor]];
             [pingSpinner setColor:[[self contactController] wordColor]];
             [pingSuccessImageView setTintColor:[[self contactController] wordColor]];
             [pingFailedImageView setTintColor:[[self contactController] wordColor]];
         } completion:^(BOOL finished)
         {
             [self createAnnotationForContactController:controller];
         }];
    });
}

- (void)controllerWillSendNotification:(ContactController *)controller
{
    [self layoutPingStatusView];
}

- (void)controller:(ContactController *)controller didSendNotifcation:(BOOL)isSuccess
{
    [self layoutPingStatusView];
}

#pragma mark UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

@end
