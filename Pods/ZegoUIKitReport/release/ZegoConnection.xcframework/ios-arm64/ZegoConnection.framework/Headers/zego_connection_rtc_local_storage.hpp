#ifndef zego_connection_rtc_local_storage_hpp
#define zego_connection_rtc_local_storage_hpp

#include <memory>
#include <zegotask.h>
#include "zego_connection_rtc_local_storage_define.hpp"

namespace ZEGO
{
namespace CONNECTION
{    
	class CRtcLocalStorageImpl;
    class ZEGOCONNECTION_API ZegoConnectionRtcLocalStorage
    {
    public:
        static std::shared_ptr<ZegoConnectionRtcLocalStorage> GetInstance();
        virtual ~ZegoConnectionRtcLocalStorage();
        
    private:
        ZegoConnectionRtcLocalStorage();

    public:
        /**
        初始化模块
        
        @param
        */
        ZCError Init();

        /**
        反初始化模块
        
        @param
        */
        void UnInit();

        /**
        读取文件
        
        @param  file_full_path 文件全路径
        @param  file_content 文件内容
        */
        bool ReadLocalStorage(const std::string& file_full_path, std::string& file_content);

        /**
        异步存储本地文件， 会抛给其它线程做存储
        
        @param  file_full_path 文件全路径
        @param  file_content 文件内容
        */
        void SaveLocalStorageAsync(const std::string &file_full_path, const std::string &file_content, const OnAsyncSaveLocalStorageResult result = nullptr);
        
        /**
        同步存储本地文件， 当前线程做存储操作
        
        @param  file_full_path 文件全路径
        @param  file_content 文件内容
        */
        bool SaveLocalStorageSync(const std::string &file_full_path,  const std::string &file_content);

        /**
        删除文件
        
        @param  file_full_path 文件全路径
        */
        bool RemoveLocalStorageSync(const std::string &file_full_path);
        
        /**
        文件是否存在
        
        @param  file_full_path 文件全路径
        */
        bool IsLocalFileExist(const std::string &file_full_path);
        
    private:		
		std::shared_ptr<CRtcLocalStorageImpl> rtc_local_storage_impl_ = nullptr;
    };
    
}// CONNECTION
}// ZEGO


#endif /* zego_connection_agent_hpp */
