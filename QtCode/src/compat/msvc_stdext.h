#pragma once

#if defined(_MSC_VER)
#include <cstddef>

namespace stdext {
template <typename T>
constexpr T *make_checked_array_iterator(T *ptr, std::size_t) noexcept
{
    return ptr;
}

template <typename T>
constexpr const T *make_checked_array_iterator(const T *ptr, std::size_t) noexcept
{
    return ptr;
}

template <typename T>
constexpr T *make_unchecked_array_iterator(T *ptr) noexcept
{
    return ptr;
}

template <typename T>
constexpr const T *make_unchecked_array_iterator(const T *ptr) noexcept
{
    return ptr;
}
}
#endif
