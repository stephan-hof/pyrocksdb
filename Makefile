all: src/rocksdb/librocksdb.a

src/rocksdb/libsnappy.a:
	make -C src/rocksdb libsnappy.a
	strip src/rocksdb/libsnappy.a

src/rocksdb/liblz4.a:
	make -C src/rocksdb liblz4.a
	strip src/rocksdb/liblz4.a

src/rocksdb/libbz2.a:
	make -C src/rocksdb libbz2.a
	strip src/rocksdb/libbz2.a

src/rocksdb/libzstd.a:
	make -C src/rocksdb libzstd.a
	strip src/rocksdb/libzstd.a

src/rocksdb/libz.a:
	make -C src/rocksdb libz.a
	strip src/rocksdb/libz.a

snappy: src/rocksdb/libsnappy.a
lz4: src/rocksdb/liblz4.a
bz2: src/rocksdb/libbz2.a
zstd: src/rocksdb/libzstd.a
zlib: src/rocksdb/libz.a

src/rocksdb/librocksdb.a: zlib zstd bz2 lz4 snappy
	CMAKE_BUILD_PARALLEL_LEVEL=8 make -C src/rocksdb static_lib
