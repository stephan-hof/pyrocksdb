Database interactions
*********************

Database object
===============

.. py:class:: rocksdb.DB

    .. py:method:: __init__(db_name, Options opts, read_only=False)

        :param unicode db_name:  Name of the database to open
        :param opts: Options for this specific database
        :type opts: :py:class:`rocksdb.Options`
        :param bool read_only: If ``True`` the database is opened read-only.
                               All DB calls which modify data will raise an
                               Exception.


    .. py:method:: put(key, value, sync=False, disable_wal=False)

        Set the database entry for "key" to "value".

        :param bytes key: Name for this entry
        :param bytes value: Data for this entry
        :param bool sync: 
            If ``True``, the write will be flushed from the operating system
            buffer cache (by calling WritableFile::Sync()) before the write
            is considered complete.  If this flag is true, writes will be
            slower.

            If this flag is ``False``, and the machine crashes, some recent
            writes may be lost.  Note that if it is just the process that
            crashes (i.e., the machine does not reboot), no writes will be
            lost even if ``sync == False``.

            In other words, a DB write with ``sync == False`` has similar
            crash semantics as the "write()" system call.  A DB write
            with ``sync == True`` has similar crash semantics to a "write()"
            system call followed by "fdatasync()".

        :param bool disable_wal:
            If ``True``, writes will not first go to the write ahead log,
            and the write may got lost after a crash.

    .. py:method:: delete(key, sync=False, disable_wal=False)

        Remove the database entry for "key".

        :param bytes key: Name to delete
        :param sync: See :py:meth:`rocksdb.DB.put`
        :param disable_wal: See :py:meth:`rocksdb.DB.put`
        :raises rocksdb.errors.NotFound: If the key did not exists

    .. py:method:: merge(key, value, sync=False, disable_wal=False)

        Merge the database entry for "key" with "value".
        The semantics of this operation is determined by the user provided
        merge_operator when opening DB.

        See :py:meth:`rocksdb.DB.put` for the parameters

        :raises:
            :py:exc:`rocksdb.errors.NotSupported` if this is called and
            no :py:attr:`rocksdb.Options.merge_operator` was set at creation


    .. py:method:: write(batch, sync=False, disable_wal=False)

        Apply the specified updates to the database.

        :param rocksdb.WriteBatch batch: Batch to apply
        :param sync: See :py:meth:`rocksdb.DB.put`
        :param disable_wal: See :py:meth:`rocksdb.DB.put`

    .. py:method:: get(key, verify_checksums=False, fill_cache=True, prefix_seek=False, snapshot=None, read_tier="all")

        :param bytes key: Name to get

        :param bool verify_checksums: 
            If ``True``, all data read from underlying storage will be
            verified against corresponding checksums.

        :param bool fill_cache:
                Should the "data block", "index block" or "filter block"
                read for this iteration be cached in memory?
                Callers may wish to set this field to ``False`` for bulk scans.
        
        :param bool prefix_seek:
                If this option is set and memtable implementation allows.
                Seek might only return keys with the same prefix as the seek-key

        :param snapshot:
            If not ``None``, read as of the supplied snapshot
            (which must belong to the DB that is being read and which must
            not have been released). Is it ``None`` a implicit snapshot of the
            state at the beginning of this read operation is used
        :type snapshot: :py:class:`rocksdb.Snapshot`

        :param string read_tier:
            Specify if this read request should process data that ALREADY
            resides on a particular cache. If the required data is not
            found at the specified cache,
            then :py:exc:`rocksdb.errors.Incomplete` is raised.

            | Use ``all`` if a fetch from disk is allowed.
            | Use ``cache`` if only data from cache is allowed.
 
        :returns: ``None`` if not found, else the value for this key

    .. py:method:: multi_get(keys, verify_checksums=False, fill_cache=True, prefix_seek=False, snapshot=None, read_tier="all")

        :param keys: Keys to fetch
        :type keys: list of bytes

        For the other params see :py:meth:`rocksdb.DB.get`

        :returns:
            A ``dict`` where the value is either ``bytes`` or ``None`` if not found

        :raises: If the fetch for a single key fails
        
        .. note::
            keys will not be "de-duplicated".
            Duplicate keys will return duplicate values in order.

    .. py:method:: key_may_exist(key, fetch=False, verify_checksums=False, fill_cache=True, prefix_seek=False, snapshot=None, read_tier="all")

        If the key definitely does not exist in the database, then this method
        returns ``False``, else ``True``. If the caller wants to obtain value
        when the key is found in memory, fetch should be set to ``True``.
        This check is potentially lighter-weight than invoking DB::get().
        One way to make this lighter weight is to avoid doing any IOs.

        :param bytes key: Key to check
        :param bool fetch: Obtain also the value if found

        For the other params see :py:meth:`rocksdb.DB.get`

        :returns: 
            * ``(True, None)`` if key is found but value not in memory
            * ``(True, None)`` if key is found and ``fetch=False``
            * ``(True, <data>)`` if key is found and value in memory and ``fetch=True``
            * ``(False, None)`` if key is not found

    .. py:method:: iterkeys(prefix=None, fetch=False, verify_checksums=False, fill_cache=True, prefix_seek=False, snapshot=None, read_tier="all")

        Iterate over the keys

        :param bytes prefix: Not implemented yet

        For other params see :py:meth:`rocksdb.DB.get`

        :returns:
            A iterator object which is not valid yet.
            Call first one of the seek methods of the iterator to position it

        :rtype: :py:class:`rocksdb.BaseIterator`

    .. py:method:: itervalues(prefix=None, fetch=False, verify_checksums=False, fill_cache=True, prefix_seek=False, snapshot=None, read_tier="all")

        Iterate over the values

        :param bytes prefix: Not implemented yet

        For other params see :py:meth:`rocksdb.DB.get`

        :returns:
            A iterator object which is not valid yet.
            Call first one of the seek methods of the iterator to position it

        :rtype: :py:class:`rocksdb.BaseIterator`

    .. py:method:: iteritems(prefix=None, fetch=False, verify_checksums=False, fill_cache=True, prefix_seek=False, snapshot=None, read_tier="all")

        Iterate over the items

        :param bytes prefix: Not implemented yet

        For other params see :py:meth:`rocksdb.DB.get`

        :returns:
            A iterator object which is not valid yet.
            Call first one of the seek methods of the iterator to position it

        :rtype: :py:class:`rocksdb.BaseIterator`

    .. py:method:: snapshot()
    
        Return a handle to the current DB state.
        Iterators created with this handle will all observe a stable snapshot
        of the current DB state.
        
        :rtype: :py:class:`rocksdb.Snapshot`


    .. py:method:: get_property(prop)

        DB implementations can export properties about their state
        via this method. If "property" is a valid property understood by this
        DB implementation, a byte string with its value is returned.
        Otherwise ``None``
        
        Valid property names include:
        
        * ``b"rocksdb.num-files-at-level<N>"``: return the number of files at level <N>,
            where <N> is an ASCII representation of a level number (e.g. "0").

        * ``b"rocksdb.stats"``: returns a multi-line byte string that describes statistics
            about the internal operation of the DB.

        * ``b"rocksdb.sstables"``: returns a multi-line byte string that describes all
            of the sstables that make up the db contents.

        * ``b"rocksdb.num-immutable-mem-table"``: Number of immutable mem tables.

        * ``b"rocksdb.mem-table-flush-pending"``: Returns ``1`` if mem table flush is pending, otherwise ``0``.

        * ``b"rocksdb.compaction-pending"``:  Returns ``1`` if a compaction is pending, otherweise ``0``.

        * ``b"rocksdb.background-errors"``: Returns accumulated background errors encountered.

        * ``b"rocksdb.cur-size-active-mem-table"``: Returns current size of the active memtable.

    .. py:method:: get_live_files_metadata()

        Returns a list of all table files.

        It returns a list of dict's were each dict has the following keys.

        ``name``
            Name of the file

        ``level``
            Level at which this file resides

        ``size``
            File size in bytes

        ``smallestkey``
            Smallest user defined key in the file

        ``largestkey``
            Largest user defined key in the file

        ``smallest_seqno``
            smallest seqno in file

        ``largest_seqno``
            largest seqno in file
        
    .. py:attribute:: options

        Returns the associated :py:class:`rocksdb.Options` instance.

        .. note::

            Changes to this object have no effect anymore.
            Consider this as read-only

