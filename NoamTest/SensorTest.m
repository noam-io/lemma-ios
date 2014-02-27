//
//  SensorTest.m
//  NoamTest
//
//  Created by Mel He on 2/27/14.
//  Copyright (c) 2014 IDEO LLC. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
#import "IDNoamLemma.h"
#import "SensorTest.h"
#import "GMeterView.h"


#pragma mark - options


#if TARGET_IPHONE_SIMULATOR
#define SIMULATOR_TEST          (YES)
#else
#define SIMULATOR_TEST          (NO)
#endif


#define FILTER_ON               (1)


#pragma mark - constants


#define METERS_PER_POINT        (2.0)
#define DATA_PANEL_H_PT         (160/2)
#define METER_PANEL_COLOUR      COLOUR_GRAYSCALE_A(255, 0.2)
#define METER_BAR_COLOUR        COLOUR_GRAYSCALE_A(255, 0.6)
#define METER_CAP_COLOUR        COLOUR_RGB_A(255, 153, 0, 1.0)
#define METER_CAP_ALPHA         (0.75)
#define SAMPLE_PER_SEC          (10.0f)
#define MPS_TO_MPH_FACTOR       ((1/1609.34f)/(1/3600.0f))
#define RPS_TO_DPS_FACTOR       (180.0f/M_PI)
#define RAD_TO_DEG_FACTOR       (180.0f/M_PI)
#define ACC_BAR_RANGE_G         (1.0)
#define GYRO_BAR_RANGE_DPS      (90.0)


@interface SensorTest () <CLLocationManagerDelegate>

@property (nonatomic, assign) BOOL sendData;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, strong) UILabel *speed;
@property (nonatomic, strong) UILabel *acceleration;
@property (nonatomic, assign) CGFloat MaxAccelerationX;
@property (nonatomic, assign) CGFloat MaxAccelerationY;
@property (nonatomic, assign) CGFloat MaxAccelerationZ;
@property (nonatomic, assign) CGFloat MaxAccelerationTotal;
@property (nonatomic, strong) GMeterView *gMeter;
@property (nonatomic, strong) GMeterView *gMeterX;
@property (nonatomic, strong) GMeterView *gMeterY;
@property (nonatomic, strong) GMeterView *gMeterZ;
@property (nonatomic, strong) UILabel *gyro;
@property (nonatomic, strong) GMeterView *rMeterX;
@property (nonatomic, strong) GMeterView *rMeterY;
@property (nonatomic, strong) GMeterView *rMeterZ;
@property (nonatomic, strong) GMeterView *aMeterRow;
@property (nonatomic, strong) GMeterView *aMeterPitch;
@property (nonatomic, strong) GMeterView *aMeterYaw;

@end


@implementation SensorTest


