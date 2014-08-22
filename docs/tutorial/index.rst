Basic Usage of pyrocksdb
************************

Open
====

The most basic open call is ::

    import rocksdb

    db = rocksdb.DB("test.db", rocksdb.Options(create_if_missing=True))

A more production ready open can look like this ::

    import rocksdb

    opts = rocksdb.Options()
    opts.create_if_missing = True
    opts.max_open_files = 300000
    opts.write_buffer_size = 67108864
    opts.max_write_buffer_number = 3
    opts.target_file_size_base = 67108864
    opts.filter_policy = rocksdb.BloomFilterPolicy(10)
    opts.block_cache = rocksdb.LRUCache(2 * (1024 ** 3))
    opts.block_cache_compressed = rocksdb.LRUCache(500 * (1024 ** 2))

    db = rocksdb.DB("test.db", opts)

It assings a cache of 2.5G, uses a bloom filter for faster lookups and keeps
more data (64 MB) in memory before writting a .sst file.

About Bytes And Unicode
========================

RocksDB stores all data as uninterpreted *byte strings*.
pyrocksdb behaves the same and uses nearly everywhere byte strings too.
In python2 this is the ``str`` type. In python3 the ``bytes`` type. 
Since the default string type for string literals differs between python 2 and 3,
it is strongly recommended to use an explicit ``b`` prefix for all byte string
literals in both python2 and python3 code.
For example ``b'this is a byte string'``. This avoids ambiguity and ensures
that your code keeps working as intended if you switch between python2 and python3.

The only place where you can pass unicode objects are filesytem paths like

* Directory name of the database itself :py:meth:`rocksdb.DB.__init__`

* :py:attr:`rocksdb.Options.wal_dir`

* :py:attr:`rocksdb.Options.db_log_dir`

To encode this path name, `sys.getfilesystemencoding()` encoding is used.

Access
======

Store, Get, Delete is straight forward ::

    # Store
    db.put(b"key", b"value")

    # Get
    db.get(b"key")

    # Delete
    db.delete(b"key")

It is also possible to gather modifications and
apply them in a single operation ::

    batch = rocksdb.WriteBatch()
    batch.put(b"key", b"v1")
    batch.delete(b"key")
    batch.put(b"key", b"v2")
    batch.put(b"key", b"v3")

    db.write(batch)

Fetch of multiple values at once ::

    db.put(b"key1", b"v1")
    db.put(b"key2", b"v2")

    ret = db.multi_get([b"key1", b"key2", b"key3"])

    # prints b"v1"
    print ret[b"key1"]

    # prints None
    print ret[b"key3"]

Iteration
=========

Iterators behave slightly different than expected. Per default they are not
valid. So you have to call one of its seek methods first ::

    db.put(b"key1", b"v1")
    db.put(b"key2", b"v2")
    db.put(b"key3", b"v3")

    it = db.iterkeys()
    it.seek_to_first()

    # prints [b'key1', b'key2', b'key3']
    print list(it)

    it.seek_to_last()
    # prints [b'key3']
    print list(it)

    it.seek(b'key2')
    # prints [b'key2', b'key3']
    print list(it)

There are also methods to iterate over values/items ::

    it = db.itervalues()
    it.seek_to_first()

    # prints [b'v1', b'v2', b'v3']
    print list(it)

    it = db.iteritems()
    it.seek_to_first()

    # prints [(b'key1', b'v1'), (b'key2, b'v2'), (b'key3', b'v3')]
    print list(it)

Reversed iteration ::

    it = db.iteritems()
    it.seek_to_last()

    # prints [(b'key3', b'v3'), (b'key2', b'v2'), (b'key1', b'v1')]
    print list(reversed(it))


Snapshots
=========

Snapshots are nice to get a consistent view on the database ::

    self.db.put(b"a", b"1")
    self.db.put(b"b", b"2")

    snapshot = self.db.snapshot()
    self.db.put(b"a", b"2")
    self.db.delete(b"b")

    it = self.db.iteritems()
    it.seek_to_first()

    # prints {b'a': b'2'}
    print dict(it)

    it = self.db.iteritems(snapshot=snapshot)
    it.seek_to_first()

    # prints {b'a': b'1', b'b': b'2'}
    print dict(it)


MergeOperator
=============

Merge operators are useful for efficient read-modify-write operations.
For more details see `Merge Operator <https://github.com/facebook/rocksdb/wiki/Merge-Operator>`_

A python merge operator must either implement the
:py:class:`rocksdb.interfaces.AssociativeMergeOperator` or
:py:class:`rocksdb.interfaces.MergeOperator` interface.

The following example python merge operator implements a counter ::

    class AssocCounter(rocksdb.interfaces.AssociativeMergeOperator):
        def merge(self, key, existing_value, value):
            if existing_value:
                s = int(existing_value) + int(value)
                return (True, str(s).encode('ascii'))
            return (True, value)

        def name(self):
            return b'AssocCounter'


    opts = rocksdb.Options()
    opts.create_if_missing = True
    opts.merge_operator = AssocCounter()
    db = rocksdb.DB('test.db', opts)

    db.merge(b"a", b"1")
    db.merge(b"a", b"1")

    # prints b'2'
    print db.get(b"a")

