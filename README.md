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

Then run:
```bash
pod install
```
and you'll be all set up!

## Usage

The Noam lemma is initialized as a global singleton that can be easily accessed from any class. Follow these steps to create the Noam lemma and connect to the server:
```objc
IDNoamLemma *lemma = [IDNoamLemma sharedLemmaWithClientName:@"YOUR_CLIENT_NAME"
                                                     hearsArray:@[@"YOUR_HEARS"]
                                                     playsArray:@[@"YOUR_PLAYS"]];
lemma.delegate = self;
[lemma connectToNoam];
```

The Lemma will notify the delegate of connection success & data receipt via the delegate methods.  

To send data:
```objc
[[IDNoamLemma sharedLemma] sendData:@[@EXAMPLE_ARRAY_OF_DATA] forEventName:@"MY_EVENT"];
```

## Questions?  
timshi@ideo.com
