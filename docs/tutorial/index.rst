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
more data (64 MB) in memory before writting a .sst file

About bytes and unicode
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

To encode this unicode objects the `sys.getfilesystemencoding()` encoding is used


Access
======

Store, Get, Delete is straight forward ::

    # Store
    db.put("key", "value")

    # Get
    db.get("key")

    # Delete
    db.delete("key")

It is also possible to gather modifications and
apply them in a single operation ::

    batch = rocksdb.WriteBatch()
    batch.put("key", "v1")
    batch.delete("key")
    batch.put("key", "v2")
    batch.put("key", "v3")

    db.write(batch)

Fetch of multiple values at once ::

    db.put("key1", "v1")
    db.put("key2", "v2")

    ret = db.multi_get(["key1", "key2", "key3"])

    # prints "v1"
    print ret["key1"]

    # prints None
    print ret["key3"]

Iteration
=========

Iterators behave slightly different than expected. Per default they are not
valid. So you have to call one of its seek methods first ::

    db.put("key1", "v1")
    db.put("key2", "v2")
    db.put("key3", "v3")

    it = db.iterkeys()
    it.seek_to_first()

    # prints ['key1', 'key2', 'key3']
    print list(it)

    it.seek_to_last()
    # prints ['key3']
    print list(it)

    it.seek('key2')
    # prints ['key2', 'key3']
    print list(it)

There are also methods to iterate over values/items ::

    it = db.itervalues()
    it.seek_to_first()

    # prints ['v1', 'v2', 'v3']
    print list(it)

    it = db.iteritems()
    it.seek_to_first()

    # prints [('key1', 'v1'), ('key2, 'v2'), ('key3', 'v3')]
    print list(it)

Reversed iteration ::

    it = db.iteritems()
    it.seek_to_last()

    # prints [('key3', 'v3'), ('key2', 'v2'), ('key1', 'v1')]
    print list(reversed(it))


Snapshots
=========

Snapshots are nice to get a consistent view on the database ::

    self.db.put("a", "1")
    self.db.put("b", "2")

    snapshot = self.db.snapshot()
    self.db.put("a", "2")
    self.db.delete("b")

    it = self.db.iteritems()
    it.seek_to_first()

    # prints {'a': '2'}
    print dict(it)

    it = self.db.iteritems(snapshot=snapshot)
    it.seek_to_first()

    # prints {'a': '1', 'b': '2'}
    print dict(it)


MergeOperator
=============

Merge operators are useful for efficient read-modify-write operations.

The simple Associative merge ::

    class AssocCounter(rocksdb.interfaces.AssociativeMergeOperator):
        def merge(self, key, existing_value, value):
            if existing_value:
                return (True, str(int(existing_value) + int(value)))
            return (True, value)

        def name(self):
            return 'AssocCounter'


    opts = rocksdb.Options()
    opts.create_if_missing = True
    opts.merge_operator = AssocCounter()
    db = rocksdb.DB('test.db', opts)

    db.merge("a", "1")
    db.merge("a", "1")

    # prints '2'
    print db.get("a")
