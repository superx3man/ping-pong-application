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
    
    IBOutlet UIImageView *currentPictureImageView;
    IBOutlet UIView *cameraView;
    
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
    
    [[self view] setBackgroundColor:[[self userController] userColor]];
    [questionLabel setTextColor:[[self userController] wordColor]];
    [submitButton setTitleColor:[[self userController] wordColor] forState:UIControlStateNormal];
    [submitButton setTitleColor:[[self userController] wordColor] forState:UIControlStateHighlighted];
    [submitButton setTitleColor:[[self userController] wordColor] forState:UIControlStateSelected];
    
    [[currentPictureImageView layer] setBorderColor:[[[self userController] wordColor] CGColor]];
    [[currentPictureImageView layer] setBorderWidth:0.5f];
    
    if ([[self userController] userIcon] != nil) [currentPictureImageView setImage:[[self userController] userIcon]];
    
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

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
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

- (IBAction)didTapOnImageView:(id)sender
{
    if (currentState == WAUUpdateUserIconStateInitial && (backCameraDevice != nil || frontCameraDevice != nil)) {
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
        if (imageModified) [[self userController] setUserIcon:[currentPictureImageView image]];
        
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
                     imageOrientation = UIImageOrientationDown;
                     break;
                 case AVCaptureVideoOrientationLandscapeLeft:
                     imageOrientation = UIImageOrientationUp;
                     break;
             }
             UIImage *rotatedImage = [[UIImage alloc] initWithCGImage:[capturedImage CGImage] scale:1.0f orientation:imageOrientation];
             [currentPictureImageView setImage:rotatedImage];
             
             [captureSession stopRunning];
             for (AVCaptureInput *oldInput in [captureSession inputs]) {
                 [captureSession removeInput:oldInput];
             }
             [cameraView setHidden:YES];
             
             NSString *newButtonTitle = @"I look awesome now!";
             [submitButton setTitle:newButtonTitle forState:UIControlStateNormal];
             [submitButton setTitle:newButtonTitle forState:UIControlStateHighlighted];
             [submitButton setTitle:newButtonTitle forState:UIControlStateSelected];
             
             imageModified = YES;
             currentState = WAUUpdateUserIconStateInitial;
         }];
    }
}

@end
