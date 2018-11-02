# content of test_sample.py
import rocksdb
import pytest
import shutil
import os
import tempfile

def test_open_skiplist_memtable_factory():
    opts = rocksdb.Options()
    opts.memtable_factory = rocksdb.SkipListMemtableFactory()
    opts.create_if_missing = True

    loc = tempfile.mkdtemp()
    try:
        test_db = rocksdb.DB(os.path.join(loc, "test"), opts)
    finally:
        shutil.rmtree(loc)


def test_open_vector_memtable_factory():
    opts = rocksdb.Options()
    opts.allow_concurrent_memtable_write = False
    opts.memtable_factory = rocksdb.VectorMemtableFactory()
    opts.create_if_missing = True
    loc = tempfile.mkdtemp()
    try:
        test_db = rocksdb.DB(os.path.join(loc, "test"), opts)
    finally:
        shutil.rmtree(loc)
