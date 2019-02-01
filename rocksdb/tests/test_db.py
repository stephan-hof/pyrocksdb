import os
import sys
import shutil
import gc
import unittest
import rocksdb
from itertools import takewhile
import struct
import tempfile
from rocksdb.merge_operators import UintAddOperator, StringAppendOperator

def int_to_bytes(ob):
    return str(ob).encode('ascii')

class TestHelper(unittest.TestCase):

    def setUp(self):
        self.db_loc = tempfile.mkdtemp()
        self.addCleanup(self._close_db)

    def _close_db(self):
        del self.db
        gc.collect()
        if os.path.exists(self.db_loc):
            shutil.rmtree(self.db_loc)


class TestDB(TestHelper):
    def setUp(self):
        TestHelper.setUp(self)
        opts = rocksdb.Options(create_if_missing=True)
        self.db = rocksdb.DB(os.path.join(self.db_loc, "test"), opts)

    def test_options_used_twice(self):
        if sys.version_info[0] == 3:
            assertRaisesRegex = self.assertRaisesRegex
        else:
            assertRaisesRegex = self.assertRaisesRegexp
        expected = "Options object is already used by another DB"
        with assertRaisesRegex(Exception, expected):
            rocksdb.DB(os.path.join(self.db_loc, "test2"), self.db.options)

    def test_unicode_path(self):
        name = os.path.join(self.db_loc, b'M\xc3\xbcnchen'.decode('utf8'))
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
            ('Put', b'key1', b'v1'),
            ('Put', b'key2', b'v2'),
            ('Put', b'key3', b'v3'),
            ('Delete', b'a', b''),
            ('Delete', b'key1', b''),
            ('Merge', b'xxx', b'value')
        ]
        self.assertEqual(ref, list(it))


    def test_key_may_exists(self):
        self.db.put(b"a", b'1')

        self.assertEqual((False, None), self.db.key_may_exist(b"x"))
        self.assertEqual((False, None), self.db.key_may_exist(b'x', True))
        self.assertEqual((True, None), self.db.key_may_exist(b'a'))
        self.assertEqual((True, b'1'), self.db.key_may_exist(b'a', True))

    def test_seek_for_prev(self):
        self.db.put(b'a1', b'a1_value')
        self.db.put(b'a3', b'a3_value')
        self.db.put(b'b1', b'b1_value')
        self.db.put(b'b2', b'b2_value')
        self.db.put(b'c2', b'c2_value')
        self.db.put(b'c4', b'c4_value')

        self.assertEqual(self.db.get(b'a1'), b'a1_value')

        it = self.db.iterkeys()

        it.seek(b'a1')
        self.assertEqual(it.get(), b'a1')
        it.seek(b'a3')
        self.assertEqual(it.get(), b'a3')
        it.seek_for_prev(b'c4')
        self.assertEqual(it.get(), b'c4')
        it.seek_for_prev(b'c3')
        self.assertEqual(it.get(), b'c2')

        it = self.db.itervalues()
        it.seek(b'a1')
        self.assertEqual(it.get(), b'a1_value')
        it.seek(b'a3')
        self.assertEqual(it.get(), b'a3_value')
        it.seek_for_prev(b'c4')
        self.assertEqual(it.get(), b'c4_value')
        it.seek_for_prev(b'c3')
        self.assertEqual(it.get(), b'c2_value')

        it = self.db.iteritems()
        it.seek(b'a1')
        self.assertEqual(it.get(), (b'a1', b'a1_value'))
        it.seek(b'a3')
        self.assertEqual(it.get(), (b'a3', b'a3_value'))
        it.seek_for_prev(b'c4')
        self.assertEqual(it.get(), (b'c4', b'c4_value'))
        it.seek_for_prev(b'c3')
        self.assertEqual(it.get(), (b'c2', b'c2_value'))

        reverse_it = reversed(it)
        it.seek_for_prev(b'c3')
        self.assertEqual(it.get(), (b'c2', b'c2_value'))


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


class TestUint64Merge(TestHelper):
    def setUp(self):
        TestHelper.setUp(self)
        opts = rocksdb.Options()
        opts.create_if_missing = True
        opts.merge_operator = UintAddOperator()
        self.db = rocksdb.DB(os.path.join(self.db_loc, 'test'), opts)

    def test_merge(self):
        self.db.put(b'a', struct.pack('Q', 5566))
        for x in range(1000):
            self.db.merge(b"a", struct.pack('Q', x))
        self.assertEqual(5566 + sum(range(1000)), struct.unpack('Q', self.db.get(b'a'))[0])


#  class TestPutMerge(TestHelper):
    #  def setUp(self):
        #  TestHelper.setUp(self)
        #  opts = rocksdb.Options()
        #  opts.create_if_missing = True
        #  opts.merge_operator = "put"
        #  self.db = rocksdb.DB(os.path.join(self.db_loc, 'test'), opts)

    #  def test_merge(self):
        #  self.db.put(b'a', b'ccc')
        #  self.db.merge(b'a', b'ddd')
        #  self.assertEqual(self.db.get(b'a'), 'ddd')

