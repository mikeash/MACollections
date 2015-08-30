
#import "MAMutableArray.h"


@implementation MAMutableArray {
    NSUInteger _count;
    NSUInteger _capacity;
    id *_objs;
}

- (id)initWithCapacity: (NSUInteger)capacity
{
    return [super init];
}

- (void)dealloc
{
    [self removeAllObjects];
    free(_objs);
    [super dealloc];
}

- (NSUInteger)count
{
    return _count;
}

- (id)objectAtIndex: (NSUInteger)index
{
    return _objs[index];
}

- (void)addObject:(id)anObject
{
    [self insertObject: anObject atIndex: [self count]];
}

- (void)insertObject: (id)anObject atIndex: (NSUInteger)index
{
    if(_count >= _capacity)
    {
        NSUInteger newCapacity = MAX(_capacity * 2, 16);
        id *newObjs = malloc(newCapacity * sizeof(*newObjs));
        
        memcpy(newObjs, _objs, _count * sizeof(*_objs));
        
        free(_objs);
        _objs = newObjs;
        _capacity = newCapacity;
    }
    
    memmove(_objs + index + 1, _objs + index, ([self count] - index) * sizeof(*_objs));
    _objs[index] = [anObject retain];
    
    _count++;
}

- (void)removeLastObject
{
    [self removeObjectAtIndex: [self count] - 1];
}

- (void)removeObjectAtIndex: (NSUInteger)index
{
    [_objs[index] release];
    memmove(_objs + index, _objs + index + 1, ([self count] - index - 1) * sizeof(*_objs));
    
    _count--;
}

- (void)replaceObjectAtIndex: (NSUInteger)index withObject: (id)anObject
{
    [anObject retain];
    [_objs[index] release];
    _objs[index] = anObject;
}

@end

void MAMutableArrayTest(void)
{
    NSMutableArray *referenceArray = [NSMutableArray array];
    MAMutableArray *testArray = [MAMutableArray array];
    
    struct seed_t { unsigned short v[3]; };
    __block struct seed_t seed = { { 0, 0, 0 } };
    
    __block NSMutableArray *array;
    
    void (^blocks[])(void) = {
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
    };
    
    NSMutableArray *operations = [NSMutableArray array];
    
    for(int i = 0; i < 100000; i++)
    {
        NSUInteger index = nrand48(seed.v) % (sizeof(blocks) / sizeof(*blocks));
        void (^block)(void) = blocks[index];
        [operations addObject: [NSNumber numberWithInteger: index]];
        
        struct seed_t oldSeed = seed;
        array = testArray;
        block();
        seed = oldSeed;
        array = referenceArray;
        block();
        
        if(![referenceArray isEqual: testArray])
        {
            int one = nrand48(oldSeed.v);
            int two = nrand48(oldSeed.v);
            NSLog(@"Next two random numbers are %d %d", one, two);
            NSLog(@"Arrays are not equal after %@: %@ %@", operations, referenceArray, testArray);
            exit(1);
        }
    }
}
