import os
import shutil
import gc
import unittest
import rocksdb
from itertools import takewhile

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

    def test_options_used_twice(self):
        expected = "Options object is already used by another DB"
        with self.assertRaisesRegexp(Exception, expected):
            rocksdb.DB("/tmp/test2", self.db.options)

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

    def test_write_batch_iter(self):
        batch = rocksdb.WriteBatch()
        self.assertEqual([], list(batch))

        batch.put(b"key1", b"v1")
        batch.put(b"key2", b"v2")
        batch.put(b"key3", b"v3")
        batch.delete(b'a')
        batch.delete(b'key1')
        batch.merge(b'xxx', b'value')

        it = iter(batch)
        del batch
        ref = [
            ('Put', 'key1', 'v1'),
            ('Put', 'key2', 'v2'),
            ('Put', 'key3', 'v3'),
            ('Delete', 'a', ''),
            ('Delete', 'key1', ''),
            ('Merge', 'xxx', 'value')
        ]
        self.assertEqual(ref, list(it))


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

    def test_compact_range(self):
        for x in range(10000):
            x = int_to_bytes(x)
            self.db.put(x, x)

        self.db.compact_range()


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

class StaticPrefix(rocksdb.interfaces.SliceTransform):
    def name(self):
        return b'static'

    def transform(self, src):
        return (0, 5)

    def in_domain(self, src):
        return len(src) >= 5

    def in_range(self, dst):
        return len(dst) == 5

class TestPrefixExtractor(unittest.TestCase, TestHelper):
    def setUp(self):
        opts = rocksdb.Options(create_if_missing=True)
        opts.prefix_extractor = StaticPrefix()
        self._clean()
        self.db = rocksdb.DB('/tmp/test', opts)

    def tearDown(self):
        self._close_db()

    def _fill_db(self):
        for x in range(3000):
            keyx = hex(x)[2:].zfill(5).encode('utf8') + b'.x'
            keyy = hex(x)[2:].zfill(5).encode('utf8') + b'.y'
            keyz = hex(x)[2:].zfill(5).encode('utf8') + b'.z'
            self.db.put(keyx, b'x')
            self.db.put(keyy, b'y')
            self.db.put(keyz, b'z')


    def test_prefix_iterkeys(self):
        self._fill_db()
        self.assertEqual(b'x', self.db.get(b'00001.x'))
        self.assertEqual(b'y', self.db.get(b'00001.y'))
        self.assertEqual(b'z', self.db.get(b'00001.z'))

        it = self.db.iterkeys()
        it.seek(b'00002')

        ref = [b'00002.x', b'00002.y', b'00002.z']
        ret = takewhile(lambda key: key.startswith(b'00002'), it)
        self.assertEqual(ref, list(ret))

    def test_prefix_iteritems(self):
        self._fill_db()

        it = self.db.iteritems()
        it.seek(b'00002')

        ref = {b'00002.z': b'z', b'00002.y': b'y', b'00002.x': b'x'}
        ret = takewhile(lambda item: item[0].startswith(b'00002'), it)
        self.assertEqual(ref, dict(ret))