Iterator
========

.. py:class:: rocksdb.BaseIterator

    Base class for all iterators in this module. After creation a iterator is
    invalid. Call one of the seek methods first before starting iteration

    .. py:method:: seek_to_first()

            Position at the first key in the source

    .. py:method:: seek_to_last()
    
            Position at the last key in the source

    .. py:method:: seek(key)
    
        :param bytes key: Position at the first key in the source that at or past
 
    Methods to support the python iterator protocol

    .. py:method:: __iter__()
    .. py:method:: __next__()
    .. py:method:: __reversed__()

Snapshot
========

.. py:class:: rocksdb.Snapshot

    Opaque handler for a single Snapshot.
    Snapshot is released if nobody holds a reference on it.
    Retrieved via :py:meth:`rocksdb.DB.snapshot`

WriteBatch
==========

.. py:class:: rocksdb.WriteBatch

     WriteBatch holds a collection of updates to apply atomically to a DB.

     The updates are applied in the order in which they are added
     to the WriteBatch.  For example, the value of "key" will be "v3"
     after the following batch is written::
     
        batch = rocksdb.WriteBatch()
        batch.put(b"key", b"v1")
        batch.delete(b"key")
        batch.put(b"key", b"v2")
        batch.put(b"key", b"v3")

    .. py:method:: __init__(data=None)

        Creates a WriteBatch.

        :param bytes data:
            A serialized version of a previous WriteBatch. As retrieved
            from a previous .data() call. If ``None`` a empty WriteBatch is
            generated

    .. py:method:: put(key, value)
    
        Store the mapping "key->value" in the database.

        :param bytes key: Name of the entry to store
        :param bytes value: Data of this entry

    .. py:method:: merge(key, value)
    
        Merge "value" with the existing value of "key" in the database.

        :param bytes key: Name of the entry to merge
        :param bytes value: Data to merge

    .. py:method:: delete(key)
 
        If the database contains a mapping for "key", erase it.  Else do nothing.

        :param bytes key: Key to erase

    .. py:method:: clear()

        Clear all updates buffered in this batch.

    .. py:method:: data()

        Retrieve the serialized version of this batch.

        :rtype: ``bytes``

    .. py:method:: count()
    
        Returns the number of updates in the batch

        :rtype: int

Errors
======

.. py:exception:: rocksdb.errors.NotFound
.. py:exception:: rocksdb.errors.Corruption
.. py:exception:: rocksdb.errors.NotSupported
.. py:exception:: rocksdb.errors.InvalidArgument
.. py:exception:: rocksdb.errors.RocksIOError
.. py:exception:: rocksdb.errors.MergeInProgress
.. py:exception:: rocksdb.errors.Incomplete


