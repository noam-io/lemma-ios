//
//  IDViewController.m
//  NoamTest
//
//  Created by Timothy Shi on 7/18/13.
//  Copyright (c) 2013 IDEO LLC. All rights reserved.
//

#import "IDViewController.h"

#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import <CocoaAsyncSocket/GCDAsyncSocket.h>

@interface IDViewController () <GCDAsyncUdpSocketDelegate, GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic, strong) GCDAsyncSocket *tcpSocket;
@property (nonatomic) dispatch_queue_t delegateQueue;

@end

@implementation IDViewController

static const uint16_t kNoamUDPBroadcastPort = 1030;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegateQueue = dispatch_queue_create("com.ideo.noam.socket-delegate-queue", DISPATCH_QUEUE_SERIAL);
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:self.delegateQueue];
    [self.udpSocket bindToPort:kNoamUDPBroadcastPort error:nil];
    [self.udpSocket beginReceiving:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)createTCPSocketWithHost:(NSString *)hostAddress andPort:(uint16_t)hostPort {
    self.tcpSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:self.delegateQueue];
    NSError *error;
//    [self.tcpSocket acceptOnPort:0 error:&error];
    [self.tcpSocket connectToHost:hostAddress onPort:hostPort error:&error];
}

- (void)sendRegistrationMessage {
    NSArray *registrationMessage = @[@"register", @"iosClient", @([self.tcpSocket localPort]), @[@"event1"], @[@"event1"], @"objective-c", @"0.1"];
    NSData *sendData = [NSJSONSerialization dataWithJSONObject:registrationMessage options:0 error:nil];
    NSString *dataString = [[NSString alloc] initWithData:sendData encoding:NSUTF8StringEncoding];
    NSString *lengthString = [NSString stringWithFormat:@"%06d", sendData.length];
    NSString *sendString = [lengthString stringByAppendingString:dataString];
    sendData = [sendString dataUsingEncoding:NSUTF8StringEncoding];
    [self.tcpSocket writeData:sendData withTimeout:1000 tag:1];
    [self.tcpSocket readDataWithTimeout:15 tag:0];
}

#pragma mark - GCDAsyncUdpSocketDelegate Methods

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address {
    NSLog(@"connected to address: %@", address);
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error {
    
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error {
    
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@", message);
    NSScanner *scanner = [NSScanner scannerWithString:message];
    [scanner setCharactersToBeSkipped:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
    int connectionPort = -1;
    [scanner scanInt:&connectionPort];
    NSString *hostAddr = [GCDAsyncUdpSocket hostFromAddress:address];
    if (!hostAddr || connectionPort < 0) {
        return;
    }
    if (!self.tcpSocket && ![self.tcpSocket isConnected]) {
        [self createTCPSocketWithHost:hostAddr andPort:connectionPort];
    }
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    
}

-(void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    
}

#pragma mark - GCDAsyncSocketDelegate Methods

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"connected to host: %@", host);
    [self sendRegistrationMessage];
    [self sendRegistrationMessage];
}

-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    
}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"did read data: %@", data);
}

@end
