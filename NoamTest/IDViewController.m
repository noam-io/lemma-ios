//
//  IDViewController.m
//  NoamTest
//
//  Created by Timothy Shi on 7/18/13.
//  Copyright (c) 2013 IDEO LLC. All rights reserved.
//

#import "IDViewController.h"

#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import <SocketRocket/SRWebSocket.h>
#import "IDNoamLemma.h"

@interface IDViewController () <IDNoamDelegate>
@end

@implementation IDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    IDNoamLemma *lemma = [IDNoamLemma sharedLemmaWithClientName:@"ios"
                                                     hearsArray:@[@"timestamp"]
                                                     playsArray:@[@"timestamp"]];
    lemma.delegate = self;
    [lemma connectToNoam];
}

- (void)noamLemmaDidConnectToNoamServer:(IDNoamLemma *)lemma {
    NSLog(@"noamLemmaDidConnectToNoamServer");
    [self sendTimestamp];
}

- (void)noamLemma:(IDNoamLemma *)lemma didReceiveData:(id)data fromLemma:(NSString *)fromLemma forEvent:(NSString *)event {
    NSLog(@"Event: %@\nSender: %@\nData: %@", event, fromLemma, data);
    [self sendTimestamp];
}

- (void)sendTimestamp {
    NSTimeInterval timestamp = [[NSDate date] timeIntervalSince1970];
    [[IDNoamLemma sharedLemma] sendData:@(timestamp) forEventName:@"timestamp"];
}

@end
