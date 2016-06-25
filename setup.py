from setuptools import setup
from setuptools import find_packages
from distutils.extension import Extension

try:
    from Cython.Build import cythonize
except ImportError:
    def cythonize(extensions): return extensions
    sources = ['rocksdb/_rocksdb.cpp']
else:
    sources = ['rocksdb/_rocksdb.pyx']

mod1 = Extension(
    'rocksdb._rocksdb',
    sources,
    extra_compile_args=[
        '-std=c++11',
        '-O3',
        '-Wall',
        '-Wextra',
        '-Wconversion',
        '-fno-strict-aliasing'
    ],
    language='c++',
    libraries=[
        'rocksdb',
        'snappy',
        'bz2',
        'z'
    ]
)

setup(
    name="pyrocksdb",
    version='0.5.0',
    description="Python bindings for RocksDB",
    keywords='rocksdb',
    author='Stephan Hofmockel',
    author_email="Use the github issues",
    url="https://github.com/stephan-hof/pyrocksdb",
    license='BSD License',
    install_requires=['setuptools'],
    package_dir={'rocksdb': 'rocksdb'},
    packages=find_packages('.'),
    ext_modules=cythonize([mod1]),
    test_suite='rocksdb.tests',
    include_package_data=True
)
