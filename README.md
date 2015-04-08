# pyrocksdb

Python bindings for RocksDB. See http://pyrocksdb.readthedocs.org for details

## How to install on Ubuntu 14.04

### Build rocksdb

    $ apt-get install build-essential libsnappy-dev zlib1g-dev libbz2-dev libgflags-dev cython
    $ git clone https://github.com/facebook/rocksdb.git
    $ cd rocksdb
    $ git checkout 1c47c433ba2c391dc0367edf16b3138afb3e8af1
    $ make shared_lib

If you do not want to call `make install` export the following enviroment variables:

    $ export CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}:`pwd`/include
    $ export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:`pwd`
    $ export LIBRARY_PATH=${LIBRARY_PATH}:`pwd`

### Build pyrocksdb

    $ apt-get install python-virtualenv python-dev
    $ virtualenv pyrocks_test
    $ cd pyrocks_test
    $ . bin/activate
    $ pip install git+git://github.com/balena/pyrocksdb.git
