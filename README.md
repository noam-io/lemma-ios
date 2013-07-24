# obj-c-noam-lemma

This is the Objective-C lemma implementation for the Noam network.  
To read more about Noam, visit the [Noam Wiki](https://sites.google.com/a/ideo.com/noam/).

## Setup

This project is set up as a private Cocoapod for easy installation into any Objective-C project (compatible with both Mac OSX and iOS).  

Please visit [ideo-pods](https://github.com/ideo/ideo-pods) if you aren't already set up.  

Once you have the IDEO private pod repo setup, simply add:  
```ruby
pod 'objc-lemma'
```
to your ```Podfile```.  

Then run (if you do not have [ideo-pods](https://github.com/ideo/ideo-pods), this still works):
```bash
pod install
```
and you'll be all set up!

Alternatively, you can add `IDNoamLemma.h` and `IDNoamLemma.m` to your project, and make sure you have [SocketRocket](https://github.com/square/SocketRocket) and [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket). Add the following line to your code and you are ready to go:

```objc
#import "IDNoamLemma.h"
```


## Usage

The Noam lemma is initialized as a global singleton that can be easily accessed from any class. Follow these steps to create the Noam lemma and connect to the server:
```objc
IDNoamLemma *lemma = [IDNoamLemma sharedLemmaWithClientName:@"UniqueLemmaID"
                                                 serverName:@"NoamServerName"
                                                 hearsArray:@[@"listenEventName1", @"listenEventName2", @"listenEventName3"]
                                                 playsArray:@[@"sendEventName1", @"sendEventName2"]
                                                   delegate:self];
[lemma connect];
```

The Lemma will notify the delegate of connection success & data receipt via the delegate methods.  

To send data:
```objc
[[IDNoamLemma sharedLemma] sendData:@/*_JSON_SERIALIZABLE_DATA_*/ forEventName:@"sendEventName1"];
```
`NSJSONSerialization` is used to encode data, which requires:
- The top level object is an `NSArray` or `NSDictionary`.
- All objects are instances of `NSString`, `NSNumber`, `NSArray`, `NSDictionary`, or `NSNull`.
- All dictionary keys are instances of `NSString`.
- Numbers are not `NaN` or infinity.

### Notifications
It's also possible to sign up for notifications to receive the Noam events. See below:  
```objc
extern NSString * const IDNoamLemmaConnectionFailedNotification;    // Connection error.
extern NSString * const IDNoamLemmaErrorKey;                        // Returns the NSError for the connection failure.
extern NSString * const IDNoamLemmaConnectionClosedNotification;    // Connection closed.
extern NSString * const IDNoamLemmaConnectionClosedReasonKey;       // NSString connection closed reason.
extern NSString * const IDNoamLemmaDidConnectNotification;          // Lemma connected to Noam.
extern NSString * const IDNoamLemmaDidReceiveDataNotification;      // Data received from a plays broadcast.
extern NSString * const IDNoamLemmaDataKey;                         // id data from the event (NSString | NSArray | NSDictionary).
extern NSString * const IDNoamLemmaFromLemmaKey;                    // The lemma that played the event (NSString).
extern NSString * const IDNoamLemmaEventKey;                        // Played event name (NSString).
```

## Dependencies
This project does have two major dependencies, [SocketRocket](https://github.com/square/SocketRocket) and [CocoaAsyncSocket](https://github.com/robbiehanson/CocoaAsyncSocket). Please make sure to install via CocoaPods to ensure the depencies are installed.  

## Questions?  
timshi@ideo.com
