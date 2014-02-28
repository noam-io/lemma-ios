//
//  IDNoamLemma.m
//  NoamTest
//
//  Created by Timothy Shi on 7/22/13.
//  Copyright (c) 2013 IDEO LLC. All rights reserved.
//


#import <CocoaAsyncSocket/GCDAsyncUdpSocket.h>
#import <SocketRocket/SRWebSocket.h>


#import "IDNoamLemma.h"


@interface IDNoamLemma () <GCDAsyncUdpSocketDelegate, SRWebSocketDelegate>

@property (nonatomic, copy) NSString *clientName;
@property (nonatomic, copy) NSString *serverName;
@property (nonatomic, strong) NSArray *hears;
@property (nonatomic, strong) NSArray *plays;
@property (nonatomic, weak) id <IDNoamDelegate> delegate;
@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) SRWebSocket *websocket;
@property (nonatomic, strong) NSTimer *broadcastTimer;
@property (nonatomic, strong) NSTimer *heartbeatTimer;
@property (nonatomic, assign) BOOL suspended;

@end


@implementation IDNoamLemma


static const CGFloat kNoamClientVersion = 0.1;
static const uint16_t kNoamUDPBroadcastPort = 1032;
static const NSInteger kNoamWebsocketsPort = 8089;
static NSString * const kNoamUDPBroadcastPrefixPattern = @"[\"polo\",";
static const uint16_t kLemmaUDPBroadcastPort = 1030;
static NSString * const kLemmaUDPBroadcastAddress = @"255.255.255.255";
static const NSInteger kLemmaUDPBroadcastInterval = 5;
static NSString * const kNoamDefaultClientName = @"iOS-client";
static NSString * const kNoamClientLibraryName = @"iOS";
static NSString * const kNoamClientBroadcastKey = @"marco";
static NSString * const kNoamRegisterKey = @"register";
static NSString * const kNoamEventKey = @"event";
static NSString * const kNoamClientHeartbeatKey = @"heartbeat";
static const NSInteger kNoamClientHeartbeatInterval = 5;


#pragma mark - setup


+ (instancetype)sharedLemma {
    return [self sharedLemmaWithClientName:nil serverName:nil hearsArray:nil playsArray:nil delegate:nil];
}


+ (instancetype)sharedLemmaWithClientName:(NSString *)clientName
                               serverName:(NSString *)serverName
                               hearsArray:(NSArray *)hears
                               playsArray:(NSArray *)plays
                                 delegate:(id<IDNoamDelegate>)delegate {
    static IDNoamLemma *sharedLemma = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedLemma = [[self alloc] init];
        sharedLemma.clientName = (clientName) ? clientName : [kNoamDefaultClientName stringByAppendingFormat:@"-%d", (rand() % 1000)];
        sharedLemma.serverName = (serverName) ? serverName : @"";
        sharedLemma.hears = (hears) ? hears : @[];
        sharedLemma.plays = (plays) ? plays : @[];
        sharedLemma.delegate = delegate;
        NSLog(@"creating lemma:\n"
              "clientName: %@\n"
              "serverName: %@\n"
              "hears: %@\n"
              "plays: %@\n"
              "delegate: %@",
              sharedLemma.clientName,
              sharedLemma.serverName,
              sharedLemma.hears,
              sharedLemma.plays,
              sharedLemma.delegate);
    });
    return sharedLemma;
}


- (id)init {
    self = [super init];
    if (self) {
        self.delegateQueue = dispatch_queue_create("com.ideo.noam.delegateQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


- (void)connect {
    NSLog(@"connecting to NOAM ...");
    [self beginFindingNoam];
}


- (void)disconnect {
    NSLog(@"disconnect from NOAM");
    if (self.udpSocket) {
        [self.udpSocket close];
        self.udpSocket = nil;
    }
    if (self.websocket) {
        [self.websocket close];
        self.websocket = nil;
    }
    [self unScheduleHeartbeat];
}


- (void)suspend {
    NSLog(@"suspend");
    self.suspended = YES;
    [self disconnect];
    [self unScheduleUDPBroadcast];
}


- (void)beginFindingNoam {
    self.suspended = NO;
    self.udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:self.delegateQueue];
    [self.udpSocket bindToPort:kNoamUDPBroadcastPort error:nil];
    [self.udpSocket beginReceiving:nil];
    
    [self scheduleUDPBroadcast];
}


/* Broadcast to 1030, every 5 seconds.
 * ["marco", <Lemma_name>, <RoomName>, <dialect>, <system version>]
 */
- (void)scheduleUDPBroadcast {
    [self.broadcastTimer invalidate];
    NSError *error;
    if (![self.udpSocket enableBroadcast:YES error:&error]) {
        NSLog(@"ERROR: UDP broadcast disabled: %@", error);
        return;
    }
    else {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.broadcastTimer = [NSTimer scheduledTimerWithTimeInterval:kLemmaUDPBroadcastInterval
                                                                   target:self
                                                                 selector:@selector(sendUDPBroadcast:)
                                                                 userInfo:nil
                                                                  repeats:YES];
        });
    }
}


- (void)unScheduleUDPBroadcast {
    [self.broadcastTimer invalidate];
    self.broadcastTimer = nil;
}


