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

+ (instancetype)sharedLemma;
+ (instancetype)sharedLemmaWithClientName:(NSString *)clientName
                               hearsArray:(NSArray *)hears
                               playsArray:(NSArray *)plays;

- (void)connectToNoam;
- (void)disconnectFromNoam;
- (void)sendData:(id)data forEventName:(NSString *)eventName;

@property (nonatomic, copy) NSString *clientName;
@property (nonatomic, strong) NSArray *hears, *plays;
@property (nonatomic, readonly) IDNoamLemmaReadyState readyState;
@property (nonatomic, weak) id <IDNoamDelegate> delegate;

@end
