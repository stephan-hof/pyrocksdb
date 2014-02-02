Welcome to pyrocksdb's documentation!
=====================================

Overview
--------
Python bindings to the C++ interface of http://rocksdb.org/ using cython::

    import rocksdb
    db = rocksdb.DB("test.db", rocksdb.Options(create_if_missing=True))
    db.put(b"a", b"b")
    print db.get(b"a")


Tested with python2.7 and python3.3 and RocksDB version 2.7.fb

.. toctree::
    :maxdepth: 2

    Instructions how to install <installation>
    Tutorial <tutorial/index>
    API <api/index>


Contributing
------------

Source can be found on `github <https://github.com/stephan-hof/pyrocksdb>`_.
Feel free to fork and send pull-requests or create issues on the
`github issue tracker <https://github.com/stephan-hof/pyrocksdb/issues>`_

RoadMap/TODO
------------

* wrap Backup/Restore https://github.com/facebook/rocksdb/wiki/How-to-backup-RocksDB%3F
* wrap DestroyDB
* wrap RepairDB
* Links from tutorial to API pages (for example merge operator)

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
