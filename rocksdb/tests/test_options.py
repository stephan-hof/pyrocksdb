import unittest
import rocksdb

class TestFilterPolicy(rocksdb.interfaces.FilterPolicy):
    def create_filter(self, keys):
        return b'nix'

    def key_may_match(self, key, fil):
        return True

    def name(self):
        return b'testfilter'

class TestMergeOperator(rocksdb.interfaces.MergeOperator):
    def full_merge(self, *args, **kwargs):
        return (False, None)

    def partial_merge(self, *args, **kwargs):
        return (False, None)

    def name(self):
        return b'testmergeop'

class TestOptions(unittest.TestCase):
    def test_simple(self):
        opts = rocksdb.Options()
        self.assertEqual(True, opts.paranoid_checks)
        opts.paranoid_checks = False
        self.assertEqual(False, opts.paranoid_checks)

        self.assertIsNone(opts.merge_operator)
        ob = TestMergeOperator()
        opts.merge_operator = ob
        self.assertEqual(opts.merge_operator, ob)

        self.assertIsInstance(
            opts.comparator,
            rocksdb.BytewiseComparator)

        self.assertEqual('snappy_compression', opts.compression)
        opts.compression = rocksdb.CompressionType.no_compression
        self.assertEqual('no_compression', opts.compression)

    def test_block_options(self):
        rocksdb.BlockBasedTableFactory(
            block_size=4096,
            filter_policy=TestFilterPolicy(),
            block_cache=rocksdb.LRUCache(100))

    def test_unicode_path(self):
        name = b'/tmp/M\xc3\xbcnchen'.decode('utf8')
        opts = rocksdb.Options()
        opts.db_log_dir = name
        opts.wal_dir = name

        self.assertEqual(name, opts.db_log_dir)
        self.assertEqual(name, opts.wal_dir)

    def test_table_factory(self):
        opts = rocksdb.Options()
        self.assertIsNone(opts.table_factory)

        opts.table_factory = rocksdb.BlockBasedTableFactory()
        opts.table_factory = rocksdb.PlainTableFactory()

    def test_compaction_style(self):
        opts = rocksdb.Options()
        self.assertEqual('level', opts.compaction_style)

        opts.compaction_style = 'universal'
        self.assertEqual('universal', opts.compaction_style)

        opts.compaction_style = 'level'
        self.assertEqual('level', opts.compaction_style)

        with self.assertRaisesRegexp(Exception, 'Unknown compaction style'):
            opts.compaction_style = 'foo'

    def test_compaction_opts_universal(self):
        opts = rocksdb.Options()
        uopts = opts.compaction_options_universal
        self.assertEqual(-1, uopts['compression_size_percent'])
        self.assertEqual(200, uopts['max_size_amplification_percent'])
        self.assertEqual('total_size', uopts['stop_style'])
        self.assertEqual(1, uopts['size_ratio'])
        self.assertEqual(2, uopts['min_merge_width'])
        self.assertGreaterEqual(4294967295, uopts['max_merge_width'])

        new_opts = {'stop_style': 'similar_size', 'max_merge_width': 30}
        opts.compaction_options_universal = new_opts
        uopts = opts.compaction_options_universal

        self.assertEqual(-1, uopts['compression_size_percent'])
        self.assertEqual(200, uopts['max_size_amplification_percent'])
        self.assertEqual('similar_size', uopts['stop_style'])
        self.assertEqual(1, uopts['size_ratio'])
        self.assertEqual(2, uopts['min_merge_width'])
        self.assertEqual(30, uopts['max_merge_width'])

    def test_row_cache(self):
        opts = rocksdb.Options()
        self.assertIsNone(opts.row_cache)
        opts.row_cache = cache = rocksdb.LRUCache(2*1024*1024)
        self.assertEqual(cache, opts.row_cache)
