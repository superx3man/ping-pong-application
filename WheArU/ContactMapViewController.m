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

#import "MKCircle+ContactController.h"
#import "MKMapView+SharedInstance.h"
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
    
    NSMutableDictionary *annotationDictionary;
    BOOL isMapViewFirstAppeared;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    UIBezierPath *circularPath=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, [userIconImageView frame].size.width, [userIconImageView frame].size.height) cornerRadius:MAX([userIconImageView frame].size.width, [userIconImageView frame].size.height)];
    [circle setPath:[circularPath CGPath]];
    [[userIconImageView layer] setMask:circle];
    
    annotationDictionary = [[NSMutableDictionary alloc] init];
    isMapViewFirstAppeared = YES;
    
    contactMapView = [MKMapView sharedInstance];
    [contactMapView setTranslatesAutoresizingMaskIntoConstraints:NO];
    [mapContainerView addSubview:contactMapView];
    [mapContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[contactMapView]|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(contactMapView)]];
    [mapContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[contactMapView]|" options:kNilOptions metrics:nil views:NSDictionaryOfVariableBindings(contactMapView)]];
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
    
    if ([[self contactController] userIcon] != nil) [userIconImageView setImage:[[self contactController] userIcon]];
    
    [self createAnnotationForContactController:[self contactController]];
    [self zoomToFitMapAnnotations:contactMapView withCurrentLocation:NO];
    
    [contactMapView setShowsUserLocation:YES];
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

#pragma mark - Controls

- (IBAction)tapOnSideSpace:(id)sender
{
    [[self navigationController] popViewControllerAnimated:YES];
}

#pragma mark - Functions
#pragma mark Support

- (void)createAnnotationForContactController:(ContactController *)contactController
{
    NSArray *annotationInfo = [annotationDictionary objectForKey:[contactController userId]];
    if (annotationInfo != nil) {
        [contactMapView removeAnnotation:[annotationInfo objectAtIndex:0]];
        [contactMapView removeOverlay:[annotationInfo objectAtIndex:1]];
    }
    
    ContactMapAnnotation *contactAnnotation = [[ContactMapAnnotation alloc] initWithContactController:contactController];
    [contactMapView addAnnotation:contactAnnotation];
    MKCircle *accuracyOverlay = [contactAnnotation accuracyOverlay];
    [contactMapView addOverlay:accuracyOverlay];
    [annotationDictionary setObject:[NSArray arrayWithObjects:contactAnnotation, accuracyOverlay, nil] forKey:[contactController userId]];
}

- (void)updateLastUpdatedLabelWithCurrentTime
{
    if ([self contactController] == nil) return;
    
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
    
    [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:UIViewAnimationOptionTransitionCrossDissolve animations:^
     {
         [userLastUpdatedLabel setText:lastUpdatedDescription];
     } completion:nil];
    
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
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updateLastUpdatedLabelWithCurrentTime) object:nil];
    [self updateLastUpdatedLabelWithCurrentTime];
    [self createAnnotationForContactController:controller];
    
    [self zoomToFitMapAnnotations:contactMapView withCurrentLocation:YES];
}

- (void)contactDidUpdateUsername:(ContactController *)controller
{
    [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:UIViewAnimationOptionTransitionCrossDissolve animations:^
     {
         [usernameLabel setText:[controller username]];
     } completion:nil];
}

- (void)contactDidUpdateUserIcon:(ContactController *)controller
{
    [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:UIViewAnimationOptionTransitionCrossDissolve animations:^
     {
         [userIconImageView setImage:[controller userIcon]];
     } completion:nil];
}

- (void)contactDidUpdateUserColor:(ContactController *)controller
{
    [UIView animateWithDuration:kWAUContactUpdateAnimationDuration delay:0.f options:UIViewAnimationOptionTransitionCrossDissolve animations:^
     {
         [[self view] setBackgroundColor:[controller userColor]];
         
         [usernameLabel setTextColor:[controller wordColor]];
         [userLastUpdatedLabel setTextColor:[controller wordColor]];
         [userLastUpdatedDescriptionLabel setTextColor:[controller wordColor]];
     } completion:nil];
}

@end
