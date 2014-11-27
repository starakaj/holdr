//
//  ViewController.h
//  Holdr
//
//  Created by Sam Tarakajian on 15/11/2014.
//  Copyright (c) 2014 Useless Shit. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController : UIViewController

@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) IBOutlet UILabel *holdingLabel;

- (IBAction)playHolding:(id)sender;
- (IBAction)playNotHolding:(id)sender;

@end