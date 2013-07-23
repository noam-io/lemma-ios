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

@interface IDViewController () <GCDAsyncUdpSocketDelegate, SRWebSocketDelegate>

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) SRWebSocket *websocket;

@end

@implementation IDViewController

static const uint16_t kNoamUDPBroadcastPort = 1033;
static const NSInteger kNoamWebsocketsPort = 8089;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegateQueue = dispatch_queue_create("com.ideo.noam.delegateQueue", DISPATCH_QUEUE_SERIAL);
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:self.delegateQueue];
    [self.udpSocket bindToPort:kNoamUDPBroadcastPort error:nil];
    [self.udpSocket beginReceiving:nil];
}

- (NSData *)messageDataForMessageArray:(NSArray *)messageArray {
    NSData *sendData = [NSJSONSerialization dataWithJSONObject:messageArray options:0 error:nil];
    NSString *dataString = [[NSString alloc] initWithData:sendData encoding:NSUTF8StringEncoding];
    NSString *lengthString = [NSString stringWithFormat:@"%06d", sendData.length];
    NSString *sendString = [lengthString stringByAppendingString:dataString];
    sendData = [sendString dataUsingEncoding:NSUTF8StringEncoding];
    return sendData;
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
    [sock close];
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@", message);
    NSScanner *scanner = [NSScanner scannerWithString:message];
    [scanner setCharactersToBeSkipped:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
    int connectionPort = -1;
    [scanner scanInt:&connectionPort];
    __block NSString *hostAddr = [GCDAsyncUdpSocket hostFromAddress:address];
    NSString *regExPattern = @"\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:regExPattern
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    [regex enumerateMatchesInString:hostAddr options:0 range:NSMakeRange(0, [hostAddr length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        hostAddr = [hostAddr substringWithRange:[match range]];
    }];
    if (!hostAddr || connectionPort < 0) {
        return;
    }
    self.udpSocket = nil;
    if (!self.websocket) {
        [self connectWebSocketsToHost:hostAddr];
    }
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    
}

-(void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    self.udpSocket = nil;
}

#pragma mark - WebSockets

- (void)connectWebSocketsToHost:(NSString *)host {
    NSString *fullURLString = [NSString stringWithFormat:@"ws://%@:%d/websocket",host, kNoamWebsocketsPort];
    self.websocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:fullURLString]];
    self.websocket.delegate = self;
    [self.websocket open];
}

#pragma mark - SRWebSocketDelegate Methods

-(void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSArray *registrationMessage = @[@"register", @"iosClient", @0, @[@"test"], @[@"test"], @"objective-c", @"0.1"];
    NSData *sendData = [self messageDataForMessageArray:registrationMessage];
    NSString *messageString = [[NSString alloc] initWithData:sendData encoding:NSUTF8StringEncoding];
    NSLog(@"%@", messageString);
    [self.websocket send:sendData];
}

-(void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    
}

-(void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    
}

-(void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    
}

@end
