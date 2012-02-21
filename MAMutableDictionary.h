
#import <Foundation/Foundation.h>

@interface MAFixedMutableDictionary : NSMutableDictionary
- (id)initWithSize: (NSUInteger)size;
@end

@interface MAMutableDictionary : NSMutableDictionary
@end

void MAMutableDictionaryTest(void);
