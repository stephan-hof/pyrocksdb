cdef extern from "<memory>" namespace "std":
    cdef cppclass shared_ptr[T]:
        shared_ptr() nogil except+
        shared_ptr(T*) nogil except+
        void reset() nogil except+
        void reset(T*) nogil except+
        T* get() nogil except+
