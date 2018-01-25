import platform
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

extra_compile_args = [
    '-std=c++11',
    '-O3',
    '-Wall',
    '-Wextra',
    '-Wconversion',
    '-fno-strict-aliasing'
]

if platform.system() == 'Darwin':
    extra_compile_args += ['-mmacosx-version-min=10.7', '-stdlib=libc++']

mod1 = Extension(
    'rocksdb._rocksdb',
    sources,
    extra_compile_args=extra_compile_args,
    language='c++',
    libraries=[
        'rocksdb',
        'snappy',
        'bz2',
        'z'
    ]
)

setup(
    name="python-rocksdb",
    version='0.6.8',
    description="Python bindings for RocksDB",
    keywords='rocksdb',
    author='Ming Hsuan Tu',
    author_email="qrnnis2623891@gmail.com",
    url="https://github.com/twmht/python-rocksdb",
    license='BSD License',
    install_requires=['setuptools'],
    package_dir={'rocksdb': 'rocksdb'},
    packages=find_packages('.'),
    ext_modules=cythonize([mod1]),
    setup_requires=['pytest-runner'],
    tests_require=['pytest'],
    include_package_data=True
)
