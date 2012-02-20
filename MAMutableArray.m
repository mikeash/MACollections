
#import "MAMutableArray.h"


@implementation MAMutableArray
@end

void MAMutableArrayTest(void)
{
    NSMutableArray *referenceArray = [NSMutableArray array];
    NSMutableArray *testArray = [MAMutableArray array];
    
    struct seed_t { unsigned short v[3]; };
    __block struct seed_t seed = { { 0, 0, 0 } };
    
    __block NSMutableArray *array;
    
    NSArray *blocks = @[
        ^{
            [array addObject: [NSNumber numberWithInt: nrand48(seed.v)]];
        },
        ^{
            id obj = [NSNumber numberWithInt: nrand48(seed.v)];
            NSUInteger index = nrand48(seed.v) % ([array count] + 1);
            [array insertObject: obj atIndex: index];
        },
        ^{
            if([array count] > 0)
                [array removeLastObject];
        },
        ^{
            if([array count] > 0)
                [array removeObjectAtIndex: nrand48(seed.v) % [array count]];
        },
        ^{
            if([array count] > 0)
            {
                id obj = [NSNumber numberWithInt: nrand48(seed.v)];
                NSUInteger index = nrand48(seed.v) % [array count];
                [array replaceObjectAtIndex: index withObject: obj];
            }
        }
    ];
    
    for(int i = 0; i < 100000; i++)
    {
        void (^block)(void) = [blocks objectAtIndex: nrand48(seed.v) % [blocks count]];
        
        struct seed_t oldSeed = seed;
        array = testArray;
        block();
        seed = oldSeed;
        array = referenceArray;
        block();
        
        if(![referenceArray isEqual: testArray])
        {
            NSLog(@"Arrays are not equal: %@ %@", referenceArray, testArray);
            abort();
        }
    }
}