PrefixExtractor
===============

According to `Prefix API <https://github.com/facebook/rocksdb/wiki/Proposal-for-prefix-API>`_
a prefix_extractor can reduce IO for scans within a prefix range.
A python prefix extractor must implement the :py:class:`rocksdb.interfaces.SliceTransform` interface.

The following example presents a prefix extractor of a static size.
So always the first 5 bytes are used as the prefix ::

    class StaticPrefix(rocksdb.interfaces.SliceTransform):
        def name(self):
            return b'static'

        def transform(self, src):
            return (0, 5)

        def in_domain(self, src):
            return len(src) >= 5

        def in_range(self, dst):
            return len(dst) == 5

    opts = rocksdb.Options()
    opts.create_if_missing=True
    opts.prefix_extractor = StaticPrefix()

    db = rocksdb.DB('test.db', opts)

    db.put(b'00001.x', b'x')
    db.put(b'00001.y', b'y')
    db.put(b'00001.z', b'z')

    db.put(b'00002.x', b'x')
    db.put(b'00002.y', b'y')
    db.put(b'00002.z', b'z')

    db.put(b'00003.x', b'x')
    db.put(b'00003.y', b'y')
    db.put(b'00003.z', b'z')

    prefix = b'00002'

    it = db.iteritems()
    it.seek(prefix)

    # prints {b'00002.z': b'z', b'00002.y': b'y', b'00002.x': b'x'}
    print dict(itertools.takewhile(lambda item: item[0].startswith(prefix), it))


Backup And Restore
==================

Backup and Restore is done with a separate :py:class:`rocksdb.BackupEngine` object.

A backup can only be created on a living database object. ::

   import rocksdb

   db = rocksdb.DB("test.db", rocksdb.Options(create_if_missing=True))
   db.put(b'a', b'v1')
   db.put(b'b', b'v2')
   db.put(b'c', b'v3')

Backup is created like this.
You can choose any path for the backup destination except the db path itself.
If ``flush_before_backup`` is ``True`` the current memtable is flushed to disk
before backup. ::

    backup = rocksdb.BackupEngine("test.db/backups")
    backup.create_backup(db, flush_before_backup=True)

Restore is done like this.
The two arguments are the db_dir and wal_dir, which are mostly the same. ::

    backup = rocksdb.BackupEngine("test.db/backups")
    backup.restore_latest_backup("test.db", "test.db")


Change Memtable Or SST Implementations
======================================

As noted here :ref:`memtable_factories_label`, RocksDB offers different implementations for the memtable
representation. Per default :py:class:`rocksdb.SkipListMemtableFactory` is used,
but changing it to a different one is veary easy.

Here is an example for HashSkipList-MemtableFactory.
Keep in mind: To use the hashed based MemtableFactories you must set
:py:attr:`rocksdb.Options.prefix_extractor`.
In this example all keys have a static prefix of len 5. ::

    class StaticPrefix(rocksdb.interfaces.SliceTransform):
        def name(self):
            return b'static'

        def transform(self, src):
            return (0, 5)

        def in_domain(self, src):
            return len(src) >= 5

        def in_range(self, dst):
            return len(dst) == 5


    opts = rocksdb.Options()
    opts.prefix_extractor = StaticPrefix()
    opts.memtable_factory = rocksdb.HashSkipListMemtableFactory()
    opts.create_if_missing = True

    db = rocksdb.DB("test.db", opts)
    db.put(b'00001.x', b'x')
    db.put(b'00001.y', b'y')
    db.put(b'00002.x', b'x')

For initial bulk loads the Vector-MemtableFactory makes sense. ::

    opts = rocksdb.Options()
    opts.memtable_factory = rocksdb.VectorMemtableFactory()
    opts.create_if_missing = True

    db = rocksdb.DB("test.db", opts)

As noted here :ref:`table_factories_label`, it is also possible to change the
representation of the final data files.
Here is an example how to use a 'PlainTable'. ::

    opts = rocksdb.Options()
    opts.table_factory = rocksdb.PlainTableFactory()
    opts.create_if_missing = True

    db = rocksdb.DB("test.db", opts)

Change Compaction Style
=======================

RocksDB has a compaction algorithm called *universal*. This style typically
results in lower write amplification but higher space amplification than
Level Style Compaction. See here for more details,
https://github.com/facebook/rocksdb/wiki/Rocksdb-Architecture-Guide#multi-threaded-compactions

Here is an example to switch to *universal style compaction*. ::

    opts = rocksdb.Options()
    opts.compaction_style = "universal"
    opts.compaction_options_universal = {"min_merge_width": 3}

See here for more options on *universal style compaction*,
:py:attr:`rocksdb.Options.compaction_options_universal`
