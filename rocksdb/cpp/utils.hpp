#include <vector>

namespace py_rocks {
    template <typename T>
    const T* vector_data(std::vector<T>& v) {
        return v.data();
    }
}
