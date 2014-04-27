Changelog
*********

Upcoming Version
----------------

Target is to work with the next version of rocksdb (2.8.fb)

* Fixed `issue 3 <https://github.com/stephan-hof/pyrocksdb/pull/3>`_.
  Which fixed the change of prefix_extractor from raw-pointer to smart-pointer.

* Support the new :py:attr:`rocksdb.Options.verify_checksums_in_compaction` option.

* Update documentation to the new default values

  * allow_mmap_reads=true
  * allow_mmap_writes=false
  * max_background_flushes=1
  * max_open_files=5000
  * paranoid_checks=true
  * disable_seek_compaction=true
  * level0_stop_writes_trigger=24
  * level0_slowdown_writes_trigger=20

* Document new property names for :py:meth:`rocksdb.DB.get_property`

* Add :py:attr:`rocksdb.Options.table_factory` option. So you could use the new
  'PlainTableFactories' which are optimized for in-memory-databases.

  * https://github.com/facebook/rocksdb/wiki/PlainTable-Format
  * https://github.com/facebook/rocksdb/wiki/How-to-persist-in-memory-RocksDB-database%3F

Version 0.1
-----------

Initial version. Works with rocksdb version 2.7.fb.
