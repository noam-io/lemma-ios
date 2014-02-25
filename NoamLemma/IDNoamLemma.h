//
//  IDNoamLemma.h
//  NoamTest
//
//  Created by Timothy Shi on 7/22/13.
//  Copyright (c) 2013 IDEO LLC. All rights reserved.
//


#import <Foundation/Foundation.h>


@class IDNoamLemma;

@protocol IDNoamDelegate <NSObject>

@optional
- (void)noamLemmaDidConnectToNoamServer:(IDNoamLemma *)lemma;
- (void)noamLemma:(IDNoamLemma *)lemma didReceiveData:(id)data fromLemma:(NSString *)fromLemma forEvent:(NSString *)event;
- (void)noamLemma:(IDNoamLemma *)lemma didFailToConnectWithError:(NSError *)error;
- (void)noamLemma:(IDNoamLemma *)lemma connectionDidCloseWithReason:(NSString *)reason;

@end


@interface IDNoamLemma : NSObject


/**
 @name Accessing the shared lemma
 */

/** Accessor for the shared lemma.
 
 If the shared lemma hasn't been initialized, this will init the lemma with a default
 client name and empty `hears` and `plays` arrays. You will need to set these in order
 for the lemma to work properly.
 
 @returns The shared singleton lemma.
 
 */
+ (instancetype)sharedLemma;


/** Accessor for the shared lemma with parameters..
 
 If the shared lemma hasn't been initialized, this will init the lemma with the given
 parameters. If the lemma exists, the parameters will be updated to match the passed
 in parameters.
 
 @param clientName The client name registered on the Noam network.
 @param serverName The Noam server name (room name).
 @param hears An array of strings representing the heard events.
 @param plays An array of strings representing the played events.
 @param delegate IDNoamDelegate.
 @returns The shared singleton lemma.
 @warning If you change the parameters after initializing, you must disconnect & reconnect.
 
 */
+ (instancetype)sharedLemmaWithClientName:(NSString *)clientName
                               serverName:(NSString *)serverName
                               hearsArray:(NSArray *)hears
                               playsArray:(NSArray *)plays
                                 delegate:(id<IDNoamDelegate>)delegate;

/** 
 @name Communicating with Noam
 */

/**
 Initiate the connection with the Noam server.
 */
- (void)connect;


/**
 Disconnect from the Noam server and close all connections.
 */
- (void)disconnect;

- (void)suspend;


/** Send an event to the Noam network.
 
 Sends an event to the Noam network. The data can be any object type that is JSON
 serializable.
 
 @param data Any object that's JSON serializable.
 @param eventName Name of the event being sent. This name should be in the `plays` array.
 @warning No data will be sent if `data` is not JSON serializable.
 
 */
- (void)sendData:(id)data forEventName:(NSString *)eventName;


@end
