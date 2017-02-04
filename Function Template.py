def point(self, x=1, y=2):
    r"""
    Return the point `(x^5,y)`.

    INPUT:

    - ``x`` -- integer (default: 1) the description of the
      argument ``x`` goes here.  If it contains multiple lines, all
      the lines after the first need to begin at the same indentation
      as the backtick.

    - ``y`` -- integer (default: 2) the ...

    OUTPUT:

    The point as a tuple.

    .. SEEALSO::

        :func:`line`

    EXAMPLES:

    This example illustrates ...

    ::

        sage: A = ModuliSpace()
        sage: A.point(2,3)
        xxx

    We now ...

    ::

        sage: B = A.point(5,6)
        sage: xxx

    It is an error to ...::

        sage: C = A.point('x',7)
        Traceback (most recent call last):
        ...
        TypeError: unable to convert 'r' to an integer

    .. NOTE::

        This function uses the algorithm of [BCDT2001]_ to determine
        whether an elliptic curve `E` over `Q` is modular.

    ...

    TESTS::

        sage: A.point(42, 0)  # Check for corner case y=0
        xxx
    """
    <body of the function>