#pragma mark - init


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, DATA_PANEL_H_PT)];
    if (self) {
        
        self.backgroundColor = COLOUR_GRAYSCALE_A(0, 1.0);

        /* overal speed */
        _speed = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 40/2)];
        [self addSubview:_speed];
        _speed.backgroundColor = [UIColor clearColor];
        _speed.textAlignment = NSTextAlignmentLeft;
        _speed.textColor = COLOUR_GRAYSCALE_A(255, 1.0);
        _speed.font = [UIFont fontWithName:@"Courier-Bold" size:24/2];
        
        /* multi-line text display for accelerometer data */
        _acceleration = [[UILabel alloc] initWithFrame:CGRectMake(0,
                                                                  _speed.frame.origin.y+_speed.frame.size.height,
                                                                  self.frame.size.width/2,
                                                                  self.frame.size.height-_speed.frame.size.height)];
        [self addSubview:_acceleration];
        _acceleration.backgroundColor = [UIColor clearColor];
        _acceleration.textAlignment = NSTextAlignmentLeft;
        _acceleration.textColor = COLOUR_GRAYSCALE_A(255, 1.0);
        _acceleration.font = [UIFont fontWithName:@"Courier-Bold" size:24/2];
        _acceleration.numberOfLines = 4;
        
        /* main bar graph */
        _gMeter = [[GMeterView alloc] initWithFrame:CGRectMake(0, _acceleration.frame.origin.y-4/2, self.bounds.size.width, 6/2)];
        [self addSubview:_gMeter];
        
        /* bar graph for X-accleleration */
        _gMeterX = [[GMeterView alloc] initWithFrame:CGRectMake(0, _acceleration.frame.origin.y+32/2, self.bounds.size.width/2, 26/2)
                                          panelColor:METER_PANEL_COLOUR
                                            barColor:METER_BAR_COLOUR
                                            capColor:[METER_CAP_COLOUR colorWithAlphaComponent:METER_CAP_ALPHA]
                                               range:ACC_BAR_RANGE_G];
        [self insertSubview:_gMeterX belowSubview:_acceleration];
        
        /* bar graph for Y-accleleration */
        _gMeterY = [[GMeterView alloc] initWithFrame:CGRectMake(0, _acceleration.frame.origin.y+32/2+26/2+1, self.bounds.size.width/2, 26/2)
                                          panelColor:METER_PANEL_COLOUR
                                            barColor:METER_BAR_COLOUR
                                            capColor:[METER_CAP_COLOUR colorWithAlphaComponent:METER_CAP_ALPHA]
                                               range:ACC_BAR_RANGE_G];
        [self insertSubview:_gMeterY belowSubview:_acceleration];
        
        /* bar graph for Z-accleleration */
        _gMeterZ = [[GMeterView alloc] initWithFrame:CGRectMake(0, _acceleration.frame.origin.y+32/2+26/2+26/2+2, self.bounds.size.width/2, 26/2)
                                          panelColor:METER_PANEL_COLOUR
                                            barColor:METER_BAR_COLOUR
                                            capColor:[METER_CAP_COLOUR colorWithAlphaComponent:METER_CAP_ALPHA]
                                               range:ACC_BAR_RANGE_G];
        [self insertSubview:_gMeterZ belowSubview:_acceleration];
        
        /* multi-line text display for gyroscope data */
        _gyro = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/2,
                                                          _acceleration.frame.origin.y,
                                                          self.frame.size.width/2,
                                                          self.frame.size.height-_speed.frame.size.height)];
        [self addSubview:_gyro];
        _gyro.backgroundColor = [UIColor clearColor];
        _gyro.textAlignment = NSTextAlignmentLeft;
        _gyro.textColor = COLOUR_GRAYSCALE_A(255, 1.0);
        _gyro.font = [UIFont fontWithName:@"Courier-Bold" size:24/2];
        _gyro.numberOfLines = 4;
        
        /* bar graph for X-rotation */
        _rMeterX = [[GMeterView alloc] initWithFrame:CGRectMake(self.bounds.size.width/2, _gyro.frame.origin.y+32/2, self.bounds.size.width/2, 26/2)
                                          panelColor:METER_PANEL_COLOUR
                                            barColor:METER_BAR_COLOUR
                                            capColor:[METER_CAP_COLOUR colorWithAlphaComponent:METER_CAP_ALPHA]
                                               range:GYRO_BAR_RANGE_DPS];
        [self insertSubview:_rMeterX belowSubview:_gyro];
        
        /* bar graph for Y-rotation */
        _rMeterY = [[GMeterView alloc] initWithFrame:CGRectMake(self.bounds.size.width/2, _gyro.frame.origin.y+32/2+26/2+1, self.bounds.size.width/2, 26/2)
                                          panelColor:METER_PANEL_COLOUR
                                            barColor:METER_BAR_COLOUR
                                            capColor:[METER_CAP_COLOUR colorWithAlphaComponent:METER_CAP_ALPHA]
                                               range:GYRO_BAR_RANGE_DPS];
        [self insertSubview:_rMeterY belowSubview:_gyro];
        
        /* bar graph for Z-rotation */
        _rMeterZ = [[GMeterView alloc] initWithFrame:CGRectMake(self.bounds.size.width/2, _gyro.frame.origin.y+32/2+26/2+26/2+2, self.bounds.size.width/2, 26/2)
                                          panelColor:METER_PANEL_COLOUR
                                            barColor:METER_BAR_COLOUR
                                            capColor:[METER_CAP_COLOUR colorWithAlphaComponent:METER_CAP_ALPHA]
                                               range:GYRO_BAR_RANGE_DPS];
        [self insertSubview:_rMeterZ belowSubview:_gyro];
        
        /* bar graph for row */
        _aMeterRow = [[GMeterView alloc] initWithFrame:CGRectMake(self.bounds.size.width/2, _rMeterY.frame.origin.y+_rMeterY.frame.size.height,
                                                                  self.bounds.size.width/2, 2/2)
                                            panelColor:[UIColor clearColor]
                                              barColor:[METER_CAP_COLOUR colorWithAlphaComponent:1.0]
                                              capColor:METER_CAP_COLOUR
                                                 range:180.0];
        [self addSubview:_aMeterRow];
        
        /* bar graph for pitch */
        _aMeterPitch = [[GMeterView alloc] initWithFrame:CGRectMake(self.bounds.size.width/2, _rMeterX.frame.origin.y+_rMeterX.frame.size.height,
                                                                    self.bounds.size.width/2, 2/2)
                                              panelColor:[UIColor clearColor]
                                                barColor:[METER_CAP_COLOUR colorWithAlphaComponent:1.0]
                                                capColor:METER_CAP_COLOUR
                                                   range:180.0];
        [self addSubview:_aMeterPitch];
        
        /* bar graph for yaw */
        _aMeterYaw = [[GMeterView alloc] initWithFrame:CGRectMake(self.bounds.size.width/2, _rMeterZ.frame.origin.y+_rMeterZ.frame.size.height,
                                                                  self.bounds.size.width/2, 2/2)
                                            panelColor:[UIColor clearColor]
                                              barColor:[METER_CAP_COLOUR colorWithAlphaComponent:1.0]
                                              capColor:METER_CAP_COLOUR
                                                 range:180.0];
        [self addSubview:_aMeterYaw];
    }
    return self;
}