#  class TestPutV1Merge(TestHelper):
    #  def setUp(self):
        #  TestHelper.setUp(self)
        #  opts = rocksdb.Options()
        #  opts.create_if_missing = True
        #  opts.merge_operator = "put_v1"
        #  self.db = rocksdb.DB(os.path.join(self.db_loc, 'test'), opts)

    #  def test_merge(self):
        #  self.db.put(b'a', b'ccc')
        #  self.db.merge(b'a', b'ddd')
        #  self.assertEqual(self.db.get(b'a'), 'ddd')

class TestStringAppendOperatorMerge(TestHelper):
    def setUp(self):
        TestHelper.setUp(self)
        opts = rocksdb.Options()
        opts.create_if_missing = True
        opts.merge_operator = StringAppendOperator()
        self.db = rocksdb.DB(os.path.join(self.db_loc, 'test'), opts)

    # NOTE(sileht): Raise "Corruption: Error: Could not perform merge." on PY3
    #@unittest.skipIf(sys.version_info[0] == 3,
    #                 "Unexpected behavior on PY3")
    def test_merge(self):
        self.db.put(b'a', b'ccc')
        self.db.merge(b'a', b'ddd')
        self.assertEqual(self.db.get(b'a'), b'ccc,ddd')

#  class TestStringMaxOperatorMerge(TestHelper):
    #  def setUp(self):
        #  TestHelper.setUp(self)
        #  opts = rocksdb.Options()
        #  opts.create_if_missing = True
        #  opts.merge_operator = "max"
        #  self.db = rocksdb.DB(os.path.join(self.db_loc, 'test'), opts)

    #  def test_merge(self):
        #  self.db.put(b'a', int_to_bytes(55))
        #  self.db.merge(b'a', int_to_bytes(56))
        #  self.assertEqual(int(self.db.get(b'a')), 56)


class TestAssocMerge(TestHelper):
    def setUp(self):
        TestHelper.setUp(self)
        opts = rocksdb.Options()
        opts.create_if_missing = True
        opts.merge_operator = AssocCounter()
        self.db = rocksdb.DB(os.path.join(self.db_loc, 'test'), opts)

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


class TestFullMerge(TestHelper):
    def setUp(self):
        TestHelper.setUp(self)
        opts = rocksdb.Options()
        opts.create_if_missing = True
        opts.merge_operator = FullCounter()
        self.db = rocksdb.DB(os.path.join(self.db_loc, 'test'), opts)

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


class TestComparator(TestHelper):
    def setUp(self):
        TestHelper.setUp(self)
        opts = rocksdb.Options()
        opts.create_if_missing = True
        opts.comparator = SimpleComparator()
        self.db = rocksdb.DB(os.path.join(self.db_loc, 'test'), opts)

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

class TestPrefixExtractor(TestHelper):
    def setUp(self):
        TestHelper.setUp(self)
        opts = rocksdb.Options(create_if_missing=True)
        opts.prefix_extractor = StaticPrefix()
        self.db = rocksdb.DB(os.path.join(self.db_loc, 'test'), opts)

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

