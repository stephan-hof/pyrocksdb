Installing
**********
.. highlight:: bash


Building rocksdb
----------------

Briefly describes how to build rocksdb under a ordinary debian/ubuntu.
For more details consider https://github.com/facebook/rocksdb/blob/master/INSTALL.md::

    $ apt-get install build-essential
    $ apt-get install libsnappy-dev zlib1g-dev libbz2-dev libgflags-dev
    $ git clone https://github.com/facebook/rocksdb.git
    $ cd rocksdb
    $ # It is tested with this version
    $ git checkout ac2fe728327be75c8c289d4e3ebf8587d88c518d
    $ make librocksdb.so

If you do not want to call ``make install`` export the following enviroment
variables::

    $ export CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}:`pwd`/include
    $ export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:`pwd`
    $ export LIBRARY_PATH=${LIBRARY_PATH}:`pwd`

Building pyrocksdb
------------------

.. code-block:: bash

    $ apt-get install python-virtualenv python-dev
    $ virtualenv pyrocks_test
    $ cd pyrocks_test
    $ . bin/active
    $ pip install Cython
    $ pip install git+git://github.com/stephan-hof/pyrocksdb.git
