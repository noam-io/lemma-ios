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

#import <sys/socket.h>
#import <netinet/in.h>
#import <socket.IO/SocketIO.h>

@interface IDViewController () <GCDAsyncUdpSocketDelegate, GCDAsyncSocketDelegate, NSStreamDelegate, SocketIODelegate>

@property (nonatomic, strong) GCDAsyncUdpSocket *udpSocket;
@property (nonatomic, strong) GCDAsyncSocket *tcpSocket;
@property (nonatomic) dispatch_queue_t delegateQueue;
@property (nonatomic, strong) NSTimer *sendTimer, *readTimer;
@property (nonatomic, strong) NSInputStream *inputStream;
@property (nonatomic, strong) NSOutputStream *outputStream;
@property (nonatomic, strong) SocketIO *websocket;

@end

@implementation IDViewController

static const uint16_t kNoamUDPBroadcastPort = 1033;

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
    dispatch_async(dispatch_get_main_queue(), ^{
        NSArray *registrationMessage = @[@"register", @"iosClient", @([self.tcpSocket localPort]), @[@"test"], @[@"test"], @"objective-c", @"0.1"];
        NSData *sendData = [self messageDataForMessageArray:registrationMessage];
        [self.tcpSocket writeData:sendData withTimeout:1000 tag:1];
        [self startSendAndReceive];
        [self.tcpSocket readDataWithTimeout:-1 tag:0];
    });
//    NSArray *eventMessage = @[@"event", @"iosClient", @"test", @"yee"];
//    sendData = [self messageDataForMessageArray:eventMessage];
//    [self.tcpSocket writeData:sendData withTimeout:1000 tag:0];
//    double delayInSeconds = 2.0;
//    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
//    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
//        [self.tcpSocket readDataWithTimeout:-1 tag:0];
//    });
}

- (NSData *)messageDataForMessageArray:(NSArray *)messageArray {
    NSData *sendData = [NSJSONSerialization dataWithJSONObject:messageArray options:0 error:nil];
    NSString *dataString = [[NSString alloc] initWithData:sendData encoding:NSUTF8StringEncoding];
    NSString *lengthString = [NSString stringWithFormat:@"%06d", sendData.length];
    NSString *sendString = [lengthString stringByAppendingString:dataString];
    sendData = [sendString dataUsingEncoding:NSUTF8StringEncoding];
    return sendData;
}

- (void)startSocketWithHost:(NSString *)host andPort:(UInt32)port {
    CFReadStreamRef readStream;
    CFWriteStreamRef writeStream;
    CFStreamCreatePairWithSocketToHost(NULL, (__bridge CFStringRef)host, port, &readStream, &writeStream);
    self.inputStream = (NSInputStream *)CFBridgingRelease(readStream);
    self.outputStream = (NSOutputStream *)CFBridgingRelease(writeStream);
    [self.inputStream setDelegate:self];
    [self.outputStream setDelegate:self];
    [self.inputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.outputStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.inputStream open];
    [self.outputStream open];
    NSString *test = @"";
    NSData *testData = [test dataUsingEncoding:NSUTF8StringEncoding];
    [self.outputStream write:[testData bytes] maxLength:[testData length]];
    NSArray *registrationMessage = @[@"register", @"iosClient", @([self portNumForNSInputStream:self.inputStream]), @[@"test"], @[@"test"], @"objective-c", @"0.1"];
    NSData *sendData = [self messageDataForMessageArray:registrationMessage];
    [self.outputStream write:[sendData bytes] maxLength:[sendData length]];
}

-(int) socknumForNSInputStream: (NSStream *)stream
{
    int sock = -1;
    NSData *sockObj = [stream propertyForKey:
                       (__bridge NSString *)kCFStreamPropertySocketNativeHandle];
    if ([sockObj isKindOfClass:[NSData class]] &&
        ([sockObj length] == sizeof(int)) ) {
        const int *sockptr = (const int *)[sockObj bytes];
        sock = *sockptr;
    }
    return sock;
}

- (int)portNumForNSInputStream:(NSStream *)stream {
    int sockNum = [self socknumForNSInputStream:stream];
    struct sockaddr_in sin;
    socklen_t len = sizeof(sin);
    int port = -1;
    if (getsockname(sockNum, (struct sockaddr *)&sin, &len) == -1) {
        NSLog(@"couldn't get socket port");
    }
    else {
        port = ntohs(sin.sin_port);
    }
    return port;
}

