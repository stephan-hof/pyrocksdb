Welcome to pyrocksdb's documentation!
=====================================

Overview
--------
Python bindings to the C++ interface of http://rocksdb.org/ using cython::

    import rocksdb
    db = rocksdb.DB("test.db", rocksdb.Options(create_if_missing=True))
    db.put(b"a", b"b")
    print db.get(b"a")

Tested with python2.7 and python3.3

.. toctree::
    :maxdepth: 2

    Instructions how to install <installation>
    Tutorial <tutorial/index>
    API <api/index>


RoadMap/TODO
------------

* support prefix API
* Links from tutorial to API pages (for example merge operator)

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
