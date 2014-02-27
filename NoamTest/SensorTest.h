//
//  SensorTest.h
//  NoamTest
//
//  Created by Mel He on 2/27/14.
//  Copyright (c) 2014 IDEO LLC. All rights reserved.
//

#import <UIKit/UIKit.h>


static NSString * const kLemmaEventTypeGyro = @"GyroValueArray";
static NSString * const kLemmaEventTypeAccelerometer = @"AccelerometerArray";


@interface SensorTest : UIView

- (void)startMonitoring;
- (void)stopMonitoring;
- (void)startSendingData;
- (void)stopSendingData;

@end
