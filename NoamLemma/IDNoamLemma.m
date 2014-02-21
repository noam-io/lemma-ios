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

static const CGFloat kNoamClientVersion = 0.1;
static const uint16_t kNoamUDPBroadcastPort = 1032;
static const NSInteger kNoamWebsocketsPort = 8089;
static NSString * const kNoamDefaultClientName = @"obj-c-client";
static NSString * const kNoamClientLibraryName = @"obj-c";
static NSString * const kNoamClientBroadcastKey = @"marco";
static NSString * const kNoamRegisterKey = @"register";
static NSString * const kNoamEventKey = @"event";

+ (instancetype)sharedLemma {
    return [self sharedLemmaWithClientName:nil hearsArray:nil playsArray:nil];
}

+ (instancetype)sharedLemmaWithClientName:(NSString *)clientName
                               hearsArray:(NSArray *)hears
                               playsArray:(NSArray *)plays {
    static IDNoamLemma *sharedLemma = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLemma = [[self alloc] init];
        sharedLemma.clientName = (clientName) ? clientName : [kNoamDefaultClientName stringByAppendingFormat:@"-%d", (rand() % 1000)];
        sharedLemma.hears = (hears) ? hears : @[];
        sharedLemma.plays = (plays) ? plays : @[];
    });
    sharedLemma.clientName = (clientName) ? clientName : sharedLemma.clientName;
    sharedLemma.hears = (hears) ? hears : sharedLemma.hears;
    sharedLemma.plays = (plays) ? plays : sharedLemma.plays;
    return sharedLemma;
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
    
    NSError *error;
    if (![self.udpSocket enableBroadcast:YES error:&error]) {
        NSLog(@"ERROR: UDP broadcast disabled: %@", error);
        return;
    }
    else {
        /* Broadcast to 1030, every 5 seconds.
         * ["marco", <Lemma_name>, <RoomName>, <dialect>, <system version>]
         */
        [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(sendUDPBroadcast) userInfo:nil repeats:YES];
    }
}

- (void)sendUDPBroadcast
{
    static unsigned long counter;
    NSArray *udpBoradcastMessage = @[kNoamClientBroadcastKey,
                                     self.clientName,
                                     @"iOS_test_room",
                                     kNoamClientLibraryName,
                                     @(kNoamClientVersion)
                                     ];
    NSData *udpData = [self messageDataForLemmaBroadcastArray:udpBoradcastMessage];
    NSLog(@"sending lemma UDP broadcast [%lu]: %@", counter++, udpBoradcastMessage);
    [self.udpSocket sendData:udpData
                      toHost:@"255.255.255.255"
                        port:1030
                 withTimeout:4
                         tag:0];
}


- (NSData *)messageDataForLemmaBroadcastArray:(NSArray *)messageArray {
    if (![NSJSONSerialization isValidJSONObject:messageArray]) {
        return nil;
    }
    NSData *sendData = [NSJSONSerialization dataWithJSONObject:messageArray options:0 error:nil];
    NSString *dataString = [[NSString alloc] initWithData:sendData encoding:NSUTF8StringEncoding];
    sendData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    return sendData;
}


- (NSData *)messageDataForMessageArray:(NSArray *)messageArray {
    if (![NSJSONSerialization isValidJSONObject:messageArray]) {
        return nil;
    }
    NSData *sendData = [NSJSONSerialization dataWithJSONObject:messageArray options:0 error:nil];
    NSString *dataString = [[NSString alloc] initWithData:sendData encoding:NSUTF8StringEncoding];
    NSString *lengthString = [NSString stringWithFormat:@"%06d", sendData.length];
    NSString *sendString = [lengthString stringByAppendingString:dataString];
    sendData = [sendString dataUsingEncoding:NSUTF8StringEncoding];
    return sendData;
}

- (void)sendData:(id)data forEventName:(NSString *)eventName {
    NSArray *eventArray = @[kNoamEventKey,
                            self.clientName,
                            eventName,
                            data];
    NSData *sendData = [self messageDataForMessageArray:eventArray];
    if (sendData) {
        [self.websocket send:sendData];
    }
}

-(void)dealloc {
    [self disconnectFromNoam];
}