- (void)sendUDPBroadcast:(NSTimer *)timer {
    NSArray *udpBoradcastMessage = @[kNoamClientBroadcastKey,
                                     self.clientName,
                                     self.serverName,
                                     kNoamClientLibraryName,
                                     @(kNoamClientVersion)
                                     ];
    NSLog(@"sending UDP broadcast: %@", udpBoradcastMessage);
    NSData *udpData = [self messageDataForLemmaBroadcastArray:udpBoradcastMessage];
    [self.udpSocket sendData:udpData
                      toHost:kLemmaUDPBroadcastAddress
                        port:kLemmaUDPBroadcastPort
                 withTimeout:kLemmaUDPBroadcastInterval - 1
                         tag:0];
}


- (void)scheduleHeartbeat
{
    [self.heartbeatTimer invalidate];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.heartbeatTimer = [NSTimer scheduledTimerWithTimeInterval:kNoamClientHeartbeatInterval
                                                               target:self
                                                             selector:@selector(sendHeartbeat:)
                                                             userInfo:nil
                                                              repeats:YES];
    });
}


- (void)unScheduleHeartbeat
{
    [self.heartbeatTimer invalidate];
    self.heartbeatTimer = nil;
}


- (void)sendHeartbeat:(NSTimer *)timer
{
    NSLog(@"sending heartbeat");
    [[IDNoamLemma sharedLemma] sendData:[NSString stringWithFormat:@"[\"%@\",\"%@\"]", kNoamClientHeartbeatKey, self.clientName]
                           forEventName:kNoamClientHeartbeatKey];
}


/* build message without leading length header */
- (NSData *)messageDataForLemmaBroadcastArray:(NSArray *)messageArray {
    if (![NSJSONSerialization isValidJSONObject:messageArray]) {
        return nil;
    }
    NSData *sendData = [NSJSONSerialization dataWithJSONObject:messageArray options:0 error:nil];
    NSString *dataString = [[NSString alloc] initWithData:sendData encoding:NSUTF8StringEncoding];
    sendData = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    return sendData;
}


/* build message with leading length header */
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
    [self disconnect];
}


#pragma mark - GCDAsyncUdpSocketDelegate


-(void)udpSocket:(GCDAsyncUdpSocket *)sock didNotConnect:(NSError *)error {
    [self disconnect];
    if ([self.delegate respondsToSelector:@selector(noamLemma:didFailToConnectWithError:)]) {
        [self.delegate noamLemma:self didFailToConnectWithError:error];
    }
}


-(void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext {
    static NSString * const kIPRegExPattern = @"\\b(?:\\d{1,3}\\.){3}\\d{1,3}\\b";
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"received UDP data: %@", message);
    NSRange search = [message rangeOfString:kNoamUDPBroadcastPrefixPattern];
    if (0 != search.location) {
        /* ignore everything except polo messages */
        return;
    }
    NSScanner *scanner = [NSScanner scannerWithString:message];
    [scanner setCharactersToBeSkipped:[[NSCharacterSet decimalDigitCharacterSet] invertedSet]];
    int connectionPort = -1;
    [scanner scanInt:&connectionPort];
    __block NSString *hostAddr = [GCDAsyncUdpSocket hostFromAddress:address];
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
    NSLog(@"hostAddr from UDP packet: %@", hostAddr);
    NSLog(@"connectionPort from UDP packet: %d", connectionPort);
    if (!hostAddr || connectionPort < 0) {
        return;
    }
    [self unScheduleUDPBroadcast];
    if (!self.websocket) {
        [self connectWebSocketsToHost:hostAddr];
    }
}


- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"UDP failed to send data: %@", error);
}


-(void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    NSLog(@"UDP socket closed");
    if (YES == self.suspended) {
        /* suspended when app goes into background mode, do nothing */
        NSLog(@"suspended");
    }
    else {
        /* unexpected disconnect, drop everything, either call user delegate or try to re-connect */
        [self disconnect];
        if ([self.delegate respondsToSelector:@selector(noamLemma:didFailToConnectWithError:)]) {
            [self.delegate noamLemma:self didFailToConnectWithError:error];
        }
        else {
            NSLog(@"reconnecting ...");
            [self connect];
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


#pragma mark - SRWebSocketDelegate


-(void)webSocketDidOpen:(SRWebSocket *)webSocket {
    NSArray *registrationMessage = @[kNoamRegisterKey,
                                     self.clientName,
                                     @0,
                                     self.hears,
                                     self.plays,
                                     kNoamClientLibraryName,
                                     @(kNoamClientVersion),
                                     @{kNoamClientHeartbeatKey : @(kNoamClientHeartbeatInterval)}];
    NSLog(@"web socket did open, send registration message: %@", registrationMessage);
    NSData *sendData = [self messageDataForMessageArray:registrationMessage];
    [self.websocket send:sendData];
    if ([self.delegate respondsToSelector:@selector(noamLemmaDidConnectToNoamServer:)]) {
        [self.delegate noamLemmaDidConnectToNoamServer:self];
    }
    [self scheduleHeartbeat];
}


-(void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"RECEIVED: %@", message);
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
    NSLog(@"web socket closed");
    [self disconnect];
    if ([self.delegate respondsToSelector:@selector(noamLemma:connectionDidCloseWithReason:)]) {
        [self.delegate noamLemma:self connectionDidCloseWithReason:reason];
    }
}


-(void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"web socket failed");
    [self disconnect];
    if ([self.delegate respondsToSelector:@selector(noamLemma:didFailToConnectWithError:)]) {
        [self.delegate noamLemma:self didFailToConnectWithError:error];
    }
}


@end
