
#import <Foundation/Foundation.h>
#import <objc/runtime.h>


@interface RTProtocol : NSObject
{
}

+ (NSArray *)allProtocols;

+ (id)protocolWithObjCProtocol: (Protocol *)protocol;
+ (id)protocolWithName: (NSString *)name;

- (id)initWithObjCProtocol: (Protocol *)protocol;
- (id)initWithName: (NSString *)name;

- (id)objCProtocol;
- (NSString *)name;
- (NSArray *)incorporatedProtocols;
- (NSArray *)methodsRequired: (BOOL)isRequiredMethod instance: (BOOL)isInstanceMethod;

@end
