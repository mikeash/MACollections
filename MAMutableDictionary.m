
#import "MAMutableDictionary.h"

@interface _MAMutableDictionaryBucket : NSObject
@property (nonatomic, copy) id key;
@property (nonatomic, retain) id obj;
@property (nonatomic, retain) _MAMutableDictionaryBucket *next;
@end

@implementation _MAMutableDictionaryBucket

- (void)dealloc
{
    [_key release];
    [_obj release];
    [_next release];
    [super dealloc];
}

@end


@interface _MABlockEnumerator : NSEnumerator
{
    id (^_block)(void);
}
- (id)initWithBlock: (id (^)(void))block;
@end

@implementation _MABlockEnumerator

- (id)initWithBlock: (id (^)(void))block
{
    if((self = [self init]))
        _block = [block copy];
    return self;
}

- (void)dealloc
{
    [_block release];
    [super dealloc];
}

- (id)nextObject
{
    return _block();
}

@end


@implementation MAFixedMutableDictionary {
    NSUInteger _count;
    NSUInteger _size;
    _MAMutableDictionaryBucket **_array;
}

- (id)initWithSize: (NSUInteger)size
{
    if((self = [super init]))
    {
        _size = size;
        _array = calloc(size, sizeof(*_array));
    }
    return self;
}

- (void)dealloc
{
    for(NSUInteger i = 0; i < _size; i++)
        [_array[i] release];
    free(_array);
    
    [super dealloc];
}

- (NSUInteger)count
{
    return _count;
}

- (id)objectForKey: (id)key
{
    NSUInteger bucketIndex = [key hash] % _size;
    _MAMutableDictionaryBucket *bucket = _array[bucketIndex];
    while(bucket)
    {
        if([[bucket key] isEqual: key])
            return [bucket obj];
        bucket = [bucket next];
    }
    return nil;
}

- (NSEnumerator *)keyEnumerator
{
    __block NSUInteger index = -1;
    __block _MAMutableDictionaryBucket *bucket = nil;
    NSEnumerator *e = [[_MABlockEnumerator alloc] initWithBlock: ^{
        bucket = [bucket next];
        while(!bucket)
        {
            index++;
            if(index >= _size)
                return (id)nil;
            bucket = _array[index];
        }
        return [bucket key];
    }];
    return [e autorelease];
}

- (void)removeObjectForKey: (id)key
{
    NSUInteger bucketIndex = [key hash] % _size;
    _MAMutableDictionaryBucket *previousBucket = nil;
    _MAMutableDictionaryBucket *bucket = _array[bucketIndex];
    while(bucket)
    {
        if([[bucket key] isEqual: key])
        {
            if(previousBucket == nil)
            {
                _MAMutableDictionaryBucket *nextBucket = [[bucket next] retain];
                [_array[bucketIndex] release];
                _array[bucketIndex] = nextBucket;
            }
            else
            {
                [previousBucket setNext: [bucket next]];
            }
            _count--;
            return;
        }
        previousBucket = bucket;
        bucket = [bucket next];
    }
}

- (void)setObject: (id)obj forKey: (id)key
{
    _MAMutableDictionaryBucket *newBucket = [[_MAMutableDictionaryBucket alloc] init];
    [newBucket setKey: key];
    [newBucket setObj: obj];
    
    [self removeObjectForKey: key];

    NSUInteger bucketIndex = [key hash] % _size;
    [newBucket setNext: _array[bucketIndex]];
    [_array[bucketIndex] release];
    _array[bucketIndex] = newBucket;
    _count++;
}

@end

@implementation MAMutableDictionary {
    NSUInteger _size;
    MAFixedMutableDictionary *_fixedDict;
}

static const NSUInteger kMaxLoadFactorNumerator = 7;
static const NSUInteger kMaxLoadFactorDenominator = 10;

- (id)initWithCapacity: (NSUInteger)capacity
{
    capacity = MAX(capacity, 4);
    if((self = [super init]))
    {
        _size = capacity;
        _fixedDict = [[MAFixedMutableDictionary alloc] initWithSize: _size];
    }
    return self;
}

- (void)dealloc
{
    [_fixedDict release];
    [super dealloc];
}

- (NSUInteger)count
{
    return [_fixedDict count];
}

- (id)objectForKey: (id)key
{
    return [_fixedDict objectForKey: key];
}

- (NSEnumerator *)keyEnumerator
{
    return [_fixedDict keyEnumerator];
}

- (void)removeObjectForKey: (id)key
{
    [_fixedDict removeObjectForKey: key];
}

- (void)setObject: (id)obj forKey:(id)key
{
    [_fixedDict setObject: obj forKey: key];
    
    if(kMaxLoadFactorDenominator * [_fixedDict count] / _size > kMaxLoadFactorNumerator)
    {
        NSUInteger newSize = _size * 2;
        MAFixedMutableDictionary *newDict = [[MAFixedMutableDictionary alloc] initWithSize: newSize];
        
        for(id key in _fixedDict)
            [newDict setObject: [_fixedDict objectForKey: key] forKey: key];
        
        [_fixedDict release];
        _size = newSize;
        _fixedDict = newDict;
    }
}

@end

static void Test(NSMutableDictionary *testDictionary)
{
    NSMutableDictionary *referenceDictionary = [NSMutableDictionary dictionary];
    
    struct seed_t { unsigned short v[3]; };
    __block struct seed_t seed = { { 0, 0, 0 } };
    
    __block NSMutableDictionary *dict;
    
    void (^blocks[])(void) = {
        ^{
            id key = [NSNumber numberWithInt: nrand48(seed.v) % 1024];
            id value = [NSNumber numberWithInt: nrand48(seed.v)];
            [dict setObject: value forKey: key];
        },
        ^{
            id key = [NSNumber numberWithInt: nrand48(seed.v) % 1024];
            [dict removeObjectForKey: key];
        }
    };
    
    for(int i = 0; i < 10000; i++)
    {
        NSUInteger index = nrand48(seed.v) % (sizeof(blocks) / sizeof(*blocks));
        void (^block)(void) = blocks[index];
        
        struct seed_t oldSeed = seed;
        dict = testDictionary;
        block();
        seed = oldSeed;
        dict = referenceDictionary;
        block();
        
        if(![testDictionary isEqual: referenceDictionary])
        {
            NSLog(@"Dictionaries are not equal: %@ %@", referenceDictionary, testDictionary);
            exit(1);
        }
    }
}

void MAMutableDictionaryTest(void)
{
//    Test([NSMutableDictionary dictionary]);
    Test([[[MAFixedMutableDictionary alloc] initWithSize: 10] autorelease]);
    Test([MAMutableDictionary dictionary]);
}
