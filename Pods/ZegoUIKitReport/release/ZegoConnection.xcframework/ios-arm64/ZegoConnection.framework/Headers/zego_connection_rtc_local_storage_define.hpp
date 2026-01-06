#ifndef zego_connection_rtc_local_storage_define_hpp
#define zego_connection_rtc_local_storage_define_hpp

#include "zego_connection_define.hpp"

namespace ZEGO
{
    namespace CONNECTION
    {
        using OnAsyncSaveLocalStorageResult = std::function<void(bool save_success)>;
    }
}
#endif 