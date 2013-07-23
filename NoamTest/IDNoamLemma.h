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

- (void)noamLemma:(IDNoamLemma *)lemma didFailToConnectWithError:(NSError *)error;
- (void)noamLemma:(IDNoamLemma *)lemma;

@end

@interface IDNoamLemma : NSObject

+ (instancetype)lemma;

- (void)connectToNoam;
- (void)disconnectFromNoam;

@property (nonatomic, readonly) IDNoamLemmaReadyState readyState;
@property (nonatomic, weak) id <IDNoamDelegate> delegate;

@end