- (void)setupLocationManager
{
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    _locationManager.distanceFilter = kCLDistanceFilterNone;
}


- (void)setupMotionManager
{
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.deviceMotionUpdateInterval = 1.0f/SAMPLE_PER_SEC;
}


- (void)startMonitoring
{
    if (nil == _locationManager) {
        [self setupLocationManager];
    }
    
    if (nil == _motionManager) {
        [self setupMotionManager];
    }
    
    [self stopMonitoring];
    
    dispatch_time_t delay = dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC * 1.5);
    dispatch_after(delay, dispatch_get_main_queue(), ^(void){
        /* wait for 1.5 sec before (re-)starting sensors */
        NSLog(@"starting GPS, accelerometer, gyroscope ...");
        [_locationManager startUpdatingLocation];
        [_motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical
                                                            toQueue:[NSOperationQueue mainQueue]
                                                        withHandler:^(CMDeviceMotion *motion, NSError *error) {
                                                            if (nil == error) {
                                                                [self updateAccelerometerDisplayWithDeviceMotion:motion];
                                                            }
                                                            else {
                                                                NSLog(@"deviceMotion ERROR: %@", error);
                                                                [_motionManager stopDeviceMotionUpdates];
                                                            }
                                                        }];
    });
}


- (void)stopMonitoring
{
    NSLog(@"stopping GPS, accelerometer, gyroscope ...");
    [_locationManager stopUpdatingLocation];
    [_motionManager stopDeviceMotionUpdates];
}


- (void)updateAccelerometerDisplayWithDeviceMotion:(CMDeviceMotion *)motion
{
    /* accelerometer */
    
    CGFloat accX = [self filteredAccelerationComponentFromComponent:motion.userAcceleration.x];
    CGFloat accY = [self filteredAccelerationComponentFromComponent:motion.userAcceleration.y];
    CGFloat accZ = [self filteredAccelerationComponentFromComponent:motion.userAcceleration.z];
    
    _MaxAccelerationX = fabsf(accX) > fabsf(_MaxAccelerationX) ? accX : _MaxAccelerationX;
    _MaxAccelerationY = fabsf(accY) > fabsf(_MaxAccelerationY) ? accY : _MaxAccelerationY;
    _MaxAccelerationZ = fabsf(accZ) > fabsf(_MaxAccelerationZ) ? accZ : _MaxAccelerationZ;
    CGFloat total = sqrtf(accX*accX + accY*accY + accZ*accZ);
    _MaxAccelerationTotal = MAX(_MaxAccelerationTotal, total);
    
    _acceleration.text = [NSString stringWithFormat:
                          @"acc: % .2f| %.2f G\n"
                          "a X: % .2f|% .2f G\n"
                          "a Y: % .2f|% .2f G\n"
                          "a Z: % .2f|% .2f G",
                          total, _MaxAccelerationTotal,
                          accX, _MaxAccelerationX,
                          accY, _MaxAccelerationY,
                          accZ, _MaxAccelerationZ];
    _gMeter.value = total;
    _gMeterX.value = accX;
    _gMeterY.value = accY;
    _gMeterZ.value = accZ;
    
    if (YES == _sendData) {
        [[IDNoamLemma sharedLemma] sendData:@[@(accX), @(accY), @(accZ)]
                               forEventName:kLemmaEventTypeAccelerometer];
    }
    
    /* gyroscope */
    
    CGFloat rX = RPS_TO_DPS_FACTOR*[self filteredGyroComponentFromComponent:motion.rotationRate.x];
    CGFloat rY = RPS_TO_DPS_FACTOR*[self filteredGyroComponentFromComponent:motion.rotationRate.y];
    CGFloat rZ = RPS_TO_DPS_FACTOR*[self filteredGyroComponentFromComponent:motion.rotationRate.z];
    
    static CGFloat maxRotationRate;
    maxRotationRate = MAX(fabsf(maxRotationRate), fabsf(rX));
    maxRotationRate = MAX(fabsf(maxRotationRate), fabsf(rY));
    maxRotationRate = MAX(fabsf(maxRotationRate), fabsf(rZ));
    
    _gyro.text = [NSString stringWithFormat:
                  @"max RR:  %.0f d/s\n"
                  "gyro X: % .2f\n"
                  "gyro Y: % .2f\n"
                  "gyro Z: % .2f",
                  maxRotationRate,
                  rX, rY, rZ];
    
    _rMeterX.value = rX;
    _rMeterY.value = rY;
    _rMeterZ.value = rZ;
    
    /* attitude */
    static CMAttitude *__referenceAttitude;
    CMAttitude *attitude = motion.attitude;
    
    if (nil == __referenceAttitude) {
        __referenceAttitude = attitude;
    }
    else {
        [attitude multiplyByInverseOfAttitude:__referenceAttitude];
    }
    
    NSInteger roll = (NSInteger)(RAD_TO_DEG_FACTOR*attitude.roll);
    NSInteger pitch = (NSInteger)(RAD_TO_DEG_FACTOR*attitude.pitch);
    NSInteger yaw = (NSInteger)(RAD_TO_DEG_FACTOR*attitude.yaw);
    roll %= 180;
    pitch %= 180;
    yaw %= 180;
    
    _aMeterRow.value = roll;
    _aMeterPitch.value = pitch;
    _aMeterYaw.value = yaw;
    
    if (YES == _sendData) {
        [[IDNoamLemma sharedLemma] sendData:@[@(roll), @(pitch), @(yaw)]
                               forEventName:kLemmaEventTypeGyro];
    }
}