#pragma mark - GCDAsyncUdpSocketDelegate Methods

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error {
    [self disconnectFromNoam];
    if ([self.delegate respondsToSelector:@selector(noamLemma:didFailToConnectWithError:)]) {
        [self.delegate noamLemma:self didFailToConnectWithError:error];
    }
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    static NSString * const kIPRegExPattern = @"\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b";
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"received UDP data: %@", message);
    // Old code that grabs the connection port from Noam. Not relevant if we're connecting via WebSockets,
    // but may be useful in the future if we switch back to TCP.
    NSScanner *scanner = [NSScanner scannerWithString:message];
    [scanner setCharactersToBeSkipped:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
    int connectionPort = -1;
    [scanner scanInt:&connectionPort];
    // Uses a RegEx to pull the Noam host IP out of the address string.
    __block NSString *hostAddr = [GCDAsyncUdpSocket hostFromAddress:address];
    NSLog(@"hostAddr from UDP: %@", hostAddr);
    NSLog(@"connectionPort from UDP: %d", connectionPort);
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:kIPRegExPattern
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    [regex enumerateMatchesInString:hostAddr
                            options:0
                              range:NSMakeRange(0, [hostAddr length])
                         usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        hostAddr = [hostAddr substringWithRange:[match range]];
    }];
    NSLog(@"hostAddr after regex matching: %@", hostAddr);
    if (!hostAddr || connectionPort < 0) {
        return;
    }
//    [sock close];
//    self.udpSocket = nil;
    if (!self.websocket) {
        [self connectWebSocketsToHost:hostAddr];
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didConnectToAddress:(NSData *)address
{
    NSLog(@"UDP socket did connect");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"UDP sent data");
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"UDP failed to send data: %@", error);
}


-(void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    NSLog(@"UDP socket closed");
    self.udpSocket = nil;
    if (!self.websocket) {
        [self disconnectFromNoam];
        if ([self.delegate respondsToSelector:@selector(noamLemma:didFailToConnectWithError:)]) {
            [self.delegate noamLemma:self didFailToConnectWithError:error];
        }
    }
}

#pragma mark - WebSockets

- (void)connectWebSocketsToHost:(NSString *)host {
    
    if (nil != self.websocket) {
        return;
    }
    
    NSString *fullURLString = [NSString stringWithFormat:@"ws://%@:%@/websocket",host, @(kNoamWebsocketsPort)];
    NSLog(@"connecting webSocket: %@", fullURLString);
    self.websocket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:fullURLString]];
    self.websocket.delegate = self;
    [self.websocket open];
}

#pragma mark - SRWebSocketDelegate Methods

-(void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSLog(@"web socket did open, sending registration");
    NSArray *registrationMessage = @[kNoamRegisterKey,
                                     self.clientName,
                                     @0,
                                     self.hears,
                                     self.plays,
                                     kNoamClientLibraryName,
                                     @(kNoamClientVersion)];
    NSLog(@"registration message: %@", registrationMessage);
    NSData *sendData = [self messageDataForMessageArray:registrationMessage];
    [self.websocket send:sendData];
    if ([self.delegate respondsToSelector:@selector(noamLemmaDidConnectToNoamServer:)]) {
        [self.delegate noamLemmaDidConnectToNoamServer:self];
    }
}

-(void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    if ([message isKindOfClass:[NSString class]]) {
        NSData *dataFromString = [((NSString *)message) dataUsingEncoding:NSUTF8StringEncoding];
        id jsonObj = [NSJSONSerialization JSONObjectWithData:dataFromString options:0 error:nil];
        if ([jsonObj isKindOfClass:[NSArray class]]) {
            NSArray *jsonArray = (NSArray *)jsonObj;
            if ([jsonArray[0] isEqualToString:kNoamEventKey]) {
                NSString *lemmaID = jsonArray[1];
                NSString *eventName = jsonArray[2];
                id eventData = jsonArray[3];
                if ([self.delegate respondsToSelector:@selector(noamLemma:didReceiveData:fromLemma:forEvent:)]) {
                    [self.delegate noamLemma:self didReceiveData:eventData fromLemma:lemmaID forEvent:eventName];
                }
            }
        }
    }
}

-(void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    [self disconnectFromNoam];
    if ([self.delegate respondsToSelector:@selector(noamLemma:connectionDidCloseWithReason:)]) {
        [self.delegate noamLemma:self connectionDidCloseWithReason:reason];
    }
}

-(void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    [self disconnectFromNoam];
    if ([self.delegate respondsToSelector:@selector(noamLemma:didFailToConnectWithError:)]) {
        [self.delegate noamLemma:self didFailToConnectWithError:error];
    }
}

@end
