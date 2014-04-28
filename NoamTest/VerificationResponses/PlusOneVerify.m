#import "PlusOneVerify.h"

@implementation PlusOneVerify

+(NSNumber*) responseFor:(NSNumber*)data {
    return [NSNumber numberWithInt: [data intValue] + 1];
}

@end