- (void)startSendAndReceive {
    self.sendTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                      target:self
                                                    selector:@selector(sendTestMessage)
                                                    userInfo:nil
                                                     repeats:YES];
    self.readTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                      target:self
                                                    selector:@selector(readData)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void)sendTestMessage {
    NSArray *eventMessage = @[@"event", @"iosClient", @"test", @([[NSDate date] timeIntervalSince1970])];
    NSData *sendData = [self messageDataForMessageArray:eventMessage];
    [self.tcpSocket writeData:sendData withTimeout:-1 tag:0];
}

- (void)readData {
    [self.tcpSocket performBlock:^{
        Boolean available = CFReadStreamHasBytesAvailable(self.tcpSocket.readStream);
        NSLog(@"%@", (available) ? @"YES" : @"NO");
    }];
//    NSMutableData *
//    [self.tcpSocket readDataWithTimeout:-1 tag:0];
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
    NSString *hostAddr = [GCDAsyncUdpSocket hostFromAddress:address];
    if (!hostAddr || connectionPort < 0) {
        return;
    }
//    if (!self.inputStream) {
//        [self startSocketWithHost:hostAddr andPort:connectionPort];
//    }
//    if (!self.tcpSocket && ![self.tcpSocket isConnected]) {
//        [self createTCPSocketWithHost:hostAddr andPort:connectionPort];
//    }
    NSString *webSocketsURLString = [hostAddr stringByAppendingString:@"/websocket"];
    
}

-(void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag {
    
}

-(void)udpSocketDidClose:(GCDAsyncUdpSocket *)sock withError:(NSError *)error {
    self.udpSocket = nil;
}

#pragma mark - GCDAsyncSocketDelegate Methods

-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"connected to host: %@", host);
    [self sendRegistrationMessage];
}

-(void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    
}

-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    
}

-(void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSLog(@"did read data: %@", data);
}

- (void)socket:(GCDAsyncSocket *)sock didReadPartialDataOfLength:(NSUInteger)partialLength tag:(long)tag {
    NSLog(@"did read data partially");
}

-(void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    
}

- (void)socketDidCloseReadStream:(GCDAsyncSocket *)sock {
    
}

#pragma mark - NSStreamDelegate Methods

- (void)stream:(NSStream *)theStream handleEvent:(NSStreamEvent)streamEvent {
    
	switch (streamEvent) {
            
		case NSStreamEventOpenCompleted:
        {
			NSLog(@"Stream opened");
//            int portNum = [self portNumForNSInputStream:self.inputStream];
//            
//            NSArray *registrationMessage = @[@"register", @"iosClient2", @(portNum), @[@"test"], @[@"test"], @"objective-c", @"0.1"];
//            NSData *sendData = [self messageDataForMessageArray:registrationMessage];
//            [self.outputStream write:[sendData bytes] maxLength:[sendData length]];
			break;
        }
		case NSStreamEventHasBytesAvailable:
            if (theStream == self.inputStream) {
                
                uint8_t buffer[1024];
                int len;
                
                while ([self.inputStream hasBytesAvailable]) {
                    len = [self.inputStream read:buffer maxLength:sizeof(buffer)];
                    if (len > 0) {
                        
                        NSString *output = [[NSString alloc] initWithBytes:buffer length:len encoding:NSASCIIStringEncoding];
                        
                        if (nil != output) {
                            NSLog(@"server said: %@", output);
                        }
                    }
                }
            }
			break;
            
		case NSStreamEventErrorOccurred:
			NSLog(@"Can not connect to the host!");
			break;
            
		case NSStreamEventEndEncountered:
			break;
            
		default:
			NSLog(@"Unknown event");
	}
    
}

#pragma mark - WebSockets

- (void)connectWebSocketsToHost:(NSString *)host onPort:(NSInteger)port {
    self.websocket = [[SocketIO alloc] initWithDelegate:self];
    [self.websocket connectToHost:host onPort:port];
}

#pragma mark - SocketIODelegate Methods

-(void)socketIODidConnect:(SocketIO *)socket {
    NSArray *registrationMessage = @[@"register", @"iosClient", @0, @[@"test"], @[@"test"], @"objective-c", @"0.1"];
    NSData *sendData = [self messageDataForMessageArray:registrationMessage];
    NSString *messageString = [[NSString alloc] initWithData:sendData encoding:NSUTF8StringEncoding];
    [self.websocket sendMessage:messageString];
}

-(void)socketIO:(SocketIO *)socket didReceiveMessage:(SocketIOPacket *)packet {
    
}

-(void)socketIO:(SocketIO *)socket didSendMessage:(SocketIOPacket *)packet {
    
}

-(void)socketIO:(SocketIO *)socket onError:(NSError *)error {
    
}

-(void)socketIODidDisconnect:(SocketIO *)socket disconnectedWithError:(NSError *)error {
    
}

@end
