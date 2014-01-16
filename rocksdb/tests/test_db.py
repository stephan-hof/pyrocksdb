import os
import shutil
import gc
import unittest
import rocksdb


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
        self.assertIsNone(self.db.get('xxx'))

    def test_put_get(self):
        self.db.put("a", "b")
        self.assertEqual("b", self.db.get("a"))

    def test_multi_get(self):
        self.db.put("a", "1")
        self.db.put("b", "2")
        self.db.put("c", "3")

        ret = self.db.multi_get(['a', 'b', 'c'])
        ref = {'a': '1', 'c': '3', 'b': '2'}
        self.assertEqual(ref, ret)

    def test_delete(self):
        self.db.put("a", "b")
        self.assertEqual("b", self.db.get("a"))
        self.db.delete("a")
        self.assertIsNone(self.db.get("a"))

    def test_write_batch(self):
        batch = rocksdb.WriteBatch()
        batch.put("key", "v1")
        batch.delete("key")
        batch.put("key", "v2")
        batch.put("key", "v3")
        batch.put("a", "b")

        self.db.write(batch)
        ref = {'a': 'b', 'key': 'v3'}
        ret = self.db.multi_get(['key', 'a'])
        self.assertEqual(ref, ret)

    def test_key_may_exists(self):
        self.db.put("a", '1')

        self.assertEqual((False, None), self.db.key_may_exist("x"))
        self.assertEqual((False, None), self.db.key_may_exist('x', True))
        self.assertEqual((True, None), self.db.key_may_exist('a'))
        self.assertEqual((True, '1'), self.db.key_may_exist('a', True))

    def test_iter_keys(self):
        for x in range(300):
            self.db.put(str(x), str(x))

        it = self.db.iterkeys()

        self.assertEqual([], list(it))

        it.seek_to_last()
        self.assertEqual(['99'], list(it))

        ref = sorted([str(x) for x in range(300)])
        it.seek_to_first()
        self.assertEqual(ref, list(it))

        it.seek('90')
        ref = ['90', '91', '92', '93', '94', '95', '96', '97', '98', '99']
        self.assertEqual(ref, list(it))

    def test_iter_values(self):
        for x in range(300):
            self.db.put(str(x), str(x * 1000))

        it = self.db.itervalues()

        self.assertEqual([], list(it))

        it.seek_to_last()
        self.assertEqual(['99000'], list(it))

        ref = sorted([str(x) for x in range(300)])
        ref = [str(int(x) * 1000) for x in ref]
        it.seek_to_first()
        self.assertEqual(ref, list(it))

        it.seek('90')
        ref = [str(x * 1000) for x in range(90, 100)]
        self.assertEqual(ref, list(it))

    def test_iter_items(self):
        for x in range(300):
            self.db.put(str(x), str(x * 1000))

        it = self.db.iteritems()

        self.assertEqual([], list(it))

        it.seek_to_last()
        self.assertEqual([('99', '99000')], list(it))

        ref = sorted([str(x) for x in range(300)])
        ref = [(x, str(int(x) * 1000)) for x in ref]
        it.seek_to_first()
        self.assertEqual(ref, list(it))

        it.seek('90')
        ref = [(str(x), str(x * 1000)) for x in range(90, 100)]
        self.assertEqual(ref, list(it))

    def test_reverse_iter(self):
        for x in range(100):
            self.db.put(str(x), str(x * 1000))

        it = self.db.iteritems()
        it.seek_to_last()

        ref = reversed(sorted([str(x) for x in range(100)]))
        ref = [(x, str(int(x) * 1000)) for x in ref]

        self.assertEqual(ref, list(reversed(it)))

    def test_snapshot(self):
        self.db.put("a", "1")
        self.db.put("b", "2")

        snapshot = self.db.snapshot()
        self.db.put("a", "2")
        self.db.delete("b")

        it = self.db.iteritems()
        it.seek_to_first()
        self.assertEqual({'a': '2'}, dict(it))

        it = self.db.iteritems(snapshot=snapshot)
        it.seek_to_first()
        self.assertEqual({'a': '1', 'b': '2'}, dict(it))

    def test_get_property(self):
        for x in range(300):
            self.db.put(str(x), str(x))

        self.assertIsNotNone(self.db.get_property('rocksdb.stats'))
        self.assertIsNotNone(self.db.get_property('rocksdb.sstables'))
        self.assertIsNotNone(self.db.get_property('rocksdb.num-files-at-level0'))
        self.assertIsNone(self.db.get_property('does not exsits'))


class AssocCounter(rocksdb.interfaces.AssociativeMergeOperator):
    def merge(self, key, existing_value, value):
        if existing_value:
            return (True, str(int(existing_value) + int(value)))
        return (True, value)

    def name(self):
        return 'AssocCounter'


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
            self.db.merge("a", str(x))
        self.assertEqual(str(sum(range(1000))), self.db.get('a'))


class FullCounter(rocksdb.interfaces.MergeOperator):
    def name(self):
        return 'fullcounter'

    def full_merge(self, key, existing_value, operand_list):
        ret = sum([int(x) for x in operand_list])
        if existing_value:
            ret += int(existing_value)

        return (True, str(ret))

    def partial_merge(self, key, left, right):
        return (True, str(int(left) + int(right)))


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
            self.db.merge("a", str(x))
        self.assertEqual(str(sum(range(1000))), self.db.get('a'))


class SimpleComparator(rocksdb.interfaces.Comparator):
    def name(self):
        return 'mycompare'

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
            self.db.put(str(x), str(x))

        self.assertEqual('300', self.db.get('300'))
