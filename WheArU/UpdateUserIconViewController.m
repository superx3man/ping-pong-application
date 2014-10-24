//
//  UpdateUserIconViewController.m
//  WheArU
//
//  Created by Calvin Ng on 9/7/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <ImageIO/CGImageProperties.h>

#import "UpdateUserIconViewController.h"

#import "UserController.h"


float const kWAUUserIconWidth = 200.f;

typedef NS_ENUM(NSInteger, WAUUpdateUserIconState)
{
    WAUUpdateUserIconStateInitial,
    WAUUpdateUserIconStateCapturingVideo,
    WAUUpdateUserIconStateSavingImage
};

@interface UpdateUserIconViewController ()

@end

@implementation UpdateUserIconViewController
{
    IBOutlet UILabel *questionLabel;
    IBOutlet UIButton *submitButton;
    IBOutlet UIButton *modifiedSubmitButton;
    IBOutlet UIButton *modifiedCancelButton;
    
    IBOutlet UIImageView *currentPictureImageView;
    IBOutlet UIView *cameraView;
    
    IBOutlet UILabel *cameraInstructionLabel;
    
    BOOL imageModified;
    WAUUpdateUserIconState currentState;
    
    AVCaptureVideoPreviewLayer *cameraPreviewLayer;
    AVCaptureSession *captureSession;
    
    AVCaptureDeviceInput *frontCameraDevice;
    AVCaptureDeviceInput *backCameraDevice;
    AVCaptureDeviceInput *currentDevice;
    
    AVCaptureStillImageOutput *deviceOutput;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    currentState = WAUUpdateUserIconStateInitial;
    imageModified = NO;
    
    [[self view] setBackgroundColor:[[UserController sharedInstance] userColor]];
    [questionLabel setTextColor:[[UserController sharedInstance] wordColor]];
    [cameraInstructionLabel setTextColor:[[UserController sharedInstance] wordColor]];
    [submitButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateNormal];
    [submitButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateHighlighted];
    [submitButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateSelected];
    
    [modifiedSubmitButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateNormal];
    [modifiedSubmitButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateHighlighted];
    [modifiedSubmitButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateSelected];
    [modifiedCancelButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateNormal];
    [modifiedCancelButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateHighlighted];
    [modifiedCancelButton setTitleColor:[[UserController sharedInstance] wordColor] forState:UIControlStateSelected];
    
    [[currentPictureImageView layer] setBorderColor:[[[UserController sharedInstance] wordColor] CGColor]];
    [[currentPictureImageView layer] setBorderWidth:0.5f];
    
    if ([[UserController sharedInstance] userIcon] != nil) [currentPictureImageView setImage:[[UserController sharedInstance] userIcon]];
    
    for (AVCaptureDevice *videoDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        NSError *error = nil;
        AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
        if (error != nil) continue;
        
        AVCaptureDevicePosition devicePosition = [videoDevice position];
        if (devicePosition == AVCaptureDevicePositionBack) backCameraDevice = deviceInput;
        else if (devicePosition == AVCaptureDevicePositionFront) frontCameraDevice = deviceInput;
        else if (backCameraDevice == nil) backCameraDevice = deviceInput;
    }
    
    captureSession = [[AVCaptureSession alloc] init];
    cameraPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    [cameraPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    [cameraPreviewLayer setFrame:[cameraView bounds]];
    [[cameraView layer] addSublayer:cameraPreviewLayer];
    
    deviceOutput = [[AVCaptureStillImageOutput alloc] init];
    [deviceOutput setOutputSettings:[NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, nil]];
    [captureSession addOutput:deviceOutput];
}

- (void)viewWillAppear:(BOOL)animated
{
    [self setButtonsHiddenForState];
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

- (void)setButtonsHiddenForState
{
    if (!imageModified) {
        [submitButton setHidden:NO];
        [modifiedSubmitButton setHidden:YES];
        [modifiedCancelButton setHidden:YES];
    }
    else {
        [submitButton setHidden:YES];
        [modifiedSubmitButton setHidden:NO];
        [modifiedCancelButton setHidden:NO];
    }
}

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

- (IBAction)didTapOnImageView:(id)sender
{
    if (backCameraDevice == nil && frontCameraDevice == nil) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
    else if (currentState == WAUUpdateUserIconStateInitial) {
        currentState = WAUUpdateUserIconStateCapturingVideo;
        
        [cameraView setHidden:NO];
        NSString *newButtonTitle = @"Snap!";
        [submitButton setTitle:newButtonTitle forState:UIControlStateNormal];
        [submitButton setTitle:newButtonTitle forState:UIControlStateHighlighted];
        [submitButton setTitle:newButtonTitle forState:UIControlStateSelected];
        
        [captureSession stopRunning];
        for (AVCaptureInput *oldInput in [captureSession inputs]) {
            [captureSession removeInput:oldInput];
        }
        if (frontCameraDevice != nil) currentDevice = frontCameraDevice;
        else if (backCameraDevice != nil) currentDevice = backCameraDevice;
        [captureSession addInput:currentDevice];
        
        [self setCameraOrientation];
        [captureSession startRunning];
    }
    else if (currentState == WAUUpdateUserIconStateCapturingVideo) {
        if (frontCameraDevice != nil) {
            [captureSession stopRunning];
            for (AVCaptureInput *oldInput in [captureSession inputs]) {
                [captureSession removeInput:oldInput];
            }
            if (currentDevice == frontCameraDevice) currentDevice = backCameraDevice;
            else currentDevice = frontCameraDevice;
            [captureSession addInput:currentDevice];
            [captureSession startRunning];
        }
    }
}

- (IBAction)didTapOnSubmit:(id)sender
{
    if (currentState == WAUUpdateUserIconStateInitial) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else if (currentState == WAUUpdateUserIconStateCapturingVideo) {
        currentState = WAUUpdateUserIconStateSavingImage;
        
        AVCaptureConnection *videoConnection = nil;
        for (AVCaptureConnection *connection in [deviceOutput connections]) {
            for (AVCaptureInputPort *port in [connection inputPorts]) {
                if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
                    videoConnection = connection;
                    break;
                }
            }
            if (videoConnection) break;
        }
        [deviceOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error)
         {
             AVCaptureVideoOrientation currentCameraOrientation = [self setCameraOrientation];
             UIImage *capturedImage = [[UIImage alloc] initWithData:[AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer]];
             UIImageOrientation imageOrientation = UIImageOrientationUp;
             switch (currentCameraOrientation) {
                 case AVCaptureVideoOrientationPortrait:
                     imageOrientation = UIImageOrientationRight;
                     break;
                 case AVCaptureVideoOrientationPortraitUpsideDown:
                     imageOrientation = UIImageOrientationLeft;
                     break;
                 case AVCaptureVideoOrientationLandscapeRight:
                     imageOrientation = currentDevice == frontCameraDevice ? UIImageOrientationDown : UIImageOrientationUp;
                     break;
                 case AVCaptureVideoOrientationLandscapeLeft:
                     imageOrientation = currentDevice == frontCameraDevice ? UIImageOrientationUp : UIImageOrientationDown;
                     break;
             }
             
             float targetScale = MIN(capturedImage.size.width, capturedImage.size.height) / kWAUUserIconWidth;
             UIImage *rotatedImage = [[UIImage alloc] initWithCGImage:[capturedImage CGImage] scale:targetScale orientation:imageOrientation];
             
             UIGraphicsBeginImageContext(CGSizeMake(kWAUUserIconWidth, kWAUUserIconWidth));
             [rotatedImage drawInRect:CGRectMake(0 - ((rotatedImage.size.width - kWAUUserIconWidth) / 2), 0 - ((rotatedImage.size.height - kWAUUserIconWidth) / 2), rotatedImage.size.width, rotatedImage.size.height)];
             UIImage *croppedIcon = UIGraphicsGetImageFromCurrentImageContext();
             UIGraphicsEndImageContext();
             
             [currentPictureImageView setImage:croppedIcon];
             
             [captureSession stopRunning];
             for (AVCaptureInput *oldInput in [captureSession inputs]) {
                 [captureSession removeInput:oldInput];
             }
             [cameraView setHidden:YES];
             
             imageModified = YES;
             currentState = WAUUpdateUserIconStateInitial;
             [self setButtonsHiddenForState];
         }];
    }
}

- (IBAction)didTapOnModifiedSubmit:(id)sender
{
    [[UserController sharedInstance] setUserIcon:[currentPictureImageView image]];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)didTapOnModifiedCancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
