//
//  ViewController.m
//  Holdr
//
//  Created by Sam Tarakajian on 15/11/2014.
//  Copyright (c) 2014 Useless Shit. All rights reserved.
//

#import "ViewController.h"

#define Holdr_DROP_ACCEL_THRESHOLD		0.09
#define Holdr_MINIMUM_DROP_TIME			0.1
#define Holdr_STILLNESS_THRESHOLD		0.025
#define Holdr_BUMP_THRESHOLD			0.1

typedef enum {
	HoldrPhoneState_NotHolding,
	HoldrPhoneState_Holding,
	HoldrPhoneState_Unknown,
	HoldrPhoneState_Dropping
} HoldrPhoneState_t;

@interface ViewController () {
	NSTimer *_startHoldingTimer;
	NSTimer *_stopHoldingTimer;
	NSTimer *_droppingTimer;
	HoldrPhoneState_t _phoneState;

	AVSpeechUtterance *_holdingUtterance;
	AVSpeechUtterance *_unholdingUtterance;
	AVSpeechUtterance *_droppingUtterance;
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
	_droppingUtterance = [AVSpeechUtterance
						  speechUtteranceWithString:@"You are now dropping your phone"];
	_droppingUtterance.pitchMultiplier = 1.0;
	_droppingUtterance.rate = 0.2;
	_speechSynth = [[AVSpeechSynthesizer alloc] init];
	_phoneState = HoldrPhoneState_Unknown;


	self.motionManager = [[CMMotionManager alloc] init];
	self.motionManager.deviceMotionUpdateInterval = 0.01;

	[self.motionManager startDeviceMotionUpdatesToQueue:[NSOperationQueue currentQueue]
											withHandler:^(CMDeviceMotion *motion, NSError *error) {
												[self handleDeviceMotion:motion error:error];
											}];

	[self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue currentQueue]
											 withHandler:^(CMAccelerometerData *accel, NSError *error) {
												 [self handleAcceleration:accel error:error];
											 }];
}

- (void) handleAcceleration:(CMAccelerometerData *)accel error:(NSError *)error
{
	double totalAcceleration = fabs(accel.acceleration.x) + fabs(accel.acceleration.y) + fabs(accel.acceleration.z);
	if (totalAcceleration < Holdr_DROP_ACCEL_THRESHOLD) {
		if (!_droppingTimer) {
			NSLog(@"Very low total acceleration. Drop detected? Starting drop timer");
			_droppingTimer = [NSTimer scheduledTimerWithTimeInterval:Holdr_MINIMUM_DROP_TIME target:self selector:@selector(startDropping) userInfo:nil repeats:NO];
		}
	} else {
		if (_droppingTimer) {
			NSLog(@"Thought we were dropping, but acceleration got too big. Invalidating Drop timer.");
			[_droppingTimer invalidate];
			_droppingTimer = nil;
		}
		if (_phoneState == HoldrPhoneState_Dropping) {
			_phoneState = HoldrPhoneState_Unknown;
		}
	}
}

- (void) handleDeviceMotion:(CMDeviceMotion *)motion error:(NSError *)error
{
	double totalMotion = fabs(motion.userAcceleration.x) + fabs(motion.userAcceleration.y) + fabs(motion.userAcceleration.z);

	// If you're about to enter the not holding state, but there's some motion, then nevermind
	if (_stopHoldingTimer) {
		if (totalMotion > Holdr_STILLNESS_THRESHOLD) {
			NSLog(@"It looked like the phone was still, but then it got a jostle. Invalidating Not Hold timer");
			[_stopHoldingTimer invalidate];
			_stopHoldingTimer = nil;
		}
	}

	// If the phone's not getting any user acceleration, then maybe it's not being held?
	if (!_stopHoldingTimer) {
		if (_phoneState != HoldrPhoneState_NotHolding) {
			if (totalMotion <= Holdr_STILLNESS_THRESHOLD) {
				NSLog(@"Phone is very still. Probably it's not being held. Starting Not Hold timer");
				_stopHoldingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(stopHolding) userInfo:nil repeats:NO];
			}
		}
	}

	// If the phone has a very small user acceleration, then you're almost definitely not holding it
	if (totalMotion <= Holdr_STILLNESS_THRESHOLD) {
		if (_startHoldingTimer) {
			NSLog(@"Had a bump but then went still. Invalidating Hold");
			[_startHoldingTimer invalidate];
			_startHoldingTimer = nil;
		}
	}

	// If the phone is not being held and it gets a bump, then maybe you're holding it now
	if (_phoneState == HoldrPhoneState_NotHolding) {
		if (!_startHoldingTimer) {
			if (totalMotion > 0.1) {
				NSLog(@"Phone got a bump. Maybe it's being held now? Starting Hold timer");
				_startHoldingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(startHolding) userInfo:nil repeats:NO];
			}
		}
	}

	// If the phone is in an unknown state, then simply some motion is enough to suggest that we're being held
	if (_phoneState == HoldrPhoneState_Unknown) {
		if (!_startHoldingTimer) {
			if (totalMotion > Holdr_STILLNESS_THRESHOLD) {
				NSLog(@"Phone seems to be moving a bit. Starting Hold timer");
				_startHoldingTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(startHolding) userInfo:nil repeats:NO];
			}
		}
	}
}

- (void) startDropping
{
	if (_phoneState != HoldrPhoneState_Dropping) {
		[_startHoldingTimer invalidate];
		_startHoldingTimer = nil;
		[_stopHoldingTimer invalidate];
		_stopHoldingTimer = nil;
		_phoneState = HoldrPhoneState_Dropping;
		self.holdingLabel.text = @"Dropping";
		self.view.backgroundColor = [[UIColor redColor] colorWithAlphaComponent:0.8];
		[_speechSynth speakUtterance:_droppingUtterance];
	}
}

- (void) startHolding
{
	if (_phoneState == HoldrPhoneState_Dropping)
		return;
	if (_phoneState != HoldrPhoneState_Holding ) {
		_phoneState = HoldrPhoneState_Holding;
		self.holdingLabel.text = @"Holding";
		self.view.backgroundColor = [[UIColor greenColor] colorWithAlphaComponent:0.8];
		[_speechSynth speakUtterance:_holdingUtterance];
	}
	_startHoldingTimer = nil;
}

- (void) stopHolding
{
	if (_phoneState == HoldrPhoneState_Dropping)
		return;
	if (_phoneState != HoldrPhoneState_NotHolding) {
		_phoneState = HoldrPhoneState_NotHolding;
		self.holdingLabel.text = @"Not Holding";
		self.view.backgroundColor = [UIColor whiteColor];
		[_speechSynth speakUtterance:_unholdingUtterance];
	}
	_stopHoldingTimer = nil;
}

@end
