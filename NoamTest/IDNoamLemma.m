//
//  IDNoamLemma.m
//  NoamTest
//
//  Created by Timothy Shi on 7/22/13.
//  Copyright (c) 2013 IDEO LLC. All rights reserved.
//

#import "IDNoamLemma.h"

#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import <SocketRocket/SRWebSocket.h>

@interface IDNoamLemma () <GCDAsyncUdpSocketDelegate, SRWebSocketDelegate>

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) SRWebSocket *websocket;

@end

@implementation IDNoamLemma

static const uint16_t kNoamUDPBroadcastPort = 1033;
static const NSInteger kNoamWebsocketsPort = 8089;

+ (instancetype)lemma {
    return [[self alloc] init];
}

- (id)init {
    self = [super init];
    if (self) {
        self.delegateQueue = dispatch_queue_create("com.ideo.noam.delegateQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (IDNoamLemmaReadyState)readyState {
    if (self.websocket) {
        if (self.websocket.readyState == SR_CONNECTING) {
            return IDNoamLemmaConnecting;
        } else if (self.websocket.readyState == SR_OPEN) {
            return IDNoamLemmaConnected;
        }
    } else if (self.udpSocket) {
        if ([self.udpSocket isConnected]) {
            return IDNoamLemmaConnecting;
        }
    }
    return IDNoamLemmaNotConnected;
}

- (void)connectToNoam {
    [self beginFindingNoam];
}

- (void)disconnectFromNoam {
    if (self.udpSocket) {
        [self.udpSocket close];
        self.udpSocket = nil;
    }
    if (self.websocket) {
        [self.websocket close];
        self.websocket = nil;
    }
}

- (void)beginFindingNoam {
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

-(void)dealloc {
    [self disconnectFromNoam];
}

#pragma mark - GCDAsyncUdpSocketDelegate Methods

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error {
    [self disconnectFromNoam];
    [self.delegate noamLemma:self didFailToConnectWithError:error];
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    // Old code that grabs the connection port from Noam. Not relevant if we're connecting via WebSockets,
    // but may be useful in the future if we switch back to TCP.
    NSScanner *scanner = [NSScanner scannerWithString:message];
    [scanner setCharactersToBeSkipped:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
    int connectionPort = -1;
    [scanner scanInt:&connectionPort];
    // Uses a RegEx to pull the Noam host IP out of the address string.
    __block NSString *hostAddr = [GCDAsyncUdpSocket hostFromAddress:address];
    NSString *regExPattern = @"\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b";
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:regExPattern
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    [regex enumerateMatchesInString:hostAddr
                            options:0
                              range:NSMakeRange(0, [hostAddr length])
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        hostAddr = [hostAddr substringWithRange:[match range]];
    }];
    if (!hostAddr || connectionPort < 0) {
        return;
    }
    if (!self.websocket) {
        [self connectWebSocketsToHost:hostAddr];
        [sock close];
        self.udpSocket = nil;
    }
}

-(void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    self.udpSocket = nil;
    [self disconnectFromNoam];
    [self.delegate noamLemma:self didFailToConnectWithError:error];
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
    NSArray *registrationMessage = @[@"register",
                                     @"iosClient",
                                     @0,
                                     @[@"test"],
                                     @[@"test"],
                                     @"objective-c",
                                     @"0.1"];
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
