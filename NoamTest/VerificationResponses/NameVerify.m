#import "NameVerify.h"

@implementation NameVerify

+(NSString*) responseFor:(NSDictionary*)data {
    NSString* fullName = [NSString stringWithFormat: @"%@ %@",
                          [data objectForKey: @"firstName"],
                          [data objectForKey: @"lastName"]];
    NSDictionary* response = @{
                               @"fullName": fullName
                               };
    NSData *sendData = [NSJSONSerialization dataWithJSONObject:response
                                                       options:0
                                                         error:nil];
    NSString *dataString = [[NSString alloc] initWithData:sendData
                                                 encoding:NSUTF8StringEncoding];

    return dataString;
}

@end
