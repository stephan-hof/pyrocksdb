import os
import shutil
import gc
import unittest
import rocksdb

def int_to_bytes(ob):
    return str(ob).encode('ascii')

class TestHelper(object):
    def _clean(self):
        if os.path.exists('/tmp/test'):
            shutil.rmtree("/tmp/test")

    def _close_db(self):
        del self.db
        gc.collect()


class TestDB(unittest.TestCase, TestHelper):
    def setUp(self):
        opts = rocksdb.Options(create_if_missing=True)
        self._clean()
        self.db = rocksdb.DB("/tmp/test", opts)

    def tearDown(self):
        self._close_db()

    def test_unicode_path(self):
        name = b'/tmp/M\xc3\xbcnchen'.decode('utf8')
        rocksdb.DB(name, rocksdb.Options(create_if_missing=True))
        self.addCleanup(shutil.rmtree, name)
        self.assertTrue(os.path.isdir(name))

    def test_get_none(self):
        self.assertIsNone(self.db.get(b'xxx'))

    def test_put_get(self):
        self.db.put(b"a", b"b")
        self.assertEqual(b"b", self.db.get(b"a"))

    def test_multi_get(self):
        self.db.put(b"a", b"1")
        self.db.put(b"b", b"2")
        self.db.put(b"c", b"3")

        ret = self.db.multi_get([b'a', b'b', b'c'])
        ref = {b'a': b'1', b'c': b'3', b'b': b'2'}
        self.assertEqual(ref, ret)

    def test_delete(self):
        self.db.put(b"a", b"b")
        self.assertEqual(b"b", self.db.get(b"a"))
        self.db.delete(b"a")
        self.assertIsNone(self.db.get(b"a"))

    def test_write_batch(self):
        batch = rocksdb.WriteBatch()
        batch.put(b"key", b"v1")
        batch.delete(b"key")
        batch.put(b"key", b"v2")
        batch.put(b"key", b"v3")
        batch.put(b"a", b"b")

        self.db.write(batch)
        ref = {b'a': b'b', b'key': b'v3'}
        ret = self.db.multi_get([b'key', b'a'])
        self.assertEqual(ref, ret)

    def test_key_may_exists(self):
        self.db.put(b"a", b'1')

        self.assertEqual((False, None), self.db.key_may_exist(b"x"))
        self.assertEqual((False, None), self.db.key_may_exist(b'x', True))
        self.assertEqual((True, None), self.db.key_may_exist(b'a'))
        self.assertEqual((True, b'1'), self.db.key_may_exist(b'a', True))

    def test_iter_keys(self):
        for x in range(300):
            self.db.put(int_to_bytes(x), int_to_bytes(x))

        it = self.db.iterkeys()

        self.assertEqual([], list(it))

        it.seek_to_last()
        self.assertEqual([b'99'], list(it))

        ref = sorted([int_to_bytes(x) for x in range(300)])
        it.seek_to_first()
        self.assertEqual(ref, list(it))

        it.seek(b'90')
        ref = [
            b'90',
            b'91',
            b'92',
            b'93',
            b'94',
            b'95',
            b'96',
            b'97',
            b'98',
            b'99'
        ]
        self.assertEqual(ref, list(it))

    def test_iter_values(self):
        for x in range(300):
            self.db.put(int_to_bytes(x), int_to_bytes(x * 1000))

        it = self.db.itervalues()

        self.assertEqual([], list(it))

        it.seek_to_last()
        self.assertEqual([b'99000'], list(it))

        ref = sorted([int_to_bytes(x) for x in range(300)])
        ref = [int_to_bytes(int(x) * 1000) for x in ref]
        it.seek_to_first()
        self.assertEqual(ref, list(it))

        it.seek(b'90')
        ref = [int_to_bytes(x * 1000) for x in range(90, 100)]
        self.assertEqual(ref, list(it))

    def test_iter_items(self):
        for x in range(300):
            self.db.put(int_to_bytes(x), int_to_bytes(x * 1000))

        it = self.db.iteritems()

        self.assertEqual([], list(it))

        it.seek_to_last()
        self.assertEqual([(b'99', b'99000')], list(it))

        ref = sorted([int_to_bytes(x) for x in range(300)])
        ref = [(x, int_to_bytes(int(x) * 1000)) for x in ref]
        it.seek_to_first()
        self.assertEqual(ref, list(it))

        it.seek(b'90')
        ref = [(int_to_bytes(x), int_to_bytes(x * 1000)) for x in range(90, 100)]
        self.assertEqual(ref, list(it))

    def test_reverse_iter(self):
        for x in range(100):
            self.db.put(int_to_bytes(x), int_to_bytes(x * 1000))

        it = self.db.iteritems()
        it.seek_to_last()

        ref = reversed(sorted([int_to_bytes(x) for x in range(100)]))
        ref = [(x, int_to_bytes(int(x) * 1000)) for x in ref]

        self.assertEqual(ref, list(reversed(it)))

    def test_snapshot(self):
        self.db.put(b"a", b"1")
        self.db.put(b"b", b"2")

        snapshot = self.db.snapshot()
        self.db.put(b"a", b"2")
        self.db.delete(b"b")

        it = self.db.iteritems()
        it.seek_to_first()
        self.assertEqual({b'a': b'2'}, dict(it))

        it = self.db.iteritems(snapshot=snapshot)
        it.seek_to_first()
        self.assertEqual({b'a': b'1', b'b': b'2'}, dict(it))

    def test_get_property(self):
        for x in range(300):
            x = int_to_bytes(x)
            self.db.put(x, x)

        self.assertIsNotNone(self.db.get_property(b'rocksdb.stats'))
        self.assertIsNotNone(self.db.get_property(b'rocksdb.sstables'))
        self.assertIsNotNone(self.db.get_property(b'rocksdb.num-files-at-level0'))
        self.assertIsNone(self.db.get_property(b'does not exsits'))


