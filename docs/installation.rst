Installing
**********
.. highlight:: bash


Building rocksdb
----------------

Briefly describes how to build rocksdb under an ordinary debian/ubuntu.
For more details consider https://github.com/facebook/rocksdb/blob/master/INSTALL.md

.. code-block:: bash

    apt-get install build-essential
    apt-get install libsnappy-dev zlib1g-dev libbz2-dev libgflags-dev
    git clone https://github.com/facebook/rocksdb.git
    cd rocksdb
    make shared_lib


Systemwide rocksdb
^^^^^^^^^^^^^^^^^^
The following command installs the shared library in ``/usr/lib/`` and the
header files in ``/usr/include/rocksdb/``::

    make install-shared INSTALL_PATH=/usr

To uninstall use::

    make uninstall INSTALL_PATH=/usr

Local rocksdb
^^^^^^^^^^^^^
If you don't like the system wide installation, or you don't have the
permissions, it is possible to set the following environment variables.
These varialbes are picked up by the compiler, linker and loader

.. code-block:: bash

    export CPLUS_INCLUDE_PATH=${CPLUS_INCLUDE_PATH}:`pwd`/include
    export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:`pwd`
    export LIBRARY_PATH=${LIBRARY_PATH}:`pwd`


Building pyrocksdb
------------------

.. code-block:: bash

    apt-get install python-virtualenv python-dev
    virtualenv pyrocks_test
    cd pyrocks_test
    . bin/active
    pip install "Cython>=0.20"
    pip install git+git://github.com/stephan-hof/pyrocksdb.git
