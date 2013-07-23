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

@interface IDViewController () <GCDAsyncUdpSocketDelegate, SRWebSocketDelegate, IDNoamDelegate>

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) SRWebSocket *websocket;
@property (nonatomic, strong) IDNoamLemma *lemma;

@end

@implementation IDViewController

static const uint16_t kNoamUDPBroadcastPort = 1033;
static const NSInteger kNoamWebsocketsPort = 8089;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.lemma = [IDNoamLemma sharedLemmaWithClientName:@"ios" hearsArray:@[@"test"] playsArray:@[@"test"]];
    self.lemma.delegate = self;
    [self.lemma connectToNoam];
}

- (void)noamLemma:(IDNoamLemma *)lemma didReceiveData:(id)data fromLemma:(NSString *)fromLemma forEvent:(NSString *)event {
    
}

@end
