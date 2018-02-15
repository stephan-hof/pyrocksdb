Note
=========
The original pyrocksdb (https://pypi.python.org/pypi/pyrocksdb/0.4) has not been updated for long time. I update pyrocksdb to support the latest rocksdb. Please open issues in github if you have any problem.


pyrocksdb
=========

Python bindings for RocksDB.
See http://python-rocksdb.readthedocs.io/en/latest/ for a more comprehensive install and usage description.


Quick Install
-------------

Quick install for debian/ubuntu like linux distributions.

.. code-block:: bash

    $ apt-get install build-essential libsnappy-dev zlib1g-dev libbz2-dev libgflags-dev
    $ git clone https://github.com/facebook/rocksdb.git
    $ cd rocksdb
    $ mkdir build && cd build
    $ cmake ..
    $ make
    $ export CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}:`pwd`/../include
    $ export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:`pwd`
    $ export LIBRARY_PATH=${LIBRARY_PATH}:`pwd`

    $ cd ../
    $ apt-get install python-virtualenv python-dev
    $ virtualenv pyrocks_test
    $ cd pyrocks_test
    $ . bin/active
    $ pip install python-rocksdb


Quick Usage Guide
-----------------

.. code-block:: pycon

    >>> import rocksdb
    >>> db = rocksdb.DB("test.db", rocksdb.Options(create_if_missing=True))
    >>> db.put(b'a', b'data')
    >>> print db.get(b'a')
    b'data'
