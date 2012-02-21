// xcrun clang -framework Foundation main.m MAMutableArray.m MAMutableDictionary.m
#import <Foundation/Foundation.h>
#import "MAMutableArray.h"
#import "MAMutableDictionary.h"


int main(int argc, char **argv)
{
    @autoreleasepool
    {
        MAMutableArrayTest();
        MAMutableDictionaryTest();
    }
}