class AssocCounter(rocksdb.interfaces.AssociativeMergeOperator):
    def merge(self, key, existing_value, value):
        if existing_value:
            return (True, int_to_bytes(int(existing_value) + int(value)))
        return (True, value)

    def name(self):
        return b'AssocCounter'


class TestAssocMerge(unittest.TestCase, TestHelper):
    def setUp(self):
        opts = rocksdb.Options()
        opts.create_if_missing = True
        opts.merge_operator = AssocCounter()
        self._clean()
        self.db = rocksdb.DB('/tmp/test', opts)

    def tearDown(self):
        self._close_db()

    def test_merge(self):
        for x in range(1000):
            self.db.merge(b"a", int_to_bytes(x))
        self.assertEqual(sum(range(1000)), int(self.db.get(b'a')))


class FullCounter(rocksdb.interfaces.MergeOperator):
    def name(self):
        return b'fullcounter'

    def full_merge(self, key, existing_value, operand_list):
        ret = sum([int(x) for x in operand_list])
        if existing_value:
            ret += int(existing_value)

        return (True, int_to_bytes(ret))

    def partial_merge(self, key, left, right):
        return (True, int_to_bytes(int(left) + int(right)))


class TestFullMerge(unittest.TestCase, TestHelper):
    def setUp(self):
        opts = rocksdb.Options()
        opts.create_if_missing = True
        opts.merge_operator = FullCounter()
        self._clean()
        self.db = rocksdb.DB('/tmp/test', opts)

    def tearDown(self):
        self._close_db()

    def test_merge(self):
        for x in range(1000):
            self.db.merge(b"a", int_to_bytes(x))
        self.assertEqual(sum(range(1000)), int(self.db.get(b'a')))


class SimpleComparator(rocksdb.interfaces.Comparator):
    def name(self):
        return b'mycompare'

    def compare(self, a, b):
        a = int(a)
        b = int(b)
        if a < b:
            return -1
        if a == b:
            return 0
        if a > b:
            return 1


class TestComparator(unittest.TestCase, TestHelper):
    def setUp(self):
        opts = rocksdb.Options()
        opts.create_if_missing = True
        opts.comparator = SimpleComparator()
        self._clean()
        self.db = rocksdb.DB('/tmp/test', opts)

    def tearDown(self):
        self._close_db()

    def test_compare(self):
        for x in range(1000):
            self.db.put(int_to_bytes(x), int_to_bytes(x))

        self.assertEqual(b'300', self.db.get(b'300'))
