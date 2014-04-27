Options creation
****************

Options object
==============


.. py:class:: rocksdb.Options

    .. IMPORTANT:: 

        The default values mentioned here, describe the values of the
        C++ library only.  This wrapper does not set any default value
        itself. So as soon as the rocksdb developers change a default value
        this document could be outdated. So if you really depend on a default
        value, double check it with the according version of the C++ library.

        | Most recent default values should be here
        | https://github.com/facebook/rocksdb/blob/master/include/rocksdb/options.h
        | https://github.com/facebook/rocksdb/blob/master/util/options.cc
        
    .. py:method:: __init__(**kwargs)

        All options mentioned below can also be passed as keyword-arguments in
        the constructor. For example::

            import rocksdb

            opts = rocksdb.Options(create_if_missing=True)
            # is the same as
            opts = rocksdb.Options()
            opts.create_if_missing = True


    .. py:attribute:: create_if_missing

        If ``True``, the database will be created if it is missing.

        | *Type:* ``bool``
        | *Default:* ``False``

    .. py:attribute:: error_if_exists

        If ``True``, an error is raised if the database already exists.

        | *Type:* ``bool``
        | *Default:* ``False``


    .. py:attribute:: paranoid_checks

        If ``True``, the implementation will do aggressive checking of the
        data it is processing and will stop early if it detects any
        errors.  This may have unforeseen ramifications: for example, a
        corruption of one DB entry may cause a large number of entries to
        become unreadable or for the entire DB to become unopenable.
        If any of the  writes to the database fails (Put, Delete, Merge, Write),
        the database will switch to read-only mode and fail all other
        Write operations.

        | *Type:* ``bool``
        | *Default:* ``True``

    .. py:attribute:: write_buffer_size

        Amount of data to build up in memory (backed by an unsorted log
        on disk) before converting to a sorted on-disk file.

        Larger values increase performance, especially during bulk loads.
        Up to max_write_buffer_number write buffers may be held in memory
        at the same time, so you may wish to adjust this parameter to control
        memory usage.  Also, a larger write buffer will result in a longer recovery
        time the next time the database is opened.

        | *Type:* ``int``
        | *Default:* ``4194304``

    .. py:attribute:: max_write_buffer_number

        The maximum number of write buffers that are built up in memory.
        The default is 2, so that when 1 write buffer is being flushed to
        storage, new writes can continue to the other write buffer.

        | *Type:* ``int``
        | *Default:* ``2``

    .. py:attribute:: min_write_buffer_number_to_merge

        The minimum number of write buffers that will be merged together
        before writing to storage.  If set to 1, then
        all write buffers are fushed to L0 as individual files and this increases
        read amplification because a get request has to check in all of these
        files. Also, an in-memory merge may result in writing lesser
        data to storage if there are duplicate records in each of these
        individual write buffers.

        | *Type:* ``int``
        | *Default:* ``1``

    .. py:attribute:: max_open_files

        Number of open files that can be used by the DB.  You may need to
        increase this if your database has a large working set. Value -1 means
        files opened are always kept open. You can estimate number of
        files based on target_file_size_base and target_file_size_multiplier
        for level-based compaction.
        For universal-style compaction, you can usually set it to -1.

        | *Type:* ``int``
        | *Default:* ``5000``

    .. py:attribute:: block_cache

        Control over blocks (user data is stored in a set of blocks, and
        a block is the unit of reading from disk).

        If not ``None`` use the specified cache for blocks.
        If ``None``, rocksdb will automatically create and use an 8MB internal cache.

        | *Type:* Instace of :py:class:`rocksdb.LRUCache`
        | *Default:* ``None``

    .. py:attribute:: block_cache_compressed

        If not ``None`` use the specified cache for compressed blocks.
        If ``None``, rocksdb will not use a compressed block cache.

        | *Type:* Instace of :py:class:`rocksdb.LRUCache`
        | *Default:* ``None``

    .. py:attribute:: block_size

        Approximate size of user data packed per block.  Note that the
        block size specified here corresponds to uncompressed data.  The
        actual size of the unit read from disk may be smaller if
        compression is enabled.  This parameter can be changed dynamically.
 
        | *Type:* ``int``
        | *Default:* ``4096``


    .. py:attribute:: block_restart_interval

        Number of keys between restart points for delta encoding of keys.
        This parameter can be changed dynamically.  Most clients should
        leave this parameter alone.
 
        | *Type:* ``int``
        | *Default:* ``16``

    .. py:attribute:: compression

        Compress blocks using the specified compression algorithm.
        This parameter can be changed dynamically.

        | *Type:* Member of :py:class:`rocksdb.CompressionType`
        | *Default:* :py:attr:`rocksdb.CompressionType.snappy_compression`

    .. py:attribute:: whole_key_filtering

        If ``True``, place whole keys in the filter (not just prefixes).
        This must generally be true for gets to be efficient.

        | *Type:* ``bool``
        | *Default:* ``True``


    .. py:attribute:: num_levels

        Number of levels for this database

        | *Type:* ``int``
        | *Default:* ``7``


    .. py:attribute:: level0_file_num_compaction_trigger

        Number of files to trigger level-0 compaction. A value <0 means that
        level-0 compaction will not be triggered by number of files at all.

        | *Type:* ``int``
        | *Default:* ``4``

    .. py:attribute:: level0_slowdown_writes_trigger

        Soft limit on number of level-0 files. We start slowing down writes at this
        point. A value <0 means that no writing slow down will be triggered by
        number of files in level-0.

        | *Type:* ``int``
        | *Default:* ``20``

    .. py:attribute:: level0_stop_writes_trigger

        Maximum number of level-0 files.  We stop writes at this point.

        | *Type:* ``int``
        | *Default:* ``24``

    .. py:attribute:: max_mem_compaction_level

        Maximum level to which a new compacted memtable is pushed if it
        does not create overlap.  We try to push to level 2 to avoid the
        relatively expensive level 0=>1 compactions and to avoid some
        expensive manifest file operations.  We do not push all the way to
        the largest level since that can generate a lot of wasted disk
        space if the same key space is being repeatedly overwritten.

        | *Type:* ``int``
        | *Default:* ``2``


    .. py:attribute:: target_file_size_base

        | Target file size for compaction.
        | target_file_size_base is per-file size for level-1.
        | Target file size for level L can be calculated by
        | target_file_size_base * (target_file_size_multiplier ^ (L-1)).

        For example, if target_file_size_base is 2MB and
        target_file_size_multiplier is 10, then each file on level-1 will
        be 2MB, and each file on level 2 will be 20MB,
        and each file on level-3 will be 200MB.

        | *Type:* ``int``
        | *Default:* ``2097152``

    .. py:attribute:: target_file_size_multiplier

        | by default target_file_size_multiplier is 1, which means
        | by default files in different levels will have similar size.

        | *Type:* ``int``
        | *Default:* ``1``

    .. py:attribute:: max_bytes_for_level_base

        Control maximum total data size for a level.
        *max_bytes_for_level_base* is the max total for level-1.
        Maximum number of bytes for level L can be calculated as
        (*max_bytes_for_level_base*) * (*max_bytes_for_level_multiplier* ^ (L-1))
        For example, if *max_bytes_for_level_base* is 20MB, and if
        *max_bytes_for_level_multiplier* is 10, total data size for level-1
        will be 20MB, total file size for level-2 will be 200MB,
        and total file size for level-3 will be 2GB.

        | *Type:* ``int``
        | *Default:* ``10485760``

    .. py:attribute:: max_bytes_for_level_multiplier

        See :py:attr:`max_bytes_for_level_base`

        | *Type:* ``int``
        | *Default:* ``10``

    .. py:attribute:: max_bytes_for_level_multiplier_additional

        Different max-size multipliers for different levels.
        These are multiplied by max_bytes_for_level_multiplier to arrive
        at the max-size of each level.

        | *Type:* ``[int]``
        | *Default:* ``[1, 1, 1, 1, 1, 1, 1]``

    .. py:attribute:: expanded_compaction_factor

        Maximum number of bytes in all compacted files. We avoid expanding
        the lower level file set of a compaction if it would make the
        total compaction cover more than
        (expanded_compaction_factor * targetFileSizeLevel()) many bytes.
        
        | *Type:* ``int``
        | *Default:* ``25``

    .. py:attribute:: source_compaction_factor

        Maximum number of bytes in all source files to be compacted in a
        single compaction run. We avoid picking too many files in the
        source level so that we do not exceed the total source bytes
        for compaction to exceed
        (source_compaction_factor * targetFileSizeLevel()) many bytes.
        If 1 pick maxfilesize amount of data as the source of
        a compaction.

        | *Type:* ``int``
        | *Default:* ``1``

    .. py:attribute:: max_grandparent_overlap_factor

        Control maximum bytes of overlaps in grandparent (i.e., level+2) before we
        stop building a single file in a level->level+1 compaction.

        | *Type:* ``int``
        | *Default:* ``10``

    .. py:attribute:: disable_data_sync

        If true, then the contents of data files are not synced
        to stable storage. Their contents remain in the OS buffers till the
        OS decides to flush them. This option is good for bulk-loading
        of data. Once the bulk-loading is complete, please issue a
        sync to the OS to flush all dirty buffesrs to stable storage.

        | *Type:* ``bool``
        | *Default:* ``False``

    .. py:attribute:: use_fsync

        If true, then every store to stable storage will issue a fsync.
        If false, then every store to stable storage will issue a fdatasync.
        This parameter should be set to true while storing data to
        filesystem like ext3 that can lose files after a reboot.

        | *Type:* ``bool``
        | *Default:* ``False``

    .. py:attribute:: db_stats_log_interval

        This number controls how often a new scribe log about
        db deploy stats is written out.
        -1 indicates no logging at all.

        | *Type:* ``int``
        | *Default:* ``1800``

    .. py:attribute:: db_log_dir

        This specifies the info LOG dir.
        If it is empty, the log files will be in the same dir as data.
        If it is non empty, the log files will be in the specified dir,
        and the db data dir's absolute path will be used as the log file
        name's prefix.

        | *Type:* ``unicode``
        | *Default:* ``""``

    .. py:attribute:: wal_dir

        This specifies the absolute dir path for write-ahead logs (WAL).
        If it is empty, the log files will be in the same dir as data,
        dbname is used as the data dir by default.
        If it is non empty, the log files will be in kept the specified dir.
        When destroying the db, all log files in wal_dir and the dir itself is deleted

        | *Type:* ``unicode``
        | *Default:* ``""``

    .. py:attribute:: disable_seek_compaction

        Disable compaction triggered by seek.
        With bloomfilter and fast storage, a miss on one level
        is very cheap if the file handle is cached in table cache
        (which is true if max_open_files is large).

        | *Type:* ``bool``
        | *Default:* ``True``

    .. py:attribute:: delete_obsolete_files_period_micros

        The periodicity when obsolete files get deleted. The default
        value is 6 hours. The files that get out of scope by compaction
        process will still get automatically delete on every compaction,
        regardless of this setting

        | *Type:* ``int``
        | *Default:* ``21600000000``

    .. py:attribute:: max_background_compactions

        Maximum number of concurrent background jobs, submitted to
        the default LOW priority thread pool

        | *Type:* ``int``
        | *Default:* ``1``

    .. py:attribute:: max_background_flushes

        Maximum number of concurrent background memtable flush jobs, submitted to
        the HIGH priority thread pool.
        By default, all background jobs (major compaction and memtable flush) go
        to the LOW priority pool. If this option is set to a positive number,
        memtable flush jobs will be submitted to the HIGH priority pool.
        It is important when the same Env is shared by multiple db instances.
        Without a separate pool, long running major compaction jobs could
        potentially block memtable flush jobs of other db instances, leading to
        unnecessary Put stalls.

        | *Type:* ``int``
        | *Default:* ``1``

    .. py:attribute:: max_log_file_size

        Specify the maximal size of the info log file. If the log file
        is larger than `max_log_file_size`, a new info log file will
        be created.
        If max_log_file_size == 0, all logs will be written to one
        log file.

        | *Type:* ``int``
        | *Default:* ``0``

    .. py:attribute:: log_file_time_to_roll

        Time for the info log file to roll (in seconds).
        If specified with non-zero value, log file will be rolled
        if it has been active longer than `log_file_time_to_roll`.
        A value of ``0`` means disabled.

        | *Type:* ``int``
        | *Default:* ``0``

    .. py:attribute:: keep_log_file_num

        Maximal info log files to be kept.

        | *Type:* ``int``
        | *Default:* ``1000``

    .. py:attribute:: soft_rate_limit

        Puts are delayed 0-1 ms when any level has a compaction score that exceeds
        soft_rate_limit. This is ignored when == 0.0.
        CONSTRAINT: soft_rate_limit <= hard_rate_limit. If this constraint does not
        hold, RocksDB will set soft_rate_limit = hard_rate_limit.
        A value of ``0`` means disabled.

        | *Type:* ``float``
        | *Default:* ``0``

    .. py:attribute:: hard_rate_limit

        Puts are delayed 1ms at a time when any level has a compaction score that
        exceeds hard_rate_limit. This is ignored when <= 1.0.
        A value fo ``0`` means disabled.

        | *Type:* ``float``
        | *Default:* ``0``

    .. py:attribute:: rate_limit_delay_max_milliseconds

        Max time a put will be stalled when hard_rate_limit is enforced. If 0, then
        there is no limit.

        | *Type:* ``int``
        | *Default:* ``1000``

    .. py:attribute:: max_manifest_file_size

        manifest file is rolled over on reaching this limit.
        The older manifest file be deleted.
        The default value is MAX_INT so that roll-over does not take place.

        | *Type:* ``int``
        | *Default:* ``(2**64) - 1``

    .. py:attribute:: no_block_cache

        Disable block cache. If this is set to true,
        then no block cache should be used, and the block_cache should
        point to ``None``

        | *Type:* ``bool``
        | *Default:* ``False``

    .. py:attribute:: table_cache_numshardbits

        Number of shards used for table cache.

        | *Type:* ``int``
        | *Default:* ``4``

    .. py:attribute:: table_cache_remove_scan_count_limit

        During data eviction of table's LRU cache, it would be inefficient
        to strictly follow LRU because this piece of memory will not really
        be released unless its refcount falls to zero. Instead, make two
        passes: the first pass will release items with refcount = 1,
        and if not enough space releases after scanning the number of
        elements specified by this parameter, we will remove items in LRU
        order.

        | *Type:* ``int``
        | *Default:* ``16``

    .. py:attribute:: arena_block_size

        size of one block in arena memory allocation.
        If <= 0, a proper value is automatically calculated (usually 1/10 of
        writer_buffer_size).
         
        | *Type:* ``int``
        | *Default:* ``0``

    .. py:attribute:: disable_auto_compactions

        Disable automatic compactions. Manual compactions can still
        be issued on this database.
         
        | *Type:* ``bool``
        | *Default:* ``False``

    .. py:attribute:: wal_ttl_seconds, wal_size_limit_mb

        The following two fields affect how archived logs will be deleted.

        1. If both set to 0, logs will be deleted asap and will not get into
           the archive.
        2. If wal_ttl_seconds is 0 and wal_size_limit_mb is not 0,
           WAL files will be checked every 10 min and if total size is greater
           then wal_size_limit_mb, they will be deleted starting with the
           earliest until size_limit is met. All empty files will be deleted.
        3. If wal_ttl_seconds is not 0 and wal_size_limit_mb is 0, then
           WAL files will be checked every wal_ttl_secondsi / 2 and those that
           are older than wal_ttl_seconds will be deleted.
        4. If both are not 0, WAL files will be checked every 10 min and both
           checks will be performed with ttl being first.

        | *Type:* ``int``
        | *Default:* ``0``

    .. py:attribute:: manifest_preallocation_size

        Number of bytes to preallocate (via fallocate) the manifest
        files.  Default is 4mb, which is reasonable to reduce random IO
        as well as prevent overallocation for mounts that preallocate
        large amounts of data (such as xfs's allocsize option).

        | *Type:* ``int``
        | *Default:* ``4194304``

    .. py:attribute:: purge_redundant_kvs_while_flush

        Purge duplicate/deleted keys when a memtable is flushed to storage.

        | *Type:* ``bool``
        | *Default:* ``True``

    .. py:attribute:: allow_os_buffer

        Data being read from file storage may be buffered in the OS

        | *Type:* ``bool``
        | *Default:* ``True``

    .. py:attribute:: allow_mmap_reads

        Allow the OS to mmap file for reading sst tables

        | *Type:* ``bool``
        | *Default:* ``True``

    .. py:attribute:: allow_mmap_writes

        Allow the OS to mmap file for writing

        | *Type:* ``bool``
        | *Default:* ``False``

    .. py:attribute:: is_fd_close_on_exec

        Disable child process inherit open files

        | *Type:* ``bool``
        | *Default:* ``True``

    .. py:attribute:: skip_log_error_on_recovery

        Skip log corruption error on recovery
        (If client is ok with losing most recent changes)
         
        | *Type:* ``bool``
        | *Default:* ``False``

    .. py:attribute:: stats_dump_period_sec

        If not zero, dump rocksdb.stats to LOG every stats_dump_period_sec

        | *Type:* ``int``
        | *Default:* ``3600``

    .. py:attribute:: block_size_deviation

        This is used to close a block before it reaches the configured
        'block_size'. If the percentage of free space in the current block is less
        than this specified number and adding a new record to the block will
        exceed the configured block size, then this block will be closed and the
        new record will be written to the next block.

        | *Type:* ``int``
        | *Default:* ``10``

    .. py:attribute:: advise_random_on_open

        If set true, will hint the underlying file system that the file
        access pattern is random, when a sst file is opened.

        | *Type:* ``bool``
        | *Default:* ``True``

    .. py:attribute:: use_adaptive_mutex

        Use adaptive mutex, which spins in the user space before resorting
        to kernel. This could reduce context switch when the mutex is not
        heavily contended. However, if the mutex is hot, we could end up
        wasting spin time.
         
        | *Type:* ``bool``
        | *Default:* ``False``

    .. py:attribute:: bytes_per_sync

        Allows OS to incrementally sync files to disk while they are being
        written, asynchronously, in the background.
        Issue one request for every bytes_per_sync written. 0 turns it off.
         
        | *Type:* ``int``
        | *Default:* ``0``

    .. py:attribute:: filter_deletes

        Use KeyMayExist API to filter deletes when this is true.
        If KeyMayExist returns false, i.e. the key definitely does not exist, then
        the delete is a noop. KeyMayExist only incurs in-memory look up.
        This optimization avoids writing the delete to storage when appropriate.
         
        | *Type:* ``bool``
        | *Default:* ``False``

    .. py:attribute:: max_sequential_skip_in_iterations

        An iteration->Next() sequentially skips over keys with the same
        user-key unless this option is set. This number specifies the number
        of keys (with the same userkey) that will be sequentially
        skipped before a reseek is issued.
         
        | *Type:* ``int``
        | *Default:* ``8``

    .. py:attribute:: inplace_update_support

        Allows thread-safe inplace updates. Requires Updates if

        * key exists in current memtable
        * new sizeof(new_value) <= sizeof(old_value)
        * old_value for that key is a put i.e. kTypeValue
 
        | *Type:* ``bool``
        | *Default:* ``False``

    .. py:attribute:: inplace_update_num_locks

        | Number of locks used for inplace update.
        | Default: 10000, if inplace_update_support = true, else 0.

        | *Type:* ``int``
        | *Default:* ``10000``

    .. py:attribute:: comparator

        Comparator used to define the order of keys in the table.
        A python comparator must implement the :py:class:`rocksdb.interfaces.Comparator`
        interface.

        *Requires*: The client must ensure that the comparator supplied
        here has the same name and orders keys *exactly* the same as the
        comparator provided to previous open calls on the same DB.

        *Default:* :py:class:`rocksdb.BytewiseComparator`

    .. py:attribute:: merge_operator

        The client must provide a merge operator if Merge operation
        needs to be accessed. Calling Merge on a DB without a merge operator
        would result in :py:exc:`rocksdb.errors.NotSupported`. The client must
        ensure that the merge operator supplied here has the same name and
        *exactly* the same semantics as the merge operator provided to
        previous open calls on the same DB. The only exception is reserved
        for upgrade, where a DB previously without a merge operator is
        introduced to Merge operation for the first time. It's necessary to
        specify a merge operator when openning the DB in this case.

        A python merge operator must implement the
        :py:class:`rocksdb.interfaces.MergeOperator` or
        :py:class:`rocksdb.interfaces.AssociativeMergeOperator`
        interface.
        
        *Default:* ``None``

    .. py:attribute:: filter_policy

        If not ``None`` use the specified filter policy to reduce disk reads.
        A python filter policy must implement the
        :py:class:`rocksdb.interfaces.FilterPolicy` interface.
        Recommendes is a instance of :py:class:`rocksdb.BloomFilterPolicy`

        *Default:* ``None``

    .. py:attribute:: prefix_extractor

        If not ``None``, use the specified function to determine the
        prefixes for keys. These prefixes will be placed in the filter.
        Depending on the workload, this can reduce the number of read-IOP
        cost for scans when a prefix is passed to the calls generating an
        iterator (:py:meth:`rocksdb.DB.iterkeys` ...).

        A python prefix_extractor must implement the
        :py:class:`rocksdb.interfaces.SliceTransform` interface

        For prefix filtering to work properly, "prefix_extractor" and "comparator"
        must be such that the following properties hold:

        1. ``key.starts_with(prefix(key))``
        2. ``compare(prefix(key), key) <= 0``
        3. ``If compare(k1, k2) <= 0, then compare(prefix(k1), prefix(k2)) <= 0``
        4. ``prefix(prefix(key)) == prefix(key)``

    *Default:* ``None``


CompressionTypes
================

.. py:class:: rocksdb.CompressionType

    Defines the support compression types

    .. py:attribute:: no_compression
    .. py:attribute:: snappy_compression
    .. py:attribute:: zlib_compression
    .. py:attribute:: bzip2_compression

BytewiseComparator
==================

.. py:class:: rocksdb.BytewiseComparator

    Wraps the rocksdb Bytewise Comparator, it uses lexicographic byte-wise
    ordering

BloomFilterPolicy
=================

.. py:class:: rocksdb.BloomFilterPolicy

    Wraps the rocksdb BloomFilter Policy

    .. py:method:: __init__(bits_per_key)

    :param int bits_per_key:
        Specifies the approximately number of bits per key.
        A good value for bits_per_key is 10, which yields a filter with
        ~ 1% false positive rate.


LRUCache
========

.. py:class:: rocksdb.LRUCache

    Wraps the rocksdb LRUCache

    .. py:method:: __init__(capacity, shard_bits=None, rm_scan_count_limit=None)

        Create a new cache with a fixed size capacity. The cache is sharded
        to 2^numShardBits shards, by hash of the key. The total capacity
        is divided and evenly assigned to each shard. Inside each shard,
        the eviction is done in two passes: first try to free spaces by
        evicting entries that are among the most least used removeScanCountLimit
        entries and do not have reference other than by the cache itself, in
        the least-used order. If not enough space is freed, further free the
        entries in least used order.

