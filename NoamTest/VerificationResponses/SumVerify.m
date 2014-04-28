#import "SumVerify.h"

@implementation SumVerify

+(NSNumber*) responseFor:(NSArray*)data {
    int sum = 0;
    for (NSNumber* number in data) {
        sum += [number intValue];
    }
    return [NSNumber numberWithInt: sum];
}

@end
