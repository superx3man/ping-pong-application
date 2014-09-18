//
//  IDCardViewController.m
//  WheArU
//
//  Created by Calvin Ng on 9/14/14.
//  Copyright (c) 2014 Hok Man Ng. All rights reserved.
//

#import "IDCardViewController.h"

#import "UserController.h"


float const kWAUUserQRCodeWidth = 250.f;

@interface IDCardViewController ()

@end

@implementation IDCardViewController
{
    IBOutlet UILabel *scanInstructionLabel;
    IBOutlet UIImageView *qrCodeImageView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[self view] setBackgroundColor:[[UserController sharedInstance] userColor]];
    [scanInstructionLabel setTextColor:[[UserController sharedInstance] wordColor]];
    
    [qrCodeImageView setAlpha:0.f];
}

- (void)viewDidAppear:(BOOL)animated
{
    [qrCodeImageView setImage:[self generateUserQRCode]];
    
    [UILabel beginAnimations:NULL context:nil];
    [UILabel setAnimationDuration:1.f];
    [qrCodeImageView setAlpha:1.f];
    [UILabel commitAnimations];
}

#pragma mark - Functions
#pragma mark Support

- (UIImage *)generateUserQRCode
{
    CIFilter *qrCodeFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    [qrCodeFilter setDefaults];
    
    NSData *userInfoData = [[[UserController sharedInstance] QRCodeDescription] dataUsingEncoding:NSUTF8StringEncoding];
    [qrCodeFilter setValue:userInfoData forKey:@"inputMessage"];
    [qrCodeFilter setValue:@"L" forKey:@"inputCorrectionLevel"];
    CIImage *qrCodeImage = [qrCodeFilter valueForKey:@"outputImage"];
    
    //CIColor *foregroundColor = [CIColor colorWithCGColor:[[[UserController sharedInstance] wordColor] CGColor]];
    //CIColor *backgroundColor = [CIColor colorWithCGColor:[[[UserController sharedInstance] userColor] CGColor]];
    CIColor *foregroundColor = [CIColor colorWithCGColor:[[UIColor blackColor] CGColor]];
    CIColor *backgroundColor = [CIColor colorWithCGColor:[[UIColor whiteColor] CGColor]];
    CIFilter *colorFilter = [CIFilter filterWithName:@"CIFalseColor" keysAndValues:@"inputImage", qrCodeImage, @"inputColor0", foregroundColor, @"inputColor1", backgroundColor, nil];
    CIImage *colorFilteredImage = [colorFilter valueForKey:@"outputImage"];
    
    CGRect imageExtent = CGRectIntegral([colorFilteredImage extent]);
    CGFloat imageScale = MIN(kWAUUserQRCodeWidth / CGRectGetWidth(imageExtent), kWAUUserQRCodeWidth / CGRectGetHeight(imageExtent));
    
    size_t width = CGRectGetWidth(imageExtent) * imageScale;
    size_t height = CGRectGetHeight(imageExtent) * imageScale;
    CGColorSpaceRef cs = CGColorSpaceCreateDeviceRGB();
    CGContextRef bitmapRef = CGBitmapContextCreate(nil, width, height, 8, 256 * 4, cs, (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);
    CIContext *context = [CIContext contextWithOptions:nil];
    
    CGImageRef bitmapImage = [context createCGImage:colorFilteredImage fromRect:imageExtent];
    
    CGContextSetInterpolationQuality(bitmapRef, kCGInterpolationNone);
    CGContextScaleCTM(bitmapRef, imageScale, imageScale);
    CGContextDrawImage(bitmapRef, imageExtent, bitmapImage);
    
    CGImageRef scaledImage = CGBitmapContextCreateImage(bitmapRef);
    
    // Cleanup
    CGContextRelease(bitmapRef);
    CGImageRelease(bitmapImage);
    
    return [[UIImage alloc] initWithCGImage:scaledImage];
}

#pragma mark - Controls
#pragma mark Tap

- (IBAction)userDidTapOnView:(id)sender
{
    [[self navigationController] popViewControllerAnimated:YES];
}

@end
