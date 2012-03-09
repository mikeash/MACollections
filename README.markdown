These are sample implementations of `NSMutableArray` and `NSMutableDictionary`. They do not rely on existing concrete implementations, but are instead "from scratch" in that they implement an array/hash table directly with more primitive constructs.

These are primarily intended for educational purposes. The `MAMutableArray` implementation is discussed here:

http://mikeash.com/pyblog/friday-qa-2012-03-09-lets-build-nsmutablearray.html

A discussion of `MAMutableDictionary` is forthcoming.

These may well be useful as actual code, though. I believe the unit tests are quite thorough and should demonstrate that they are solid enough to use in real apps. They could come in handy if you need some customizable behavior that's difficult to add on to the framework implementations. (One good example would be adding weak reference support to `MAMutableDictionary`, which would be easy to do but is really hard to add into a standard `NSMutableDictionary`.)

If you want to use it, the code is public domain and can be used however you like. Credit is preferred but not required. For more information, see the LICENSE file.