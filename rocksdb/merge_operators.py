import struct as py_struct
from rocksdb.interfaces import AssociativeMergeOperator

class UintAddOperator(AssociativeMergeOperator):
    def merge(self, key, existing_value, value):
        if existing_value:
            s = py_struct.unpack('Q', existing_value)[0] + py_struct.unpack('Q', value)[0]
            return (True, py_struct.pack('Q', s))
        return (True, value)

    def name(self):
        return b'uint64add'

class StringAppendOperator(AssociativeMergeOperator):
    def merge(self, key, existing_value, value):
        if existing_value:
            s = existing_value + b',' + value
            return (True, s)
        return (True, value)

    def name(self):
        return b'StringAppendOperator'
