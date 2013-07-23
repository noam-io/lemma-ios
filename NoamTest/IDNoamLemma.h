//
//  IDNoamLemma.h
//  NoamTest
//
//  Created by Timothy Shi on 7/22/13.
//  Copyright (c) 2013 IDEO LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, IDNoamLemmaReadyState) {
    IDNoamLemmaNotConnected,
    IDNoamLemmaConnecting,
    IDNoamLemmaConnected
};

@class IDNoamLemma;

@protocol IDNoamDelegate

@optional
- (void)noamLemma:(IDNoamLemma *)lemma didFailToConnectWithError:(NSError *)error;
- (void)noamLemma:(IDNoamLemma *)lemma connectionDidCloseWithReason:(NSString *)reason;
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

@property (nonatomic, readonly) IDNoamLemmaReadyState readyState;
@property (nonatomic, copy) NSString *clientName;
@property (nonatomic, strong) NSArray *hears, *plays;
@property (nonatomic, weak) id <IDNoamDelegate> delegate;

@end
