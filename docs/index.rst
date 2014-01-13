Welcome to pyrocksdb's documentation!
=====================================

Overview
--------
Python bindings to the C++ interface of http://rocksdb.org/ using cython::

    import rocksdb
    db = rocksdb.DB("test.db", rocksdb.Options(create_if_missing=True))
    db.put("a", "b")
    print db.get("a")

Tested with python2.7

.. toctree::
    :maxdepth: 2

    Instructions how to install <installation>
    Tutorial <tutorial/index>
    API <api/index>


RoadMap/TODO
------------

* Links from tutorial to API pages (for example merge operator)
* support python3.3.
  Make it fix what kind of strings are allow.

  * Arbitrary ``unicode`` and then do some encoding/decoding, like
    `redis-driver <https://github.com/andymccurdy/redis-py/blob/2.8.0/redis/connection.py#L319>`_

  * Or just ASCII ``bytes`` and let the user handle unicode.

* support prefix API

Indices and tables
==================

* :ref:`genindex`
* :ref:`modindex`
* :ref:`search`
