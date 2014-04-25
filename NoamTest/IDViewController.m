//
//  IDViewController.m
//  NoamTest
//
//  Created by Timothy Shi on 7/18/13.
//  Copyright (c) 2013 IDEO LLC. All rights reserved.
//



//------------------------------------------------------------------------
// uncomment the following line to enable accelerometer and gyroscope demo
//------------------------------------------------------------------------
//#define SENSOR_DEMO_ENABLED



#import "IDNoamLemma.h"
#import "IDViewController.h"

#import "EchoVerify.h"
#import "SumVerify.h"
#import "PlusOneVerify.h"
#import "NameVerify.h"

#if defined(SENSOR_DEMO_ENABLED)
#import "SensorTest.h"
#endif


#define IS_PRE_IOS7                             ((floor(NSFoundationVersionNumber) <= NSFoundationVersionNumber_iOS_6_1))


static NSString * const kLemmaID = @"iOSLemmaID";
static NSString * const kLemmaEventTypeTouch = @"iOSTouchEvent";
static NSString * const kLemmaEventKeyPos = @"pos";
static NSString * const kLemmaEventKeyTimestamp = @"time";


@interface IDViewController () <IDNoamDelegate>

@property (nonatomic, strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic, strong) UILabel *label;
#if defined(SENSOR_DEMO_ENABLED)
@property (nonatomic, strong) SensorTest *sensorTest;
#endif

@end


@implementation IDViewController


#pragma mark - init


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /* init Lemma */
    IDNoamLemma *lemma = [IDNoamLemma sharedLemmaWithClientName:kLemmaID
                                                     serverName:@"iOS_test_room"
                                                     hearsArray:@[@"EventFromOtherEntity", kLemmaEventTypeTouch, @"Echo", @"Sum", @"PlusOne", @"Name"]
#if defined(SENSOR_DEMO_ENABLED)
                                                     playsArray:@[kLemmaEventTypeTouch, kLemmaEventTypeGyro, kLemmaEventTypeAccelerometer]
#else
                                                     playsArray:@[kLemmaEventTypeTouch]
#endif
                                                       delegate:self];
    [lemma connect];
    
    /* [demo] touch to test */
    self.tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapRecognized:)];
    [self.view addGestureRecognizer:self.tapRecognizer];
    
    /* [demo] message lable to confirm test results */
    self.label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 120/2)];
    [self.view addSubview:self.label];
    self.label.textColor = [UIColor colorWithWhite:0 alpha:1.0];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.numberOfLines = 0;
    self.label.font = [UIFont boldSystemFontOfSize:22/2];
    self.label.hidden = YES;
    
#if defined(SENSOR_DEMO_ENABLED)
    /* [demo] panel displaying accelerometer and gyro data */
    self.sensorTest = [[SensorTest alloc] initWithFrame:CGRectMake(0,
                                                                   IS_PRE_IOS7 ? 0 : [[UIApplication sharedApplication] statusBarFrame].size.height,
                                                                   self.view.bounds.size.width,
                                                                   0)];
    [self.view addSubview:self.sensorTest];
#endif
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
#if defined(SENSOR_DEMO_ENABLED)
    [self.sensorTest startMonitoring];
#endif
}


- (void)viewDidDisappear:(BOOL)animated
{
#if defined(SENSOR_DEMO_ENABLED)
    [self.sensorTest stopMonitoring];
#endif
    
    [super viewDidDisappear:animated];
}


#pragma mark - IDNoamDelegate example


- (void)noamLemmaDidConnectToNoamServer:(IDNoamLemma *)lemma {
    self.label.hidden = NO;
    self.label.center = self.view.center;
    self.label.text = [NSString stringWithFormat:@"connected to NOAM on: %@", [NSDate date]];
#if defined(SENSOR_DEMO_ENABLED)
    [self.sensorTest startSendingData];
#endif
}


- (void)noamLemma:(IDNoamLemma *)lemma connectionDidCloseWithReason:(NSString *)reason
{
#if defined(SENSOR_DEMO_ENABLED)
    [self.sensorTest stopSendingData];
#endif
}


- (void)noamLemma:(IDNoamLemma *)lemma didReceiveData:(id)data fromLemma:(NSString *)fromLemma forEvent:(NSString *)event {
    /* [demo] display touch position sent to NOAM server and passed back */
    if ([data isKindOfClass:[NSDictionary class]] &&
        [event isEqualToString:kLemmaEventTypeTouch] &&
        data[kLemmaEventKeyPos]) {
        CGPoint pos = CGPointMake([data[kLemmaEventKeyPos][0] floatValue], [data[kLemmaEventKeyPos][1] floatValue]);
        self.label.center = pos;
        self.label.text = [NSString stringWithFormat:@"x: %.0f, y: %.0f\n"
                           "t: %@",
                           pos.x,
                           pos.y,
                           data[kLemmaEventKeyTimestamp]];
        self.label.hidden = NO;
        [self.view setNeedsDisplay];
    }
    else if ([event isEqualToString: @"Echo"]) {
        [lemma sendData: [EchoVerify responseFor:data] forEventName: @"EchoVerify"];
    }
    else if ([event isEqualToString: @"Sum"]) {
        [lemma sendData: [SumVerify responseFor:data] forEventName: @"SumVerify"];
    }
    else if ([event isEqualToString: @"PlusOne"]) {
        [lemma sendData:[PlusOneVerify responseFor:data] forEventName:@"PlusOneVerify"];
    }
    else if ([event isEqualToString: @"Name"]) {
        [lemma sendData:[NameVerify responseFor:data] forEventName:@"NameVerify"];
    }
    else {
        self.label.center = self.view.center;
        self.label.text = [NSString stringWithFormat:@"RECEIVED: %@", data];
        self.label.hidden = NO;
        [self.view setNeedsDisplay];
    }
}


#pragma mark - demo


- (void)tapRecognized:(UITapGestureRecognizer *)recognizer {
    self.label.hidden = YES;
    [self.view setNeedsDisplay];
    CGPoint pos = [recognizer locationInView:self.view];
    /* NSJSONSerialization is used to encode data, which requires:
     * 1. The top level object is an NSArray or NSDictionary.
     * 2. All objects are instances of NSString, NSNumber, NSArray, NSDictionary, or NSNull.
     * 3. All dictionary keys are instances of NSString.
     * 4. Numbers are not NaN or infinity.
     */
    [[IDNoamLemma sharedLemma] sendData:@{
                                          kLemmaEventKeyTimestamp : [[NSDate date] description],
                                          kLemmaEventKeyPos : @[@(pos.x), @(pos.y)]
                                          }
                           forEventName:kLemmaEventTypeTouch];
}


@end
