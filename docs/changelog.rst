Changelog
*********

Version 0.3
-----------

Backward Incompatible Changes:
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Prefix Seeks:**

According to this page https://github.com/facebook/rocksdb/wiki/Prefix-Seek-API-Changes,
all the prefix related parameters on ``ReadOptions`` are removed.
Rocksdb realizes now if ``Options.prefix_extractor`` is set and uses then
prefix-seeks automatically. This means the following changes on pyrocksdb.

* DB.iterkeys, DB.itervalues, DB.iteritems have *no* ``prefix`` parameter anymore.
* DB.get, DB.multi_get, DB.key_may_exist, DB.iterkeys, DB.itervalues, DB.iteritems
  have *no* ``prefix_seek`` parameter anymore.

Which means all the iterators walk now always to the *end* of the database.
So if you need to stay within a prefix, write your own code to ensure that.
For DB.iterkeys and DB.iteritems ``itertools.takewhile`` is a possible solution. ::

    from itertools import takewhile

    it = self.db.iterkeys()
    it.seek(b'00002')
    print list(takewhile(lambda key: key.startswith(b'00002'), it))

    it = self.db.iteritems()
    it.seek(b'00002')
    print dict(takewhile(lambda item: item[0].startswith(b'00002'), it))

**SST Table Builders:**

* Removed ``NewTotalOrderPlainTableFactory``, because rocksdb drops it too.

**Changed Options:**

In newer versions of rocksdb a bunch of options were moved or removed.

* Rename ``bloom_bits_per_prefix`` of :py:class:`rocksdb.PlainTableFactory` to ``bloom_bits_per_key``
* Removed ``Options.db_stats_log_interval``.
* Removed ``Options.disable_seek_compaction``
* Moved ``Options.no_block_cache`` to ``BlockBasedTableFactory``
* Moved ``Options.block_size`` to ``BlockBasedTableFactory``
* Moved ``Options.block_size_deviation`` to ``BlockBasedTableFactory``
* Moved ``Options.block_restart_interval`` to ``BlockBasedTableFactory``
* Moved ``Options.whole_key_filtering`` to ``BlockBasedTableFactory``
* Removed ``Options.table_cache_remove_scan_count_limit``
* Removed rm_scan_count_limit from ``LRUCache``


New:
^^^^
* Make CompactRange available: :py:meth:`rocksdb.DB.compact_range`
* Add init options to :py:class:`rocksdb.BlockBasedTableFactory`
* Add more option to :py:class:`rocksdb.PlainTableFactory`
* Add :py:class:`rocksdb.WriteBatchIterator`


Version 0.2
-----------

This version works with RocksDB version 2.8.fb. Now you have access to the more
advanced options of rocksdb. Like changing the memtable or SST representation.
It is also possible now to enable *Universal Style Compaction*.

* Fixed `issue 3 <https://github.com/stephan-hof/pyrocksdb/pull/3>`_.
  Which fixed the change of prefix_extractor from raw-pointer to smart-pointer.

* Support the new :py:attr:`rocksdb.Options.verify_checksums_in_compaction` option.

* Add :py:attr:`rocksdb.Options.table_factory` option. So you could use the new
  'PlainTableFactories' which are optimized for in-memory-databases.

  * https://github.com/facebook/rocksdb/wiki/PlainTable-Format
  * https://github.com/facebook/rocksdb/wiki/How-to-persist-in-memory-RocksDB-database%3F

* Add :py:attr:`rocksdb.Options.memtable_factory` option.

* Add options :py:attr:`rocksdb.Options.compaction_style` and
  :py:attr:`rocksdb.Options.compaction_options_universal` to change the
  compaction style.

* Update documentation to the new default values

  * allow_mmap_reads=true
  * allow_mmap_writes=false
  * max_background_flushes=1
  * max_open_files=5000
  * paranoid_checks=true
  * disable_seek_compaction=true
  * level0_stop_writes_trigger=24
  * level0_slowdown_writes_trigger=20

* Document new property names for :py:meth:`rocksdb.DB.get_property`.

Version 0.1
-----------

Initial version. Works with rocksdb version 2.7.fb.