class TestDBColumnFamilies(TestHelper):
    def setUp(self):
        TestHelper.setUp(self)
        opts = rocksdb.Options(create_if_missing=True)
        self.db = rocksdb.DB(
            os.path.join(self.db_loc, 'test'),
            opts,
        )

        self.cf_a = self.db.create_column_family(b'A', rocksdb.ColumnFamilyOptions())
        self.cf_b = self.db.create_column_family(b'B', rocksdb.ColumnFamilyOptions())

    def test_column_families(self):
        families = self.db.column_families
        names = [handle.name for handle in families]
        self.assertEqual([b'default', b'A', b'B'], names)
        for name in names:
            self.assertIn(self.db.get_column_family(name), families)

        self.assertEqual(
            names,
            rocksdb.list_column_families(
                os.path.join(self.db_loc, 'test'),
                rocksdb.Options(),
            )
        )

    def test_get_none(self):
        self.assertIsNone(self.db.get(b'k'))
        self.assertIsNone(self.db.get((self.cf_a, b'k')))
        self.assertIsNone(self.db.get((self.cf_b, b'k')))

    def test_put_get(self):
        key = (self.cf_a, b'k')
        self.db.put(key, b"v")
        self.assertEqual(b"v", self.db.get(key))
        self.assertIsNone(self.db.get(b"k"))
        self.assertIsNone(self.db.get((self.cf_b, b"k")))

    def test_multi_get(self):
        data = [
            (b'a', b'1default'),
            (b'b', b'2default'),
            (b'c', b'3default'),
            ((self.cf_a, b'a'), b'1a'),
            ((self.cf_a, b'b'), b'2a'),
            ((self.cf_a, b'c'), b'3a'),
            ((self.cf_b, b'a'), b'1b'),
            ((self.cf_b, b'b'), b'2b'),
            ((self.cf_b, b'c'), b'3b'),
        ]
        for value in data:
            self.db.put(*value)

        multi_get_lookup = [value[0] for value in data]

        ret = self.db.multi_get(multi_get_lookup)
        ref = {value[0]: value[1] for value in data}
        self.assertEqual(ref, ret)

    def test_delete(self):
        self.db.put((self.cf_a, b"a"), b"b")
        self.assertEqual(b"b", self.db.get((self.cf_a, b"a")))
        self.db.delete((self.cf_a, b"a"))
        self.assertIsNone(self.db.get((self.cf_a, b"a")))

    def test_write_batch(self):
        cfa = self.db.get_column_family(b"A")
        batch = rocksdb.WriteBatch()
        batch.put((cfa, b"key"), b"v1")
        batch.delete((self.cf_a, b"key"))
        batch.put((cfa, b"key"), b"v2")
        batch.put((cfa, b"key"), b"v3")
        batch.put((cfa, b"a"), b"1")
        batch.put((cfa, b"b"), b"2")

        self.db.write(batch)
        query = [(cfa, b"key"), (cfa, b"a"), (cfa, b"b")]
        ret = self.db.multi_get(query)

        self.assertEqual(b"v3", ret[query[0]])
        self.assertEqual(b"1", ret[query[1]])
        self.assertEqual(b"2", ret[query[2]])

    def test_key_may_exists(self):
        self.db.put((self.cf_a, b"a"), b'1')

        self.assertEqual(
            (False, None),
            self.db.key_may_exist((self.cf_a, b"x"))
        )
        self.assertEqual(
            (False, None),
            self.db.key_may_exist((self.cf_a, b'x'), fetch=True)
        )
        self.assertEqual(
            (True, None),
            self.db.key_may_exist((self.cf_a, b'a'))
        )
        self.assertEqual(
            (True, b'1'),
            self.db.key_may_exist((self.cf_a, b'a'), fetch=True)
        )

    def test_iter_keys(self):
        for x in range(300):
            self.db.put((self.cf_a, int_to_bytes(x)), int_to_bytes(x))

        it = self.db.iterkeys(self.cf_a)
        self.assertEqual([], list(it))

        it.seek_to_last()
        self.assertEqual([(self.cf_a, b'99')], list(it))

        ref = sorted([(self.cf_a, int_to_bytes(x)) for x in range(300)])
        it.seek_to_first()
        self.assertEqual(ref, list(it))

        it.seek(b'90')
        ref = sorted([(self.cf_a, int_to_bytes(x)) for x in range(90, 100)])
        self.assertEqual(ref, list(it))

    def test_iter_values(self):
        for x in range(300):
            self.db.put((self.cf_b, int_to_bytes(x)), int_to_bytes(x * 1000))

        it = self.db.itervalues(self.cf_b)
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
            self.db.put((self.cf_b, int_to_bytes(x)), int_to_bytes(x * 1000))

        it = self.db.iteritems(self.cf_b)
        self.assertEqual([], list(it))

        it.seek_to_last()
        self.assertEqual([((self.cf_b, b'99'), b'99000')], list(it))

        ref = sorted([int_to_bytes(x) for x in range(300)])
        ref = [((self.cf_b, x), int_to_bytes(int(x) * 1000)) for x in ref]
        it.seek_to_first()
        self.assertEqual(ref, list(it))

        it.seek(b'90')
        ref = [((self.cf_b, int_to_bytes(x)), int_to_bytes(x * 1000)) for x in range(90, 100)]
        self.assertEqual(ref, list(it))

    def test_reverse_iter(self):
        for x in range(100):
            self.db.put((self.cf_a, int_to_bytes(x)), int_to_bytes(x * 1000))

        it = self.db.iteritems(self.cf_a)
        it.seek_to_last()

        ref = reversed(sorted([(self.cf_a, int_to_bytes(x)) for x in range(100)]))
        ref = [(x, int_to_bytes(int(x[1]) * 1000)) for x in ref]

        self.assertEqual(ref, list(reversed(it)))

    def test_snapshot(self):
        cfa = self.db.get_column_family(b'A')
        self.db.put((cfa, b"a"), b"1")
        self.db.put((cfa, b"b"), b"2")

        snapshot = self.db.snapshot()
        self.db.put((cfa, b"a"), b"2")
        self.db.delete((cfa, b"b"))

        it = self.db.iteritems(cfa)
        it.seek_to_first()
        self.assertEqual({(cfa, b'a'): b'2'}, dict(it))

        it = self.db.iteritems(cfa, snapshot=snapshot)
        it.seek_to_first()
        self.assertEqual({(cfa, b'a'): b'1', (cfa, b'b'): b'2'}, dict(it))

    def test_get_property(self):
        for x in range(300):
            x = int_to_bytes(x)
            self.db.put((self.cf_a, x), x)

        self.assertEqual(b"300",
                         self.db.get_property(b'rocksdb.estimate-num-keys',
                                              self.cf_a))
        self.assertIsNone(self.db.get_property(b'does not exsits',
                                               self.cf_a))

    def test_compact_range(self):
        for x in range(10000):
            x = int_to_bytes(x)
            self.db.put((self.cf_b, x), x)

        self.db.compact_range(column_family=self.cf_b)

