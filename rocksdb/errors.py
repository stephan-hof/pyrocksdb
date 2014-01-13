class NotFound(Exception):
    pass

class Corruption(Exception):
    pass

class NotSupported(Exception):
    pass

class InvalidArgument(Exception):
    pass

class RocksIOError(Exception):
    pass

class MergeInProgress(Exception):
    pass

class Incomplete(Exception):
    pass
