//
//  IDAppDelegate.m
//  NoamTest
//
//  Created by Timothy Shi on 7/18/13.
//  Copyright (c) 2013 IDEO LLC. All rights reserved.
//


#import "IDNoamLemma.h"
#import "IDAppDelegate.h"


@implementation IDAppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return YES;
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [[IDNoamLemma sharedLemma] connect];
}


- (void)applicationWillResignActive:(UIApplication *)application
{
    [[IDNoamLemma sharedLemma] suspend];
}


- (void)applicationWillTerminate:(UIApplication *)application
{
    [[IDNoamLemma sharedLemma] suspend];
}


@end
