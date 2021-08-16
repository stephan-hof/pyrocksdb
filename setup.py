import platform
import os
from setuptools import setup
from setuptools import find_packages
from setuptools import Extension

try:
    from Cython.Build import cythonize
except ImportError:
    def cythonize(extensions):
        return extensions

    sources = ['rocksdb/_rocksdb.cpp']
else:
    sources = ['rocksdb/_rocksdb.pyx']

extra_compile_args = [
    '-std=c++11',
    '-O3',
    '-Wall',
    '-Wextra',
    '-Wconversion',
    '-fno-strict-aliasing',
    '-fno-rtti',
]

if platform.system() == 'Darwin':
    extra_compile_args += ['-mmacosx-version-min=10.7', '-stdlib=libc++']


STATIC_LIBRARIES = [os.path.join("src", "rocksdb", item) for item in [
    "libbz2.a",
    "liblz4.a",
    "librocksdb.a",
    "libsnappy.a",
    "libz.a",
    "libzstd.a",
]]

LIBRARIES = ['rocksdb', 'snappy', 'bz2', 'z', 'lz4']
EXTRA_OBJECTS = []
INCLUDE_DIRS = []

if all(map(os.path.exists, STATIC_LIBRARIES)):
    LIBRARIES = []
    EXTRA_OBJECTS = STATIC_LIBRARIES
    INCLUDE_DIRS = [os.path.join("src", "rocksdb", "include")]


setup(
    name="python-rocksdb-static",
    version='0.7.0',
    description="Python bindings for RocksDB",
    keywords='rocksdb',
    author='Ming Hsuan Tu',
    author_email="qrnnis2623891@gmail.com",
    url="https://github.com/twmht/python-rocksdb",
    license='BSD License',
    setup_requires=['setuptools>=25', 'Cython>=0.20'],
    install_requires=['setuptools>=25'],
    package_dir={'rocksdb': 'rocksdb'},
    packages=find_packages('.'),
    ext_modules=cythonize([Extension(
        'rocksdb._rocksdb',
        ['rocksdb/_rocksdb.pyx'],
        extra_compile_args=extra_compile_args,
        language='c++',
        libraries=LIBRARIES,
        include_dirs=INCLUDE_DIRS,
        extra_objects=EXTRA_OBJECTS,
    )]),
    extras_require={
        "doc": ['sphinx_rtd_theme', 'sphinx'],
        "test": ['pytest'],
    },
    include_package_data=True,
    zip_safe=False,
)
