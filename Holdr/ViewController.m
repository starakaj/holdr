//
//  ViewController.m
//  Holdr
//
//  Created by Sam Tarakajian on 15/11/2014.
//  Copyright (c) 2014 Useless Shit. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
	NSTimer *_startHoldingTimer;
	NSTimer *_stopHoldingTimer;
	BOOL _isHolding;

	AVSpeechUtterance *_holdingUtterance;
	AVSpeechUtterance *_unholdingUtterance;
	AVSpeechSynthesizer *_speechSynth;
}

@end

@implementation ViewController

- (void)viewDidLoad {
	[super viewDidLoad];

	_holdingUtterance = [AVSpeechUtterance
						 speechUtteranceWithString:@"You are now holding your phone"];
	_holdingUtterance.pitchMultiplier = 1.0;
	_holdingUtterance.rate = 0.2;
	_unholdingUtterance = [AVSpeechUtterance
						   speechUtteranceWithString:@"You are no longer holding your phone"];
	_unholdingUtterance.pitchMultiplier = 1.0;
	_unholdingUtterance.rate = 0.2;
	_speechSynth = [[AVSpeechSynthesizer alloc] init];


	self.motionManager = [[CMMotionManager alloc] init];
	self.motionManager.deviceMotionUpdateInterval = 0.02;

	[self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
											withHandler:^(CMDeviceMotion *motion, NSError *error) {
												[self handleDeviceMotion:motion error:error];
											}];

	NSLog(@"Loaded");
}

- (void) handleDeviceMotion:(CMDeviceMotion *)motion error:(NSError *)error
{
	double totalMotion = fabs(motion.userAcceleration.x) + fabs(motion.userAcceleration.y) + fabs(motion.userAcceleration.z);
	printf("%f\n", totalMotion);

	if (_isHolding) {
		if (totalMotion > 0.025) {
			if (_stopHoldingTimer) {
				[_stopHoldingTimer invalidate];
				_stopHoldingTimer = nil;
			}
		} else {
			if (!_stopHoldingTimer) {
				_stopHoldingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(stopHolding) userInfo:nil repeats:NO];
			}
		}
	}

	else {
		if (totalMotion > 0.1) {
			if (!_startHoldingTimer) {
				_startHoldingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(startHolding) userInfo:nil repeats:NO];
			}
		}
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void) startHolding
{
	if (!_isHolding) {
		_isHolding = YES;
		self.holdingLabel.text = @"Holding";
		self.view.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.8];
		[_speechSynth speakUtterance:_holdingUtterance];
	}
}

- (void) stopHolding
{
	if (_isHolding) {
		if (_startHoldingTimer) {
			[_startHoldingTimer invalidate];
			_startHoldingTimer = nil;
		}
		_isHolding = NO;
		self.holdingLabel.text = @"Not Holding";
		self.view.backgroundColor = [UIColor whiteColor];

		[_speechSynth speakUtterance:_unholdingUtterance];
	}
}

- (void) playHolding:(id)sender
{
	[_speechSynth speakUtterance:_holdingUtterance];
}

- (void) playNotHolding:(id)sender
{
	[_speechSynth speakUtterance:_unholdingUtterance];
}

@end
