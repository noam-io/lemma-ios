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

@interface IDViewController () <GCDAsyncUdpSocketDelegate>

@end

@implementation IDViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - GCDAsyncUdpSocketDelegate Methods



@end
