from abc import ABCMeta
from abc import abstractmethod


class Comparator:
    __metaclass__ = ABCMeta

    @abstractmethod
    def compare(self, a, b):
        pass

    @abstractmethod
    def name(self):
        pass


class AssociativeMergeOperator:
    __metaclass__ = ABCMeta

    @abstractmethod
    def merge(self, key, existing_value, value):
        pass

    @abstractmethod
    def name(self):
        pass


class MergeOperator:
    __metaclass__ = ABCMeta

    @abstractmethod
    def full_merge(self, key, existing_value, operand_list):
        pass

    @abstractmethod
    def partial_merge(self, key, left_operand, right_operand):
        pass

    @abstractmethod
    def name(self):
        pass


class FilterPolicy:
    __metaclass__ = ABCMeta

    @abstractmethod
    def name(self):
        pass

    @abstractmethod
    def create_filter(self, keys):
        pass

    @abstractmethod
    def key_may_match(self, key, filter_):
        pass

class SliceTransform:
    __metaclass__ = ABCMeta

    @abstractmethod
    def name(self):
        pass

    @abstractmethod
    def transform(self, src):
        pass

    @abstractmethod
    def in_domain(self, src):
        pass

    @abstractmethod
    def in_range(self, dst):
        pass
