//
//  AddContactWithQRCodeViewController.m
//  WheArU
//
//  Created by Calvin Ng on 9/14/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "AddContactWithQRCodeViewController.h"

#import "IDCardViewController.h"

#import "ContactListController.h"
#import "UserController.h"


@interface AddContactWithQRCodeViewController ()

@end

@implementation AddContactWithQRCodeViewController
{
    IBOutlet UIView *cameraView;
    
    IBOutlet UILabel *instructionLabel;
    
    IBOutlet UIButton *showMineButton;
    IBOutlet UIButton *backButton;
    
    AVCaptureSession *captureSession;
    AVCaptureVideoPreviewLayer *cameraPreviewLayer;
    
    ContactListController *contactListController;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    contactListController = [ContactListController sharedInstance];
    
    [[self view] setBackgroundColor:[[UserController sharedInstance] userColor]];
    [instructionLabel setTextColor:[[UserController sharedInstance] wordColor]];
    
    [showMineButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateNormal];
    [showMineButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateHighlighted];
    [showMineButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateSelected];
    [backButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateNormal];
    [backButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateHighlighted];
    [backButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateSelected];
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:nil];
    
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession addInput:deviceInput];
    
    cameraPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    [cameraPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [cameraPreviewLayer setFrame:[cameraView bounds]];
    [[cameraView layer] addSublayer:cameraPreviewLayer];
    
    AVCaptureMetadataOutput *captureOutput = [[AVCaptureMetadataOutput alloc] init];
    [captureOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [captureSession addOutput:captureOutput];
    
    if ([[captureOutput availableMetadataObjectTypes] containsObject:AVMetadataObjectTypeQRCode]) {
        [captureOutput setMetadataObjectTypes:[NSArray arrayWithObjects:AVMetadataObjectTypeQRCode, nil]];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self setCameraOrientation];
    [captureSession startRunning];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [captureSession stopRunning];
    
    [super viewWillDisappear:animated];
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context)
     {
         [self setCameraOrientation];
     } completion:nil];
}

#pragma mark - Functions
#pragma mark Support

- (AVCaptureVideoOrientation)setCameraOrientation
{
    AVCaptureVideoOrientation videoOrientation;
    AVCaptureConnection *previewLayerConnection = [cameraPreviewLayer connection];
    if ([previewLayerConnection isVideoOrientationSupported]) {
        UIInterfaceOrientation currentOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        switch (currentOrientation) {
            case UIInterfaceOrientationPortrait:
                videoOrientation = AVCaptureVideoOrientationPortrait;
                break;
            case UIInterfaceOrientationPortraitUpsideDown:
                videoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
                break;
            case UIInterfaceOrientationLandscapeLeft:
                videoOrientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
            case UIInterfaceOrientationLandscapeRight:
                videoOrientation = AVCaptureVideoOrientationLandscapeRight;
                break;
            default:
                videoOrientation = AVCaptureVideoOrientationPortrait;
                break;
        }
        [previewLayerConnection setVideoOrientation:videoOrientation];
    }
    return videoOrientation;
}

#pragma mark - Controls
#pragma mark Tap

- (IBAction)didTapOnBackButton:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Delegates
#pragma mark AVCaptureMetadataOutputObjectsDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if ([metadataObjects count] == 0) return;
    
    [captureSession stopRunning];
    
    AVMetadataMachineReadableCodeObject *metadata = (AVMetadataMachineReadableCodeObject *) [metadataObjects firstObject];
    id newContactController = [contactListController createContactWithJSONDescription:[metadata stringValue]];
    
    if (newContactController == nil) [captureSession startRunning];
    else [self dismissViewControllerAnimated:YES completion:nil];
}

@end
