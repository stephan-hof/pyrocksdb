Interfaces
**********

Comparator
==========

.. py:class:: rocksdb.interfaces.Comparator

    A Comparator object provides a total order across slices that are
    used as keys in an sstable or a database.  A Comparator implementation
    must be thread-safe since rocksdb may invoke its methods concurrently
    from multiple threads.

    .. py:method:: compare(a, b)

        Three-way comparison.

        :param bytes a: First field to compare
        :param bytes b: Second field to compare
        :returns: * -1 if a < b
                  * 0 if a == b
                  * 1 if a > b
        :rtype: ``int``

    .. py:method:: name()

        The name of the comparator.  Used to check for comparator
        mismatches (i.e., a DB created with one comparator is
        accessed using a different comparator).

        The client of this package should switch to a new name whenever
        the comparator implementation changes in a way that will cause
        the relative ordering of any two keys to change.

        Names starting with "rocksdb." are reserved and should not be used
        by any clients of this package.

        :rtype: ``bytes``

Merge Operator
==============

    Essentially, a MergeOperator specifies the SEMANTICS of a merge, which only
    client knows. It could be numeric addition, list append, string
    concatenation, edit data structure, whatever.
    The library, on the other hand, is concerned with the exercise of this
    interface, at the right time (during get, iteration, compaction...)

    To use merge, the client needs to provide an object implementing one of
    the following interfaces:

    * AssociativeMergeOperator - for most simple semantics (always take
      two values, and merge them into one value, which is then put back
      into rocksdb).
      numeric addition and string concatenation are examples.

    * MergeOperator - the generic class for all the more complex operations.
      One method (FullMerge) to merge a Put/Delete value with a merge operand.
      Another method (PartialMerge) that merges two operands together.
      This is especially useful if your key values have a complex structure but
      you would still like to support client-specific incremental updates.

    AssociativeMergeOperator is simpler to implement.
    MergeOperator is simply more powerful.

    See this page for more details
    https://github.com/facebook/rocksdb/wiki/Merge-Operator

AssociativeMergeOperator
------------------------

.. py:class:: rocksdb.interfaces.AssociativeMergeOperator

    .. py:method:: merge(key, existing_value, value)

        Gives the client a way to express the read -> modify -> write semantics

        :param bytes key: The key that's associated with this merge operation
        :param bytes existing_value: The current value in the db.
                                      ``None`` indicates the key does not exist
                                      before this op
        :param bytes value: The value to update/merge the existing_value with

        :returns: ``True`` and the new value on success.
                  All values passed in will be client-specific values.
                  So if this method returns false, it is because client
                  specified bad data or there was internal corruption.
                  The client should assume that this will be treated as an
                  error by the library.

        :rtype: ``(bool, bytes)``

    .. py:method:: name()

        The name of the MergeOperator. Used to check for MergeOperator mismatches.
        For example a DB created with one MergeOperator is accessed using a
        different MergeOperator.

        :rtype: ``bytes``

MergeOperator
-------------

.. py:class:: rocksdb.interfaces.MergeOperator

    .. py:method:: full_merge(key, existing_value, operand_list)

        Gives the client a way to express the read -> modify -> write semantics

        :param bytes key: The key that's associated with this merge operation.
                           Client could multiplex the merge operator based on it
                           if the key space is partitioned and different subspaces
                           refer to different types of data which have different
                           merge operation semantics

        :param bytes existing_value: The current value in the db.
                                     ``None`` indicates the key does not exist
                                     before this op

        :param operand_list: The sequence of merge operations to apply.
        :type operand_list: list of bytes 

        :returns: ``True`` and the new value on success.
                  All values passed in will be client-specific values.
                  So if this method returns false, it is because client
                  specified bad data or there was internal corruption.
                  The client should assume that this will be treated as an
                  error by the library.

        :rtype: ``(bool, bytes)``

    .. py:method:: partial_merge(key, left_operand, right_operand)

        This function performs merge(left_op, right_op)
        when both the operands are themselves merge operation types
        that you would have passed to a DB::Merge() call in the same order.
        For example DB::Merge(key,left_op), followed by DB::Merge(key,right_op)).

        PartialMerge should combine them into a single merge operation that is
        returned together with ``True``
        This new value should be constructed such that a call to
        DB::Merge(key, new_value) would yield the same result as a call
        to DB::Merge(key, left_op) followed by DB::Merge(key, right_op).

        If it is impossible or infeasible to combine the two operations,
        return ``(False, None)`` The library will internally keep track of the
        operations, and apply them in the correct order once a base-value
        (a Put/Delete/End-of-Database) is seen.

        :param bytes key: the key that is associated with this merge operation.
        :param bytes left_operand: First operand to merge
        :param bytes right_operand: Second operand to merge
        :rtype: ``(bool, bytes)``

        .. note::

            Presently there is no way to differentiate between error/corruption
            and simply "return false". For now, the client should simply return
            false in any case it cannot perform partial-merge, regardless of reason.
            If there is corruption in the data, handle it in the FullMerge() function,
            and return false there.

    .. py:method:: name()

        The name of the MergeOperator. Used to check for MergeOperator mismatches.
        For example a DB created with one MergeOperator is accessed using a
        different MergeOperator.

        :rtype: ``bytes``

FilterPolicy
============

.. py:class:: rocksdb.interfaces.FilterPolicy

    .. py:method:: create_filter(keys)

        Create a bytestring which can act as a filter for keys.

        :param keys: list of keys (potentially with duplicates)
                     that are ordered according to the user supplied
                     comparator. 
        :type keys: list of bytes

        :returns: A filter that summarizes keys
        :rtype: ``bytes``

    .. py:method:: key_may_match(key, filter)

        Check if the key is maybe in the filter. 

        :param bytes key: Key for a single entry inside the database
        :param bytes filter: Contains the data returned by a preceding call
                              to create_filter on this class
        :returns: This method must return ``True`` if the key was in the list
                  of keys passed to create_filter().
                  This method may return ``True`` or ``False`` if the key was
                  not on the list, but it should aim to return ``False`` with
                  a high probability.
        :rtype: ``bool``

                     
    .. py:method:: name()

        Return the name of this policy.  Note that if the filter encoding
        changes in an incompatible way, the name returned by this method
        must be changed.  Otherwise, old incompatible filters may be
        passed to methods of this type.

        :rtype: ``bytes``


SliceTransform
==============

.. py:class:: rocksdb.interfaces.SliceTransform

    SliceTransform is currently used to implement the 'prefix-API' of rocksdb.
    https://github.com/facebook/rocksdb/wiki/Proposal-for-prefix-API

    .. py:method:: transform(src)

        :param bytes src: Full key to extract the prefix from.

        :returns:  A tuple of two interges ``(offset, size)``.
                   Where the first integer is the offset within the ``src``
                   and the second the size of the prefix after the offset.
                   Which means the prefix is generted by ``src[offset:offset+size]``

        :rtype: ``(int, int)``


    .. py:method:: in_domain(src)

        Decide if a prefix can be extraced from ``src``.
        Only if this method returns ``True`` :py:meth:`transform` will be
        called.

        :param bytes src: Full key to check.
        :rtype: ``bool``

    .. py:method:: in_range(prefix)

        Checks if prefix is a valid prefix

        :param bytes prefix: Prefix to check.
        :returns: ``True`` if ``prefix`` is a valid prefix.
        :rtype: ``bool``

    .. py:method:: name()

        Return the name of this transformation.

        :rtype: ``bytes``
