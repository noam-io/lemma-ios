//
//  IDNoamLemma.h
//  NoamTest
//
//  Created by Timothy Shi on 7/22/13.
//  Copyright (c) 2013 IDEO LLC. All rights reserved.
//

/**
 IDNoamLemma is an Objective-C implementation of a Noam client. It can be used to quickly and simply
 discover a noam server and interact with it.
 
 To start, initialize the shared lemma using `sharedLemmsWithClientName:hearsArray:playsArray`.
 This will create a global shared object for easy access from any class (it is created using a
 singleton initializer). Connect a `delegate` to receive events and data, and send events using
 `sendData:forEventName:`.
 
 Email timshi@ideo.com with any questions!
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, IDNoamLemmaReadyState) {
    IDNoamLemmaNotConnected,
    IDNoamLemmaConnecting,
    IDNoamLemmaConnected
};

@class IDNoamLemma;

@protocol IDNoamDelegate <NSObject>

@optional
- (void)noamLemma:(IDNoamLemma *)lemma didFailToConnectWithError:(NSError *)error;
- (void)noamLemma:(IDNoamLemma *)lemma connectionDidCloseWithReason:(NSString *)reason;
- (void)noamLemmaDidConnectToNoamServer:(IDNoamLemma *)lemma;
- (void)noamLemma:(IDNoamLemma *)lemma
   didReceiveData:(id)data
        fromLemma:(NSString *)fromLemma
         forEvent:(NSString *)event;

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
 @param hears An array of strings representing the heard events.
 @param plays An array of strings representing the played events.
 @returns The shared singleton lemma.
 @warning If you change the parameters after initializing, you must disconnect & reconnect.
 
 */
+ (instancetype)sharedLemmaWithClientName:(NSString *)clientName
                               hearsArray:(NSArray *)hears
                               playsArray:(NSArray *)plays;

/** 
 @name Communicating with Noam
 */

/**
 Initiate the connection with the Noam server.
 */
- (void)connectToNoam;

/**
 Disconnect from the Noam server and close all connections.
 */
- (void)disconnectFromNoam;

/** Send an event to the Noam network.
 
 Sends an event to the Noam network. The data can be any object type that is JSON
 serializable.
 
 @param data Any object that's JSON serializable.
 @param eventName Name of the event being sent. This name should be in the `plays` array.
 @warning No data will be sent if `data` is not JSON serializable.
 
 */
- (void)sendData:(id)data forEventName:(NSString *)eventName;

@property (nonatomic, copy) NSString *clientName;
@property (nonatomic, strong) NSArray *hears, *plays;
@property (nonatomic, readonly) IDNoamLemmaReadyState readyState;
@property (nonatomic, weak) id <IDNoamDelegate> delegate;

@end
