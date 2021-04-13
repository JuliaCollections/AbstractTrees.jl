"""
    children(x)

Get the immediate children of node `x`.

This is the primary function that needs to be implemented for custom tree types. It should return an
iterable object for which an appropriate implementation of `Base.pairs` is available.

The default behavior is to assume that if an object is iterable, iterating over
it gives its children. Non-iterable types are treated as leaf nodes.
"""
children(x) = Base.isiterable(typeof(x)) ? x : ()