#pragma mark - CLLocationManagerDelegate


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"didFailWithError: %@", error);
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *location = [locations lastObject];
    
    if ((!SIMULATOR_TEST) &&
        (location.horizontalAccuracy < 0 || location.verticalAccuracy < 0)) {
        /* when either value is negative, location data is invalid */
        return;
    }
    
    CGFloat mph = 0.0;
    if (location.speed >= 0) {
        mph = (location.speed)*MPS_TO_MPH_FACTOR;
        _speed.text = [NSString stringWithFormat:@"speed: %.1f m/s (%.1f mph)  H: %.1f  V: %.1f",
                       location.speed, mph, location.horizontalAccuracy, location.verticalAccuracy];
    }
    else {
        _speed.text = [NSString stringWithFormat:@"speed: --.- m/s (--.- mph)  H: %.1f  V: %.1f",
                       location.horizontalAccuracy, location.verticalAccuracy];
    }
}


- (void)startSendingData
{
    _sendData = YES;
}


- (void)stopSendingData
{
    _sendData = NO;
}


#pragma mark - filtering


- (CGFloat)filteredAccelerationComponentFromComponent:(CGFloat)accelerationComponent
{
#if FILTER_ON
    static const CGFloat w_3 = 0.07;
    static const CGFloat w_2 = 0.08;
    static const CGFloat w_1 = 0.15;
    static const CGFloat w_0 = 0.70;
    static CGFloat a_3 = 0.0;
    static CGFloat a_2 = 0.0;
    static CGFloat a_1 = 0.0;
    CGFloat a_0 = accelerationComponent;
    
    CGFloat result = a_0 * w_0 + a_1 * w_1 + a_2 * w_2 + a_3 * w_3;
    
    a_3 = a_2;
    a_2 = a_1;
    a_1 = a_0;
    
    return result;
#else
    return accelerationComponent;
#endif
}


- (CGFloat)filteredGyroComponentFromComponent:(CGFloat)gyroComponent
{
#if FILTER_ON
    static const CGFloat w_3 = 0.04;
    static const CGFloat w_2 = 0.06;
    static const CGFloat w_1 = 0.20;
    static const CGFloat w_0 = 0.70;
    static CGFloat a_3 = 0.0;
    static CGFloat a_2 = 0.0;
    static CGFloat a_1 = 0.0;
    CGFloat a_0 = gyroComponent;
    
    CGFloat result = a_0 * w_0 + a_1 * w_1 + a_2 * w_2 + a_3 * w_3;
    
    a_3 = a_2;
    a_2 = a_1;
    a_1 = a_0;
    
    return result;
#else
    return gyroComponent;
#endif
}


- (CGFloat)deltaFromPreviousYawAngleToCurrentAngle:(CGFloat)currentYaw
{
    static CGFloat previousYaw = 0.0;
    CGFloat delta = currentYaw - previousYaw;
    previousYaw = currentYaw;
    return delta;
}


@end
